defmodule MatchEngine.Score do
  @moduledoc false

  alias MatchEngine.Geo
  alias MatchEngine.Query

  @leaf_operators Query.leaf_operators()

  def filter([], _doc) do
    score_map(0)
  end

  def filter(parts, doc) when is_list(parts) do
    score_part({:_and, parts}, doc)
  end

  def score(parts, doc) when is_list(parts) do
    score_part({:_or, parts}, doc)
  end

  defp score_part({:_or, parts}, doc) do
    parts
    |> Enum.map(&score_part(&1, doc))
    |> score_combine(0, &Kernel.+/2)
  end

  defp score_part({:_and, parts}, doc) do
    parts
    |> Enum.map(&score_part(&1, doc))
    |> score_combine(1, &Kernel.*/2)
  end

  defp score_part({:_not, parts}, doc) do
    parts
    |> Enum.map(&(score_part(&1, doc) |> invert_score()))
    |> score_combine(0, &Kernel.+/2)
  end

  defp score_part({op, _parts}, _doc) when op in @leaf_operators do
    raise RuntimeError, "Unexpected operator: #{op}"
  end

  defp score_part({field, [{:_ne, expected} | rest]}, doc) do
    score_part({:_not, [{field, [{:_eq, expected} | rest]}]}, doc)
  end

  defp score_part({field, [{:_hasnt, expected} | rest]}, doc) do
    score_part({:_not, [{field, [{:_has, expected} | rest]}]}, doc)
  end

  defp score_part({field, [{:_nin, expected} | rest]}, doc) do
    score_part({:_not, [{field, [{:_in, expected} | rest]}]}, doc)
  end

  defp score_part({field, [{:_eq, expected} | rest]}, doc) when is_list(expected) do
    score_part({field, [{:_has, expected} | rest]}, doc)
  end

  defp score_part({field, [{:_eq, expected} | _] = node}, doc) do
    case get_value(doc, field) do
      items when is_list(items) ->
        truth_score(Enum.member?(items, expected))

      ^expected ->
        1

      _ ->
        0
    end
    |> weigh(node)
    |> score_map()
  end

  defp score_part({field, [{:_has, expected} | rest]}, doc) when is_binary(expected) do
    score_part({field, [{:_has, [expected]} | rest]}, doc)
  end

  defp score_part({field, [{:_has, expected} | _] = node}, doc) when is_list(expected) do
    case get_value(doc, field) do
      [] ->
        0

      str when is_binary(str) ->
        (length(expected) - length(expected -- String.split(str))) / length(expected)

      items when is_list(items) ->
        (length(expected) - length(expected -- items)) / length(expected)

      _ ->
        0
    end
    |> weigh(node)
    |> score_map()
  end

  defp score_part({field, [{:_in, expected} | _] = node}, doc) do
    truth_score(Enum.member?(expected, get_value(doc, field)))
    |> weigh(node)
    |> score_map()
  end

  @compare_operators %{_lt: :<, _lte: :<=, _gt: :>, _gte: :>=}
  @compare_operator_keys Map.keys(@compare_operators)
  defp score_part({field, [{op, expected} | _] = node}, doc) when op in @compare_operator_keys do
    value = get_value(doc, field)

    apply(Kernel, @compare_operators[op], [value, expected])
    |> truth_score()
    |> weigh(node)
    |> score_map()
  end

  defp score_part({field, [{:_regex, %Regex{} = regex} | _] = node}, doc) do
    value = get_value(doc, field) || ""

    case Regex.named_captures(regex, value) do
      nil ->
        score_map(0)

      %{"__match__" => ""} ->
        score_map(0)

      %{"__match__" => match} = all ->
        (String.length(match) / String.length(value))
        |> weigh(node)
        |> score_map(Map.delete(all, "__match__"))
    end
  end

  defp score_part({field, [{:_regex, subject}, {:inverse, true} | _] = node}, doc) do
    value = get_value(doc, field) || ""

    case Regex.compile!(value, "iu") |> Regex.run(subject) do
      nil ->
        score_map(0)

      [""] ->
        score_map(0)

      [match] ->
        (String.length(match) / String.length(subject))
        |> weigh(node)
        |> score_map()
    end
  end

  defp score_part({field, [{:_sim, expected} | _] = node}, doc) when is_binary(expected) do
    case get_value(doc, field) do
      list when is_list(list) ->
        Enum.reduce(list, 0, &max(string_sim(&1, expected), &2))

      str when is_binary(str) ->
        string_sim(str, expected)

      _ ->
        0
    end
    |> weigh(node)
    |> score_map()
  end

  @default_max_distance 100 * 1000

  defp score_part({field, [{:_geo, location} | _] = node}, doc) do
    case get_value(doc, field) do
      nil ->
        score_map(0)

      value ->
        case {Geo.coerce_location(location), Geo.coerce_location(value)} do
          {{_, _} = a, {_, _} = b} ->
            max_distance = node[:max_distance] || @default_max_distance
            radius = node[:radius] || 0
            distance = Geo.distance(a, b)

            case distance > radius do
              false ->
                truth_score(true)

              true ->
                log_score(distance - radius, max_distance)
            end
            |> weigh(node)
            |> score_map(%{"distance" => distance})

          {_, _} ->
            score_map(0)
        end
    end
  end

  defp score_part({field, [{:_geo_poly, points} | _] = node}, doc) do
    with value when value != nil <- get_value(doc, field),
         point = {x_point, y_point} <- Geo.coerce_location(value),
         poly = [{_, _} | _] <- Geo.coerce_locations(points) do
      #      max_distance = node[:max_distance] || @default_max_distance

      contained =
        poly
        |> Enum.chunk_every(2, 1, [hd(poly)])
        |> Enum.reject(fn [{_x1, y1}, {_x2, y2}] -> y1 > y_point == y2 > y_point end)
        |> Enum.reject(fn [{x1, y1}, {x2, y2}] ->
          not (x_point < (x2 - x1) * (y_point - y1) / (y2 - y1) + x1)
        end)
        |> Enum.count()
        |> Integer.mod(2) == 1

      case contained do
        true ->
          truth_score(true)
          |> weigh(node)
          |> score_map()

        false ->
          max_distance = node[:max_distance] || @default_max_distance
          distance = Geo.distance(point, Geo.closest_point(point, poly))

          log_score(distance, max_distance)
          |> weigh(node)
          |> score_map(%{"distance" => distance})
      end
    else
      _ -> score_map(0)
    end
  end

  defp score_part({field, [{:_time, time} | _] = node}, doc) do
    with {:ok, to} <- parse_time(time),
         {:ok, from} = parse_time(get_value(doc, field)) do
      max_time = node[:max_time] || 24 * 3600

      Timex.diff(to, from, :seconds)
      |> abs()
      |> log_score(max_time)
      |> weigh(node)
      |> score_map()
    else
      _ ->
        score_map(0)
    end
  end

  defp score_part({field, [{op, _} | _]}, _doc) do
    raise RuntimeError, "Unexpected operator #{field}, or invalid arguments for operator #{op}"
  end

  ##

  defp weigh(score, _node) when score == 0, do: 0

  defp weigh(score, node) do
    binary_score(score, node[:b]) * (node[:w] || 1)
  end

  defp get_value(doc, []) do
    doc
  end

  defp get_value(doc, field) do
    get_in(doc, field)
  end

  defp truth_score(true), do: 1
  defp truth_score(false), do: 0

  defp binary_score(score, true) when score > 0, do: 1
  defp binary_score(score, _), do: score

  defp invert_score(%{"score" => score} = map) when score == 0 do
    Map.put(map, "score", 1)
  end

  defp invert_score(%{"score" => _score} = map) do
    Map.put(map, "score", 0)
  end

  defp log_score(value, _max_value) when value == 0 do
    1
  end

  defp log_score(value, max_value) do
    cond do
      max_value == 0.0 ->
        0

      true ->
        max(1 - :math.log(1 + value) / :math.log(1 + max_value), 0)
    end
  end

  defp string_sim("", ""), do: 0

  defp string_sim(a, b) do
    d1 = 1 - Simetric.Levenshtein.compare(a, b) / max(String.length(a), String.length(b))
    d2 = String.jaro_distance(a, b)
    max(d1, d2)
  end

  defp score_map(s) do
    %{"score" => s}
  end

  defp score_map(s, add) when is_map(add) do
    Map.put(add, "score", s)
  end

  defp score_combine(score_maps, initial, resolver) do
    score_maps
    |> Enum.reduce(score_map(initial), fn score, overall ->
      Map.merge(score, overall, fn
        "score", s1, s2 ->
          resolver.(s1, s2)

        _k, _v1, v2 ->
          v2
      end)
    end)
  end

  defp parse_time(time) do
    Timex.parse(time, "{ISO:Extended}")
  end
end

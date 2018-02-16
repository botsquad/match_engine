defmodule MatchEngine.Score do

  @leaf_operators ~w(_eq _regex _sim _in)a

  def filter([], _doc) do
    false
  end
  def filter(parts, doc) when is_list(parts) do
    score_part({:_and, parts}, doc) > 0
  end

  def score(parts, doc) when is_list(parts) do
    score_part({:_or, parts}, doc)
  end

  defp score_part({:_or, parts}, doc) do
    parts
    |> Enum.map(&(score_part(&1, doc)))
    |> Enum.reduce(0, &Kernel.+/2)
  end
  defp score_part({:_and, parts}, doc) do
    parts
    |> Enum.map(&(score_part(&1, doc)))
    |> Enum.reduce(1, &Kernel.*/2)
  end
  defp score_part({:_not, parts}, doc) do
    parts
    |> Enum.map(&(score_part(&1, doc) |> invert_score()))
    |> Enum.reduce(0, &Kernel.+/2)
  end
  defp score_part({op, _parts}, _doc) when op in @leaf_operators do
    raise RuntimeError, "Unexpected operator: #{op}"
  end

  defp score_part({field, [{:_ne, _} | _] = node}, doc) do
    score_part({field, {:not, node}}, doc)
  end
  defp score_part({field, [{:_eq, value} | _] = node}, doc) do
    case get_value(doc, field) do
      items when is_list(items) and is_list(value) ->
        1 - length(items -- value) / max(length(value), length(items))
      items when is_list(items) ->
        truth_score(Enum.member?(items, value))
      ^value ->
        1
      _ ->
        0
    end
    |> weigh(node)
  end
  defp score_part({field, [{:_in, list} | _] = node}, doc) do
    truth_score(Enum.member?(list, get_value(doc, field)))
    |> weigh(node)
  end
  defp score_part({field, [{:_regex, regex} | _] = node}, doc) do
    value = get_value(doc, field) || ""
    case Regex.compile!(regex, "i") |> Regex.run(value) do
      [result] ->
      (String.length(result) / String.length(value))
      |> weigh(node)
      nil ->
        0
    end
  end
  defp score_part({field, [{:_sim, expected} | _] = node}, doc) when is_binary(expected) do
    case get_value(doc, field) do
      list when is_list(list) ->
        Enum.reduce(list, 0, &(max(string_sim(&1, expected), &2)))
      str when is_binary(str) ->
        string_sim(str, expected)
      _ ->
        0
    end
    |> weigh(node)
  end
  defp score_part({_field, [{op, _} | _]}, _doc) do
    raise RuntimeError, "Unexpected operator #{_field}, or invalid arguments for operator #{op}"
  end
  defp score_part({field, value}, doc) do
    case Atom.to_string(field) do
      "_" <> _ ->
        raise RuntimeError, "Unknown operator: #{field}"
      _ ->
        # default behaviuor is equality
        score_part({field, [_eq: value]}, doc)
    end
  end

  ##

  defp weigh(score, _node) when score == 0, do: 0
  defp weigh(score, node) do
    binary_score(score, node[:b]) * (node[:w] || 1)
  end

  defp get_value(doc, field) do
    path = field |> Atom.to_string() |> String.split("@")
    get_in(doc, path)
  end

  defp truth_score(true), do: 1
  defp truth_score(false), do: 0

  defp binary_score(score, true) when score > 0, do: 1
  defp binary_score(score, _), do: score

  defp invert_score(score) when score == 0, do: 1
  defp invert_score(_score), do: 0

  defp string_sim(a, b) do
    d1 = (1 - Simetric.Levenshtein.compare(a, b) / (max(String.length(a), String.length(b))))
    d2 = String.jaro_distance(a, b)
    max(d1, d2)
  end
end

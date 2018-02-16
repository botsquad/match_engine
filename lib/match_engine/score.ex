defmodule MatchEngine.Score do

  def score(parts, doc) when is_list(parts) do
    parts
    |> Enum.map(&(score_part(&1, doc)))
    |> Enum.reduce(0, &Kernel.+/2)
  end

  defp score_part({:_and, parts}, doc) do
    parts
    |> Enum.map(&(score_part(&1, doc)))
    |> Enum.reduce(1, &Kernel.*/2)
  end
  defp score_part({field, [{:_eq, value} | _] = node}, doc) do
    truth_score(get_value(doc, field) == value)
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
  defp score_part({field, [{:_sim, expected} | _] = node}, doc) do
    value = get_value(doc, field) || ""
    d1 = (1 - Simetric.Levenshtein.compare(expected, value) / (max(String.length(expected), String.length(value))))
    d2 = String.jaro_distance(expected, value)

    max(d1, d2)
    |> weigh(node)
  end
  defp score_part({field, value}, doc) do
    truth_score(get_value(doc, field) == value)
  end

  ##

  defp weigh(score, _node) when score == 0, do: 0
  defp weigh(score, node) do
    binary_score(score, node[:b]) * (node[:w] || 1)
  end

  defp get_value(doc, field) do
    doc[Atom.to_string(field)]
  end

  defp truth_score(true), do: 1
  defp truth_score(false), do: 0

  defp binary_score(score, true) when score > 0, do: 1
  defp binary_score(score, _), do: score

end

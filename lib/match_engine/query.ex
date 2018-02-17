defmodule MatchEngine.Query do

  @leaf_operators ~w(_eq _regex _sim _in)a
  @logic_operators ~w(_and _or _not)a

  def preprocess(q) when is_list(q) do
    q
    |> Enum.reduce([], &(preprocess_part(&1, [], &2)))
    |> Enum.reverse()
  end

  #  defp preprocess_part({op, value}, prefix, all) when op in @logic_operators do
  #  end

  defp preprocess_part({op, value}, [], all) when op in @logic_operators do
    [{op, preprocess(value)} | all]
  end
  defp preprocess_part({op, value}, prefix, all) when op in @logic_operators do
    ops =
      value
      |> Enum.reduce([], &(preprocess_part(&1, prefix, &2))) |> Enum.reverse()
    [{op, ops} | all]
  end
  defp preprocess_part({field, [{op, _}| _] = value}, prefix, all) when op not in @leaf_operators do
    (value |> Enum.reduce([], &(preprocess_part(&1, prefix ++ [Atom.to_string(field)], &2)))) ++ all
  end
  defp preprocess_part({field, value}, prefix, all) do
    [{prefix ++ [Atom.to_string(field)], preprocess_value(value)} | all]
  end

  defp preprocess_value([{op, _val} | _] = node) when op in @leaf_operators do
    node
    |> preprocess_leaf_op()
  end
  defp preprocess_value([{_, _val} | _] = node) do
    raise RuntimeError, "Invalid leaf value: #{inspect node}"
  end
  defp preprocess_value(node) do
    [_eq: node]
  end

  defp preprocess_leaf_op([{:_regex, re} | rest]) do
    [{:_regex, Regex.compile!(re)} | rest]
  end
  defp preprocess_leaf_op(node) do
    node
  end

end

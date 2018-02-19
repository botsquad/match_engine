defmodule MatchEngine.Query do

  @leaf_operators ~w(_eq _regex _sim _in _ne _nin _geo _time)a
  @logic_operators ~w(_and _or _not)a

  def leaf_operators do
    @leaf_operators
  end

  def preprocess(q) when is_map(q) do
    q |> query_map_to_list() |> preprocess()
  end
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
    ops = value |> Enum.reduce([], &(preprocess_part(&1, prefix, &2))) |> Enum.reverse()
    [{op, ops} | all]
  end
  defp preprocess_part({field, [{op, _}| _] = value}, prefix, all) when op not in @leaf_operators do
    if is_operator(field) do
      if Enum.member?(@leaf_operators, field) do
        raise RuntimeError, "Invalid use of operator: #{field}"
      end
      raise RuntimeError, "Invalid operator: #{field}"
    end
    (value |> Enum.reduce([], &(preprocess_part(&1, prefix ++ [Atom.to_string(field)], &2)))) ++ all
  end
  defp preprocess_part([{op, _val} | _] = node, prefix, all) when op in @leaf_operators do
    [{prefix, preprocess_value(node)} | all]
  end
  defp preprocess_part({field, value}, prefix, all) do
    if is_operator(field) do
      [{prefix, preprocess_value([{field, value}])} | all]
    else
      [{prefix ++ [coerce_string(field)], preprocess_value(value)} | all]
    end
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

  defp preprocess_leaf_op([{:_regex, _}, {:inverse, true} | rest] = node) do
    node
  end
  defp preprocess_leaf_op([{:_regex, re} | rest]) do
    re = "(?P<__match__>#{re})"
    [{:_regex, Regex.compile!(re, "i")} | rest]
  end
  defp preprocess_leaf_op(node) do
    node
  end

  defp coerce_string(field) when is_binary(field), do: field
  defp coerce_string(field) when is_atom(field), do: field |> Atom.to_string()

  defp is_operator(op) when op in @logic_operators do
    true
  end
  defp is_operator(op) when op in @leaf_operators do
    true
  end
  defp is_operator(op) do
    case Atom.to_string(op) do
      "_" <> _ ->
        true
      _ ->
        false
    end
  end

  defp query_map_to_list(list) when is_list(list) do
    list |> Enum.map(&query_map_to_list/1)
  end
  defp query_map_to_list(map) when is_map(map) do
    Map.to_list(map)
    |> Enum.sort(fn
      ({"_" <> _, _}, _) -> true
      (_, {"_" <> _, _}) -> false
      ({k1, _}, {k2, _}) -> k1 >= k2
    end)
    |> Enum.map(fn({k, v}) -> {String.to_atom(k), query_map_to_list(v)} end)
  end
  defp query_map_to_list(value), do: value

end

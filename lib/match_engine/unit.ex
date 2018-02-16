defmodule MatchEngine.Unit do
  alias MatchEngine.Unit

  defstruct [
    # the operator
    op: nil,

    # its argument(s)
    arg: nil,

    # score weight
    weight: 1,

    # when true, score binary.(1 or 0), otherwise score a continuous value
    binary_score: false
  ]

  def new(opts) when is_list(opts) do
    new(opts |> Enum.into(%{}))
  end
  def new(opts) when is_map(opts) do
    struct = %Unit{}
    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(opts, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error ->
          case Map.fetch(opts, k) do
            {:ok, v} ->
              validate_attr(k, v) || raise RuntimeError, "Validation failed for #{k}: #{v} is not valid"
              %{acc | k => v}
            :error -> acc
          end
      end
    end)
    |> validate_unit()
  end

  def arg(unit, arg) do
    %Unit{unit | arg: arg}
  end

  @operators ~w(eq sim re not or and)a


  # unit validation

  defp validate_unit(%{op: :re, arg: {_field, re}} = unit) do
    if not is_binary(re) do
      raise RuntimeError, "Regular expression needs to be a string"
    end
    unit
  end
  defp validate_unit(%{op: _} = unit), do: unit

  # attribute validation
  def validate_attr(:op, op), do: Enum.member?(@operators, op)
  def validate_attr(:field, string), do: is_binary(string)
  def validate_attr(_, _), do: true

  def run(%Unit{} = unit, input) do
    run(unit.op, unit, input)
    |> weigh(unit)
  end

  defp weigh(score, %{weight: weight, binary_score: binary_score}) do
    weight * score_binary(score, binary_score)
  end

  defp score_binary(score, true) when score > 0, do: 1
  defp score_binary(score, true) when score == 0, do: 0
  defp score_binary(score, false), do: score

  defp invert_score(score) do
    case score != 0 do
      true -> 0
      false -> 1
    end
  end

  defp retrieve_field(input, field) do
    Map.fetch(input, field)
  end

  ### Operators

  defp run(:not, %{arg: %Unit{} = unit}, input) do
    run(unit, input)
    |> invert_score()
  end

  defp run(:or, %{arg: units}, input) do
    units
    |> Enum.map(&(run(&1, input)))
    |> Enum.reduce(0, &Kernel.+/2)
  end

  defp run(:and, %{arg: units}, input) do
    units
    |> Enum.map(&(run(&1, input)))
    |> Enum.reduce(1, &Kernel.*/2)
  end

  defp run(:eq, %{arg: {field, expected}}, input) do
    case retrieve_field(input, field) do
      {:ok, ^expected} -> 1
      _ -> 0
    end
  end

  defp run(:sim, %{arg: {field, expected}}, input) do
    case retrieve_field(input, field) do
      {:ok, value} -> String.jaro_distance(expected, value)
      _ -> 0
    end
  end

  defp run(:re, %{arg: {field, re}}, input) do
    with {:ok, input} <- Map.fetch(input, field) do
      case Regex.compile!(re, "i") |> Regex.run(input) do
        [result] ->
          String.length(result) / String.length(input)
        nil ->
          0
      end
    else
      _ -> 0
    end
  end

end

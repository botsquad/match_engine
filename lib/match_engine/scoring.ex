defmodule MatchEngine.Scoring do
  @moduledoc false

  import MatchEngine.Score

  def score_all(docs, query) do
    docs
    |> Enum.map(& Map.put(&1, "_match", score(query, &1)))
    |> Enum.sort_by(&(&1["_match"]["score"]), &Kernel.>/2)
  end

  def filter_all(docs, query) do
    docs
    |> Enum.map(&(Map.put(&1, "_match", filter(query, &1))))
    |> Enum.filter(&(&1["_match"]["score"] > 0))
    |> Enum.map(& Map.delete(&1, "_match"))
  end

end

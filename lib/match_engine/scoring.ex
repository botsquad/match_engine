defmodule MatchEngine.Scoring do
  @moduledoc false

  import MatchEngine.Score

  def score_all(docs, query) do
    docs
    |> Enum.map(&Map.put(&1, "_match", score(query, &1)))
    |> Enum.sort_by(& &1["_match"]["score"], &Kernel.>/2)
  end

  def filter_all([], _query) do
    []
  end

  def filter_all(docs, query) do
    Enum.filter(docs, fn doc ->
      result = filter(query, doc)
      result["score"] > 0
    end)
  end
end

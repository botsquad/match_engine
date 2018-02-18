defmodule MatchEngine.Scoring do

  import MatchEngine.Score

  def score_all(docs, query) do
    docs
    |> Enum.map(&({score(query, &1), &1}))
    |> Enum.sort()
    |> Enum.reverse()
    |> Enum.map(&(Map.put(elem(&1, 1), :_match, elem(&1, 0))))
  end

  def filter_all(docs, query) do
    docs
    |> Enum.map(&(Map.put(&1, :_match, filter(query, &1))))
    |> Enum.filter(&(&1._match.score > 0))
  end

end

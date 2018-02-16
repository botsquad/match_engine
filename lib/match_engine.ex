defmodule MatchEngine do
  @moduledoc """
  Documentation for MatchEngine.
  """

  defdelegate score(query, doc), to: MatchEngine.Score
  defdelegate filter(query, doc), to: MatchEngine.Score

  defdelegate score_all(docs, query), to: MatchEngine.Scoring
  defdelegate filter_all(docs, query), to: MatchEngine.Scoring

end

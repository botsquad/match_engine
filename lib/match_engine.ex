defmodule MatchEngine do
  @moduledoc """
  Documentation for MatchEngine.
  """

  alias MatchEngine.{Query, Score, Scoring}

  def score(query, doc) do
    query
    |> Query.preprocess()
    |> Score.score(doc)
  end

  def filter(query, doc) do
    query
    |> Query.preprocess()
    |> Score.filter(doc)
  end

  def score_all(docs, query) do
    query = Query.preprocess(query)
    Scoring.score_all(docs, query)
  end

  def filter_all(docs, query) do
    query = Query.preprocess(query)
    Scoring.filter_all(docs, query)
  end

end

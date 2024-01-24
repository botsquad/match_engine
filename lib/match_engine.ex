defmodule MatchEngine do
  @external_resource "README.md"

  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias MatchEngine.{Query, Score, Scoring}

  @type query() :: [operator_pair] | map()
  @type operator_pair() :: {operator(), operator_arg()}
  @type operator_arg() :: any()
  @type operator() ::
          :_not
          | :_and
          | :_or
          | :_eq
          | :_ne
          | :_in
          | :_nin
          | :_sim
          | :_regex
          | :_geo
          | :_time
          | :_has
          | :_hasnt

  @type score_match() :: map()
  @type doc() :: map()
  @type doc_with_match() :: map()

  @doc """
  Score a single document agains the given query

  Top-level query operators are treated as `or` clauses.  The return
  value includes `score` attribute which contains the actual score.
  """
  @spec score(query(), doc()) :: score_match()
  def score(query, doc) do
    query
    |> Query.preprocess()
    |> Score.score(doc)
  end

  @doc """
  Filter a single document agains the given query

  Top-level query operators are treated as `and` clauses.  The return
  value includes `score` attribute which contains the actual score.
  """
  @spec filter(query(), doc()) :: score_match()
  def filter(query, doc) do
    query
    |> Query.preprocess()
    |> Score.filter(doc)
  end

  @doc """
  Score all given documents against the given query.

  All documents are returned, even when their score is 0. The returned
  list of documents is sorted on their score, descending (best
  matching document first).

  The document contains a `_match` key which contains the `score`
  attribute. Some operators, e.g. `_geo`, add additional information
  to this match map, for instance, the geographical distance.
  """
  @spec score_all([doc()], query()) :: [doc_with_match()]
  def score_all(docs, query) do
    query = Query.preprocess(query)
    Scoring.score_all(docs, query)
  end

  @doc """
  Filter all given documents agains the given query.

  Only the documents that have a positive (greater than 0) score are
  returned. The document order is preserved, no sorting on score is done.
  """
  @spec filter_all([doc()], query()) :: [doc_with_match()]
  def filter_all(docs, query) do
    query = Query.preprocess(query)
    Scoring.filter_all(docs, query)
  end
end

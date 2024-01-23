# MatchEngine

[![Elixir CI](https://github.com/botsquad/match_engine/actions/workflows/elixir.yml/badge.svg)](https://github.com/botsquad/match_engine/actions/workflows/elixir.yml) [![Hex.pm](https://img.shields.io/hexpm/v/match_engine.svg)]()

A query language for filtering and scoring of documents, inspired by
the MongoDB query language and Solr. The query language consists of
nested Elixir _keyword list_. Each component of the query consists of
a _key_ part and a _value_ part. The key part is either a logic
operator (and/or/not), or a reference to a field, the value part is
either a plain value, or a value operator.

When a query is run against a document, where each term is scored
individually and then summed. (This implies "or").

Example queries:

```
[title: "hoi"]
[title: [_eq: "hoi"]]
[_and: [name: "Arjan", age: 36]]
[_or: [name: "Arjan", age: 36]]
[_not: [title: "foo"]]
```

Full documentation can be found at [https://hexdocs.pm/match_engine](https://hexdocs.pm/match_engine/MatchEngine.html).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `match_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:match_engine, "~> 1.0"}
  ]
end
```

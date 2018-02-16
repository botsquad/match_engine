# MatchEngine

A query language for filtering and scoring of documents, inspired by
the MongoDB query language and Solr.

```
[title: "hoi"]
[title: [_eq: "hoi"]]
[_and: [name: "Arjan", age: 36]]
[_or: [name: "Arjan", age: 36]]

[_not: [title: "foo"]]

```

## Operators
### `_eq`

Equality. Also doubles as set operator.

### `_sim`

Normalized string similarity. The max of the Normalised Levenshtein
distance and Jaro distance.

### `_regex`

Match a regex.
Scores on the length of match divided by the total string length.

###  `_and`

Combine matchers, multiplying the score. When one of the matchers
returns 0, the total score is 0 as well.

### `_or`

Combine matchers, adding the scores.

### `_not`

Reverse the score of the nested matchers. (when score > 0, return 0, otherwise, return 1.


### Matcher weights

`w: 10` can be added to a matcher term to boost its score by the given weight.

`b: true` can be added to force a score of 1 when the score is > 0.




## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `match_engine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:match_engine, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/match_engine](https://hexdocs.pm/match_engine).

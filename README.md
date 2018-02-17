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

Nested objects follow the shape of the data:

```
[user: [name: "Arjan"]]
[_not: [user: [name: "Arjan"]]]
```

## Query language

The query language consists of a nested Elixir "keyword list".

A query is a list of term matches, where each term is scored
individually and then summed. (This implies "or").



## Operators

### `_eq`

Scores on the equality of the argument.

    [title: "hello"]
    [title: [_eq: "hello"]]

Can also be used when the input document contains a list of values for the given field.


### `_in`

Scores when the document's value is a member of the given list.

    [role: [_in: ["developer", "freelancer"]]]



### `_sim`

Normalized string similarity. The max of the Normalised Levenshtein
distance and Jaro distance.

### `_geo`

Score on the distance of the given location


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

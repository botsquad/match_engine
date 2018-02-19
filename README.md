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

The queries can be run by calling `MatchEngine.score_all/2` or `MatchEngine.filter_all/2`.

Queries are first preprocessed, and then executed on a list of search
"documents". A "document" is just a normal Elixir map, with string
keys.

The preprocessing phase compiles any regexes, checks whether all
operators exist, and de-nests nested field structures.

The query phase runs the preprocessed query for each document in the
list, by calculating the score for the given document, given the
query. This score, including any additional metadata, is returned in a
`_match` map inside the document.


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

### `_nin`

Scores when the document's value is *not* a member of the given list.

    [role: [_nin: ["recruiter"]]]


### `_sim`

Normalized string similarity. The max of the Normalised Levenshtein
distance and Jaro distance.


### `_regex`

Match a regular expression. The input is a string, which gets compiled
into a regex. This operator scores on the length of match divided by
the total string length. It is possible to add named captures to the
regex, which then get added to the `_match` metadata map, as seen in the following exapmle:

    # regex matches entire string, 100% score
    assert %{score: 1} == score([title: [_regex: "foo"]], %{"title" => "foo"})
    # regex matches with a capture called 'name'. It is boosted by weight.
    assert %{:score => 1.6, "name" => "food"} == score([title: [_regex: "(?P<name>foo[dl])", w: 4]], %{"title" => "foodtrucks"})

The regex match can also be inversed, where the document value is
treated as the regular expression, and the query input is treated as
the string to be matched. (No captures are supported in this case).

    assert %{score: 0.5} == score([title: [_regex: "foobar", inverse: true]], %{"title" => "foo"})


### `_geo`

Calculate document score based on its geographical distance to a given
point. The geo distance (both in the operator and in the document) can
be given as:

 - A regular list, e.g. `[4.56, 52.33]`
 - A keyword list, e.g. `[lat: 52.33, lon: 4.56]`
 - A map with atom keys, e.g. `%{lat: 52.33, lon: 4.56}`
 - A map with string keys, e.g. `%{"lat" => 52.33, "lon" => 4.56}`

The calculated `distance` is returned in meters, as part of the `_match` map.

An extra argument, `max_distance` can be given to the operator which
specifies the maximum cutoff point. It defaults to 100km. (100_000).
Distance is scored logarithmically with respect to the maximum
distance.

    doc = %{"location" => %{"lat" => 52.340500999999996, "lon" => 4.8832816}}
    q = [location: [_geo: [lat: 52.340500999999996, lon: 4.8832816]]]
    assert %{score: 1, distance: 0.0} == score(q, doc)


### `_time`

Score by an UTC timestamp, relative to the given time.

    t1 = "2018-02-19T15:29:53.672235Z"
    t2 = "2018-02-19T15:09:53.672235Z"
    assert %{score: s} = score([inserted_at: [_time: t1]], %{"inserted_at" => t2})

This way, documents can be returned in order of recency.


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

# MatchEngine

[![CI](https://github.com/botsquad/match_engine/actions/workflows/elixir.yml/badge.svg)](https://github.com/botsquad/match_engine/actions/workflows/elixir.yml)
[![Module Version](https://img.shields.io/hexpm/v/match_engine.svg)](https://hex.pm/packages/match_engine)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/match_engine/)
[![Total Download](https://img.shields.io/hexpm/dt/match_engine.svg)](https://hex.pm/packages/match_engine)
[![License](https://img.shields.io/hexpm/l/match_engine.svg)](https://github.com/botsquad/match_engine/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/botsquad/match_engine.svg)](https://github.com/botsquad/match_engine/commits/master)

<!-- MDOC !-->

MatchEngine is an in-memory matching/filtering engine with
MongoDB-like query syntax.

## Introduction

The query language consists of nested Elixir "keyword list". Each
component of the query consists of a _key_ part and a _value_
part. The key part is either a logic operator (and/or/not), or a
reference to a field, the value part is either a plain value, or a
value operator.

When a query is run against a document, where each term is scored
individually and then summed. (This implies "or"). Some example
queries:

```
[title: "hoi"]
[title: [_eq: "hoi"]]
[_and: [name: "John", age: 36]]
[_or: [name: "John", age: 36]]
[_not: [title: "foo"]]
```

Two ways of saying "Score all documents in which the title equals `"hoi"`":

```
[title: "hoi"]
[title: [_eq: "hoi"]]
```

Combining various matchers with logic operators:

```
[_and: [name: "John", age: 36]]
[_or: [name: "John", age: 36]]
[_not: [title: "foo"]]
```

Performing matches in nested objects is also possible; the query
simply follows the shape of the data.

Given a document consisting of a nested structure, `%{"user" => %{"name" => "John"}}`:

"User name equals John":

```
[user: [name: "John"]]
```

"User name does not equal John":

```
[_not: [user: [name: "John"]]]
```

> Note that this is a different approach for nesting fields than MongoDB, which uses dot notation for field nesting.

## Query execution

The queries can be run by calling `MatchEngine.score_all/2` or `MatchEngine.filter_all/2`.

Queries are first preprocessed, and then executed on a list of search
"documents". A "document" is just a normal Elixir map, with string
keys.

The preprocessing phase compiles any regexes, checks whether all
operators exist, and de-nests nested field structures.

The query phase runs the preprocessed query for each document in the
list, by calculating the score for the given document, given the
query. When using filter_all/2, documents with a zero score are
removed from the input list. When using score_all, the list is
sorted on score, descending, and this score, including any
additional metadata, is returned in a `"_match"` map inside the
document.

## Value operators

_Value operators_ work on an individual field. Various operators can
be used to calculate a score for a given field.

### `_eq`

Scores on the equality of the argument.

```
[title: "hello"]
[title: [_eq: "hello"]]
```

### `_ne`

Scores on the *in*equality of the argument. ("Not equals")

```
[title: [_ne: "hello"]]
```

### `_has`

Scores when the document's value contains a member of the given list or contains the given word or words

```
[tag: [_has: ["production"]]]
[title: [_has: "The"]]
[title: [_has: ["The", "title"]]]
```

### `_hasnt`

Scores when the document's value does NOT contains any member of the given list
or does not contain any of the given word or words

```
[tag: [_hasnt: ["production"]]]
[title: [_hasnt: "The"]]
[title: [_hasnt: ["The", "title"]]]
```

### `_in`

Scores when the document's value is a member of the given list.

```
[role: [_in: ["developer", "freelancer"]]]
```

### `_nin`

Scores when the document's value is _not_ a member of the given list.

```
[role: [_nin: ["recruiter"]]]
```

### `_lt`, `_gt`, `_lte`, `_gte`

Scores on using the comparison operators <, >, <= and >=.

```
[age: [_gt: 18]]
```

### `_sim`

Normalized string similarity. The max of the Normalised Levenshtein
distance and Jaro distance.

### `_regex`

Match a regular expression. The input is a string, which gets compiled
into a regex. This operator scores on the length of match divided by
the total string length. It is possible to add named captures to the
regex, which then get added to the `_match` metadata map, as seen in the following example:

```
# regex matches entire string, 100% score
assert %{"score" => 1} == score([title: [_regex: "foo"]], %{"title" => "foo"})
# regex matches with a capture called 'name'. It is boosted by weight.
assert %{"score" => 1.6, "name" => "food"} == score([title: [_regex: "(?P<name>foo[dl])", w: 4]], %{"title" => "foodtrucks"})
```

The regex match can also be inversed, where the document value is
treated as the regular expression, and the query input is treated as
the string to be matched. (No captures are supported in this case).

```
assert %{"score" => 0.5} == score([title: [_regex: "foobar", inverse: true]], %{"title" => "foo"})
```

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

```
doc = %{"location" => %{"lat" => 52.340500999999996, "lon" => 4.8832816}}
q = [location: [_geo: [lat: 52.340500999999996, lon: 4.8832816]]]
assert %{"score" => 1, "distance" => 0.0} == score(q, doc)
```

When `radius` is given as an option, all geo points that are within
the radius will score a 1 and the max_distance scoring will be in
effect for distances larger than the radius.

### `_geo_poly`

Calculate document score based on its containment inside a given
geographical polygon.

Accepts a list of geographical coordinates, each in the same format
as `_geo`.

Like `_geo`, the `max_distance` option can be given to the operator
which specifies the maximum cutoff point. It defaults to
100km. (100_000). Distance is scored logarithmically with respect
to the maximum distance.

When the point is inside the polygon, the score is always 1. Only
when the point is outside the polygon, the geographical distance
from the document point to the closest point on the edge of the
polygon is calculated and scored based on the `max_distance`
setting.

### `_time`

Score by an UTC timestamp, relative to the given time.

```
t1 = "2018-02-19T15:29:53.672235Z"
t2 = "2018-02-19T15:09:53.672235Z"
assert %{"score" => s} = score([inserted_at: [_time: t1]], %{"inserted_at" => t2})
```

This way, documents can be returned in order of recency.

## Logic operators

### `_and`

Combine matchers, multiplying the score. When one of the matchers
returns 0, the total score is 0 as well.

```
[_and: [name: "John", age: 36]]
```

### `_or`

Combine matchers, adding the scores.

```
[_or: [name: "John", id: 12]]
```

### `_not`

Reverse the score of the nested matchers. (when score > 0, return 0, otherwise, return 1.

```
[_not: [title: "foo"]]
```

### Matcher weights

`w: 10` can be added to a matcher term to boost its score by the given weight.

```
[title: [_eq: "Pete", w: 5], summary: [_sim: "hello", w: 2]]
```

`b: true` can be added to force a score of 1 when the score is > 0.

```
[title: [_sim: "hello", b: true]]
```

## Map syntax for queries

Instead of keyword lists, queries can also be specified as maps. In
this case, the keys of the map need to be strings. Query maps are
meant to be used from user-generated input, and can be easily created from JSON files.

```
[_not: [title: "foo"]]
# can also be written as:
%{"_not" => %{"title" => "foo"}}

[title: [_eq: "Pete", w: 5], summary: [_sim: "hello", w: 2]]
# can also be written as:
%{"title" => %{"_eq" => "Pete", "w" => 5}, "summary" => %{"_sim" => "hello", "w" => 2}}
```

<!-- MDOC !-->

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

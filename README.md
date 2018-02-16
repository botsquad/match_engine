# MatchEngine

**TODO: Add description**

```
[title: "hoi"]
[title: [_eq: "hoi"]]
[_and: [name: "Arjan", age: 36]]
[_or: [name: "Arjan", age: 36]]

[_not: [title: "foo"]]

```

operators
_eq:
_sim:
_regex:
_and:
_or:
_not

options:
w: score weight
b: binary scoring t/f

divide in score and filter expression. score = _or, filter = _and.


## Query language

Inspired by the [Lucene query language](https://lucene.apache.org/core/2_9_4/queryparsersyntax.html)

Examples:

```elixir

# exact match on a field
title=Foo

# proximity match
title:foo

# regex match
title~foo

# AND
title:foo AND field:bar

# NOT
NOT title:foo
NOT title:foo

# boosting
title:foo^3

# subfields of document
user.name:Arjan

```

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

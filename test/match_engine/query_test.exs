defmodule MatchEngine.QueryTest do
  use ExUnit.Case

  import MatchEngine.Query

  test "query preprocessing" do

    assert [ {["user"], [_eq: "Arjan"]}] ==
      preprocess [user: "Arjan"]

    assert [ {["user", "name"], [_eq: "Arjan"]}] ==
      preprocess [user: [name: "Arjan"]]

    assert [ {["user", "name"], [_eq: "Arjan"]}, {["age"], [_eq: 38]}] ==
      preprocess [user: [name: "Arjan"], age: 38]

    assert [ {["user", "name"], [_eq: "Arjan"]}, {["user", "age"], [_eq: 38]}] ==
      preprocess [user: [name: "Arjan", age: 38]]

    assert [ {["user", "name"], [_eq: "Arjan"]}, {["user", "test", "a"], [_eq: 1]}, {["user", "test", "b"], [_eq: 2]}] ==
      preprocess [user: [name: "Arjan", test: [a: 1, b: 2]]]

    assert [ {["user"], [_eq: "Arjan"]}] ==
      preprocess [user: [_eq: "Arjan"]]

    assert [ {["user", "name"], [_sim: "Arjan"]}] ==
      preprocess [user: [name: [_sim: "Arjan"]]]

    assert [ _not: [{["user", "name"], [_sim: "Arjan"]}]] ==
      preprocess [_not: [user: [name: [_sim: "Arjan"]]]]

    # assert [
    #   _not: [{["user", "age"], 36}],
    #   _not: [{["user", "name"], [_sim: "Arjan"]}]] ==
    #   preprocess [_not: [user: [age: 36, name: [_sim: "Arjan"]]]]

    assert [
      _and: [
        {["user", "name"], [_eq: "Arjan"]},
        {["user", "age"], [_eq: 38]}
      ]
    ] ==
      preprocess [_and: [user: [name: "Arjan", age: 38]]]

    assert [
      _and: [
        {["user", "name"], [_eq: "Arjan"]},
        {["user", "age"], [_eq: 38]}
      ]
    ] ==
      preprocess [user: [_and: [name: "Arjan", age: 38]]]

    assert [
      _or: [
        {["user", "name"], [_sim: "Arjan"]},
        {["user", "age"], [_eq: 38]}
      ]
    ] ==
      preprocess [user: [_or: [name: [_sim: "Arjan"], age: 38]]]

    assert [ {["user"], [_regex: %Regex{}]}] =
      preprocess [user: [_regex: "Arjan"]]

    assert [
      _and: [
        {["title"], [_eq: "Arjan"]},
        {["title"], [_sim: 38]}
      ]
    ] ==
      preprocess [title: [_and: [ [_eq: "Arjan"], [_sim: 38]]]]

  end

  test "map queries" do

    assert [ {["user"], [_eq: "Arjan"]}] ==
      preprocess %{"user" => "Arjan"}

    assert [ {["user"], [_eq: "Arjan"]}] ==
      preprocess %{"user" => %{"_eq" => "Arjan"}}

    assert [
      _or: [
        {["user", "name"], [_sim: "Arjan"]},
        {["user", "age"], [_eq: 38]}
      ]
    ] ==
      preprocess %{"user" => %{"_or" => %{"name" => %{"_sim" => "Arjan"}, "age" => 38}}}

    assert [
      _and: [
        {["title"], [_eq: "Arjan"]},
        {["title"], [_sim: 38]}
      ]
    ] ==
      preprocess %{"title" => %{"_and" => [ %{"_eq" => "Arjan"}, %{"_sim" => 38}]}}

  end

  test "unknown leaf operator" do
    assert_raise RuntimeError, fn -> preprocess([location: [_bla: 1]]) end
  end

  test "unknown logic operator" do
    assert_raise RuntimeError, fn -> preprocess([_bla: 1]) end
  end

end

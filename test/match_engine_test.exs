defmodule MatchEngineTest do
  use ExUnit.Case
  doctest MatchEngine


  import MatchEngine

  describe "scoring" do
    test "basic" do
      assert 0 == score([], %{})
      # basic equals
      assert 1 == score([title: "foo"], %{"title" => "foo"})
      # implied OR
      assert 2 == score([title: "foo", age: 34], %{"title" => "foo", "age" => 34})
    end

    test "deep fields" do
      assert 1 == score([user@title: "foo"], %{"user" => %{"title" => "foo"}})
    end

    test "eq" do
      assert 1 == score([title: [_eq: "foo"]], %{"title" => "foo"})
    end

    test "ne" do
      assert 0 == score([title: [_ne: "foo"]], %{"title" => "foo"})
    end

    test "eq w/ array in doc" do
      assert 1 == score([title: [_eq: "foo"]], %{"title" => ["foo", "bar"]})
    end

    test "set overlap (eq w/ arrays on both side)" do
      assert 1 == score([title: [_eq: ["foo"]]], %{"title" => ["foo"]})
      assert 0 == score([title: [_eq: ["foo"]]], %{"title" => ["bar"]})
      assert 1 == score([title: [_eq: ["foo", "bar"]]], %{"title" => ["foo", "bar"]})
      assert 0.5 == score([title: [_eq: ["foo"]]], %{"title" => ["foo", "bar"]})
      assert 0.25 == score([title: [_eq: ["foo"]]], %{"title" => ["foo", "bar", "a", "b"]})
      assert 0.5 == score([title: [_eq: ["a", "foo"]]], %{"title" => ["foo", "bar", "a", "b"]})
    end

    test "weight" do
      assert 2 == score([title: [_eq: "foo", w: 2]], %{"title" => "foo"})
    end

    test "regex" do
      assert 1 == score([title: [_regex: "foo"]], %{"title" => "foo"})
      assert 0.5 == score([title: [_regex: "foo"]], %{"title" => "foofoo"})
      assert 2 == score([title: [_regex: "foo", w: 4]], %{"title" => "foofoo"})
    end

    test "regex binary score" do
      assert 1 == score([title: [_regex: "foo", b: true]], %{"title" => "foofoo"})
    end

    test "sim" do
      assert 1 == score([title: [_sim: "foo"]], %{"title" => "foo"})
      assert 0.9 < score([title: [_sim: "foo"]], %{"title" => "food"})
      assert 1 == score([title: [_sim: "foo", b: true]], %{"title" => "food"})
    end

    test "sim w/ array document" do
      assert 1 == score([title: [_sim: "foo"]], %{"title" => ["foo", "bar"]})
      assert 1 == score([learn@sentences: [_sim: "foo"]], %{"learn" => %{"sentences" => ["foo", "bar"]}})
    end

    test "and" do
      assert 0.3 < score([_and: [title: [_sim: "foo"], title: [_sim: "bar"]]], %{"title" => "foo bar"})
      assert 0.0 == score([_and: [title: [_sim: "xxxx"], title: [_sim: "bar"]]], %{"title" => "foo bar"})
    end

    test "or" do
      assert 0.3 < score([_or: [title: [_sim: "foo"], title: [_sim: "bar"]]], %{"title" => "foo bar"})
      assert 0.3 < score([_or: [title: [_sim: "xxxx"], title: [_sim: "bar"]]], %{"title" => "foo bar"})
    end

    test "not" do
      assert 0 == score([_not: [title: "foo"]], %{"title" => "foo"})
      assert 1 == score([_not: [title: "foo"]], %{"title" => "bar"})
      assert 0 == score([_not: [title: [_sim: "foo"]]], %{"title" => "foo"})
      assert 0 == score([_not: [title: [_sim: "food"]]], %{"title" => "foo"})
      assert 1 == score([_not: [title: [_sim: "food"]]], %{"title" => "bla"})
    end

    test "in" do
      assert 1 == score([title: [_in: ~w(foo bar)]], %{"title" => "foo"})
    end
  end


  describe "filter" do

    test "basic" do
      assert false == filter([], %{})
      # basic equals
      assert filter([title: "foo"], %{"title" => "foo"})
      # implied AND
      assert filter([title: "foo", age: 34], %{"title" => "foo", "age" => 34})
      refute filter([title: "foo", age: 34], %{"title" => "foo", "age" => 33})
    end

    test "deep fields" do
      assert filter([user@title: "foo"], %{"user" => %{"title" => "foo"}})
    end

    test "eq" do
      assert filter([title: [_eq: "foo"]], %{"title" => "foo"})
    end

    test "eq w/ array in doc" do
      assert filter([title: [_eq: "foo"]], %{"title" => ["foo", "bar"]})
      refute filter([title: [_eq: "xx"]], %{"title" => ["foo", "bar"]})
    end
  end

end

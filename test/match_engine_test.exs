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

    test "eq" do
      assert 1 == score([title: [_eq: "foo"]], %{"title" => "foo"})
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
    end

    test "and" do
      assert 0.3 < score([_and: [title: [_sim: "foo"], title: [_sim: "bar"]]], %{"title" => "foo bar"})
      assert 0.0 < score([_and: [title: [_sim: "blaatschaap"], title: [_sim: "bar"]]], %{"title" => "foo bar"})

    end

  end

end

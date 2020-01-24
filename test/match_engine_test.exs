defmodule MatchEngineTest do
  use ExUnit.Case
  doctest MatchEngine

  import MatchEngine

  describe "scoring" do
    test "basic" do
      assert %{"score" => 0} == score([], %{})
      # basic equals
      assert %{"score" => 1} == score([title: "foo"], %{"title" => "foo"})
      # implied OR
      assert %{"score" => 2} == score([title: "foo", age: 34], %{"title" => "foo", "age" => 34})
    end

    test "score on non-map 'document'" do
      assert %{"score" => 1} == score([_eq: "foo"], "foo")
      assert %{"score" => 0} == score([_eq: "foo"], "xfoo")
    end

    test "deep fields" do
      assert %{"score" => 1} == score([user: [title: "foo"]], %{"user" => %{"title" => "foo"}})
    end

    test "eq" do
      assert %{"score" => 1} == score([title: [_eq: "foo"]], %{"title" => "foo"})
    end

    test "ne" do
      assert %{"score" => 0} == score([title: [_ne: "foo"]], %{"title" => "foo"})
    end

    test "equality operators" do
      assert %{"score" => 0} == score([title: [_gt: 10]], %{"title" => 9})
      assert %{"score" => 0} == score([title: [_gt: 10]], %{"title" => 10})
      assert %{"score" => 1} == score([title: [_gt: 10]], %{"title" => 11})

      assert %{"score" => 1} == score([title: [_lte: 10]], %{"title" => 9})
      assert %{"score" => 1} == score([title: [_lte: 10]], %{"title" => 10})
      assert %{"score" => 0} == score([title: [_lte: 10]], %{"title" => 11})

      assert %{"score" => 1} == score([title: [_lt: 10]], %{"title" => 9})
      assert %{"score" => 0} == score([title: [_lt: 10]], %{"title" => 10})
      assert %{"score" => 0} == score([title: [_lt: 10]], %{"title" => 11})

      assert %{"score" => 0} == score([title: [_gte: 10]], %{"title" => 9})
      assert %{"score" => 1} == score([title: [_gte: 10]], %{"title" => 10})
      assert %{"score" => 1} == score([title: [_gte: 10]], %{"title" => 11})
    end

    test "eq w/ array in doc" do
      assert %{"score" => 1} == score([title: [_eq: "foo"]], %{"title" => ["foo", "bar"]})
    end

    test "set overlap (eq w/ arrays on both side)" do
      assert %{"score" => 1} == score([title: [_eq: ["foo"]]], %{"title" => ["foo"]})
      assert %{"score" => 0} == score([title: [_eq: ["foo"]]], %{"title" => ["bar"]})

      assert %{"score" => 1} ==
               score([title: [_eq: ["foo", "bar"]]], %{"title" => ["foo", "bar"]})

      assert %{"score" => 0.5} == score([title: [_eq: ["foo"]]], %{"title" => ["foo", "bar"]})

      assert %{"score" => 0.25} ==
               score([title: [_eq: ["foo"]]], %{"title" => ["foo", "bar", "a", "b"]})

      assert %{"score" => 0.5} ==
               score([title: [_eq: ["a", "foo"]]], %{"title" => ["foo", "bar", "a", "b"]})
    end

    test "weight" do
      assert %{"score" => 2} == score([title: [_eq: "foo", w: 2]], %{"title" => "foo"})
    end

    test "regex" do
      assert %{"score" => 1} == score([title: [_regex: "foo"]], %{"title" => "foo"})
      assert %{"score" => 0.5} == score([title: [_regex: "foo"]], %{"title" => "foofoo"})
      assert %{"score" => 2} == score([title: [_regex: "foo", w: 4]], %{"title" => "foofoo"})

      assert %{"score" => 0} == score([title: [_regex: "", w: 4]], %{"title" => "sdf"})

      assert %{"score" => 1.6, "name" => "food"} ==
               score([title: [_regex: "(?P<name>foo[dl])", w: 4]], %{"title" => "foodtrucks"})
    end

    test "regex - with unicode" do
      assert %{"score" => 1} == score([title: [_regex: "hoi \\w+"]], %{"title" => "hoi áép"})
    end

    test "regex - inverse" do
      assert %{"score" => 1} ==
               score([title: [_regex: "foo", inverse: true]], %{"title" => "foo"})

      assert %{"score" => 0} ==
               score([title: [_regex: "", inverse: true]], %{"title" => ""})

      assert %{"score" => 0} ==
               score([title: [_regex: "foo", inverse: true]], %{"title" => "foofoo"})

      assert %{"score" => 0.5} ==
               score([title: [_regex: "foobar", inverse: true]], %{"title" => "Foo"})
    end

    test "regex - inverse w/ unicode" do
      assert %{"score" => 1.0} ==
               score([title: [_regex: "foobár", inverse: true]], %{"title" => "foo\\w+"})
    end

    test "regex binary score" do
      assert %{"score" => 1} == score([title: [_regex: "foo", b: true]], %{"title" => "foofoo"})
    end

    test "sim" do
      assert %{"score" => 0} == score([title: [_sim: ""]], %{"title" => ""})

      assert %{"score" => 1} == score([title: [_sim: "foo"]], %{"title" => "foo"})
      assert %{"score" => s} = score([title: [_sim: "foo"]], %{"title" => "food"})
      assert 0.9 < s
      assert %{"score" => 1} == score([title: [_sim: "foo", b: true]], %{"title" => "food"})
    end

    test "sim w/ array document" do
      assert %{"score" => 1} == score([title: [_sim: "foo"]], %{"title" => ["foo", "bar"]})

      assert %{"score" => 1} ==
               score([learn: [sentences: [_sim: "foo"]]], %{
                 "learn" => %{"sentences" => ["foo", "bar"]}
               })
    end

    test "and" do
      assert %{"score" => s} =
               score([_and: [title: [_sim: "foo"], title: [_sim: "bar"]]], %{"title" => "foo bar"})

      assert 0.3 < s

      assert %{"score" => 0.0} ==
               score([_and: [title: [_sim: "xxxx"], title: [_sim: "bar"]]], %{
                 "title" => "foo bar"
               })
    end

    test "or" do
      assert %{"score" => s} =
               score([_or: [title: [_sim: "foo"], title: [_sim: "bar"]]], %{"title" => "foo bar"})

      assert 0.3 < s

      assert %{"score" => s} =
               score([_or: [title: [_sim: "xxxx"], title: [_sim: "bar"]]], %{"title" => "foo bar"})

      assert 0.3 < s
    end

    test "not" do
      assert %{"score" => 0} == score([_not: [title: "foo"]], %{"title" => "foo"})
      assert %{"score" => 1} == score([_not: [title: "foo"]], %{"title" => "bar"})
      assert %{"score" => 0} == score([_not: [title: [_sim: "foo"]]], %{"title" => "foo"})
      assert %{"score" => 0} == score([_not: [title: [_sim: "food"]]], %{"title" => "foo"})
      assert %{"score" => 1} == score([_not: [title: [_sim: "food"]]], %{"title" => "bla"})
    end

    test "in" do
      assert %{"score" => 1} == score([title: [_in: ~w(foo bar)]], %{"title" => "foo"})
    end

    test "not in" do
      assert %{"score" => 0} == score([title: [_not: [_in: ~w(foo bar)]]], %{"title" => "foo"})
      assert %{"score" => 0} == score([title: [_nin: ~w(foo bar)]], %{"title" => "foo"})
    end

    test "geo" do
      doc = %{"location" => %{"lat" => 52.340500999999996, "lon" => 4.8832816}}
      q = [location: [_geo: [lat: 52.340500999999996, lon: 4.8832816]]]
      assert %{"score" => 1, "distance" => 0.0} == score(q, doc)

      q = [location: [_geo: [lat: 51.340500999999996, lon: 3.8832816]]]
      assert %{"score" => 0, "distance" => d} = score(q, doc)
      assert 130 == div(trunc(d), 1000)
    end

    test "time" do
      time = DateTime.to_iso8601(DateTime.utc_now())
      assert %{"score" => 1} == score([inserted_at: [_time: time]], %{"inserted_at" => time})

      t1 = "2018-02-19T15:29:53.672235Z"
      t2 = "2018-02-19T15:09:53.672235Z"
      assert %{"score" => s} = score([inserted_at: [_time: t1]], %{"inserted_at" => t2})
      assert 0.3 < s
    end

    test "unknown leaf operator" do
      assert_raise RuntimeError, fn -> score([location: [_bla: 1]], %{}) end
    end
  end

  describe "filter" do
    test "basic" do
      assert %{"score" => 0} = filter([], %{})
      # basic equals
      assert %{"score" => 1} = filter([title: "foo"], %{"title" => "foo"})
      # implied AND
      assert %{"score" => 1} = filter([title: "foo", age: 34], %{"title" => "foo", "age" => 34})
      assert %{"score" => 0} = filter([title: "foo", age: 34], %{"title" => "foo", "age" => 33})
    end

    test "deep fields" do
      assert %{"score" => 1} = filter([user: [title: "foo"]], %{"user" => %{"title" => "foo"}})
    end

    test "eq" do
      assert %{"score" => 1} = filter([title: [_eq: "foo"]], %{"title" => "foo"})
    end

    test "eq w/ array in doc" do
      assert %{"score" => 1} = filter([title: [_eq: "foo"]], %{"title" => ["foo", "bar"]})
      assert %{"score" => 0} = filter([title: [_eq: "xx"]], %{"title" => ["foo", "bar"]})

      assert %{"score" => 0} = filter([title: [_eq: []]], %{"title" => []})
    end
  end
end

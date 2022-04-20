defmodule MatchEngine.ScoringTests do
  use ExUnit.Case

  @data "test/fixture/regio.json" |> File.read!() |> Poison.decode!()

  import MatchEngine

  test "score_all" do
    docs = @data["value"]

    result =
      docs
      |> score_all(title: "Amsterdam")
      |> Enum.slice(0..1)

    assert [%{"_match" => %{"score" => 1}}, %{"_match" => %{"score" => 0}}] = result
  end

  test "filter_all" do
    docs = @data["value"]

    assert [doc = %{"title" => "Amsterdam"}] =
             filter_all(docs, title: "Amsterdam", key: "GM0363    ")

    refute doc["_match"]
  end

  test "filter_all on non-map doc" do
    docs = ~w(a b c d e f g)
    assert ~w(a b c d) = filter_all(docs, _lt: "e")
  end

  test "score_all (map)" do
    docs = @data["value"]

    result =
      docs
      |> score_all(%{"title" => %{"_eq" => "Amsterdam"}})
      |> Enum.slice(0..1)

    assert [%{"_match" => %{"score" => 1}}, %{"_match" => %{"score" => 0}}] = result
  end

  test "score_all (map), weighted" do
    docs = @data["value"]

    result =
      docs
      |> score_all(%{"title" => %{"_eq" => "Amsterdam", "w" => 2}})
      |> Enum.slice(0..1)

    assert [%{"_match" => %{"score" => 2}}, %{"_match" => %{"score" => 0}}] = result
  end

  test "score_all geo w/ maps" do
    docs = [
      %{"city" => "amsterdam", "location" => %{"lat" => 52.363711, "lon" => 4.882609}},
      %{"city" => "new york", "location" => %{"lat" => 40.690902, "lon" => -73.922038}}
    ]

    q = %{"location" => %{"_geo" => %{"lat" => 52.3303715, "lon" => 4.8813892}}}

    [first, second] =
      docs
      |> score_all(q)

    assert first["_match"]["score"] > 0
    assert first["_match"]["distance"] > 0

    assert first["_match"]["distance"] < second["_match"]["distance"]
  end

  test "score_all geo, invalid locations" do
    docs = [
      %{"city" => "amsterdam", "location" => %{"lat" => 52.363711, "lon" => 4.882609}},
      %{"city" => "amsterdam2", "location" => "52.393711,4.882609"},
      %{"city" => "new york", "location" => %{"lat" => 40.690902, "lon" => -73.922038}},
      %{"city" => "error", "location" => "error"}
    ]

    q = %{"location" => %{"_geo" => %{"lat" => 52.3303715, "lon" => 4.8813892}}}

    scored = docs |> score_all(q)

    first = List.first(scored)

    assert first["_match"]["score"] > 0
    assert first["_match"]["distance"] > 0

    error = Enum.find(scored, &(&1["city"] == "error"))
    assert error["_match"]["score"] == 0
    # no distance for erroneous lat/lng pairs
    assert error["_match"]["distance"] == nil
  end

  test "score_all geo_poly" do
    q = %{"_geo_poly" => [[1, 1], [1, 0], [0, 0], [0, 1]]}

    # outside
    assert score(q, %{"lat" => 2, "lon" => 2})["score"] == 0

    # inside
    assert score(q, %{"lat" => 0.5, "lon" => 0.5})["score"] == 1

    # on edge
    assert score(q, %{"lat" => 0.5, "lon" => 0})["score"] == 1
  end

  @amsterdam [
    [4.8950958251953125, 52.389849169813694],
    [4.842224121093749, 52.348763181988105],
    [4.9321746826171875, 52.347504844796546],
    [4.94110107421875, 52.38020997185712],
    [4.8950958251953125, 52.389849169813694]
  ]

  test "score_all geo_poly w/ max distance " do
    docs = [
      %{"city" => "inside", "location" => [4.85595703125, 52.35547370875268]},
      %{"city" => "outside", "location" => [4.9156951904296875, 52.32946474208912]}
    ]

    q = %{
      "location" => %{
        "_geo_poly" => @amsterdam,
        "max_distance" => 5000
      }
    }

    assert [
             %{"city" => "inside", "_match" => %{"score" => 1}},
             %{"city" => "outside", "_match" => %{"score" => s, "distance" => d}}
           ] = docs |> score_all(q)

    assert trunc(d) == 2031
    # score = 0.105
    assert trunc(s * 1000) == 105
  end
end

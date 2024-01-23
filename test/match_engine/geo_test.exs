defmodule MatchEngine.GeoTest do
  use ExUnit.Case

  alias MatchEngine.Geo

  test "coerce_location/1" do
    assert {2, 1} = Geo.coerce_location(%{"lat" => 1, "lon" => 2})
    assert :error = Geo.coerce_location(%{"url" => "foo", "type" => "blabla"})

    assert {2.0, 1.0} = Geo.coerce_location("1,2")
    assert {2.12, 1.1} = Geo.coerce_location("1.1,2.12")

    loc = {2, 1}
    assert ^loc = Geo.coerce_location([2, 1])
    assert ^loc = Geo.coerce_location(%{lat: 1, lon: 2})
    assert ^loc = Geo.coerce_location(lat: 1, lon: 2)
    assert ^loc = Geo.coerce_location(%{"lat" => 1, "lon" => 2})

    assert :error = Geo.coerce_location("foo")
  end

  test "closest_point" do
    p = {0, 0}
    assert {0, 0} == Geo.closest_point(p, [{0, 0}])

    assert {0, 0} == Geo.closest_point(p, [{0, 0}, {1, 1}])

    assert {0, 0} == Geo.closest_point(p, [{-1, -1}, {1, 1}])

    assert {0, 0} == Geo.closest_point({-2, 2}, [{-1, -1}, {1, 1}])

    assert {-1, -1} == Geo.closest_point({-200, -12}, [{-1, -1}, {1, 1}])
    assert {1, 1} == Geo.closest_point({200, 12}, [{-1, -1}, {1, 1}])
  end
end

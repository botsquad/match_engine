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
end

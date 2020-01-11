defmodule MatchEngine.Geo do
  @moduledoc false

  @pi_over_180 3.14159265359 / 180.0
  @radius_of_earth_meters 6_371_008.8

  @doc """
  Returns the great circle distance in meters between two points in the form of
  `{longitude, latitude}`.
  ## Examples
  iex> Distance.GreatCircle.distance({-105.343, 39.984}, {-105.534, 39.123})
  97129.22118968463
  iex> Distance.GreatCircle.distance({-74.00597, 40.71427}, {-70.56656, -33.42628})
  8251609.780265334
  """
  def distance({lon1, lat1}, {lon2, lat2}) do
    a = :math.sin((lat2 - lat1) * @pi_over_180 / 2)
    b = :math.sin((lon2 - lon1) * @pi_over_180 / 2)

    s = a * a + b * b * :math.cos(lat1 * @pi_over_180) * :math.cos(lat2 * @pi_over_180)
    2 * :math.atan2(:math.sqrt(s), :math.sqrt(1 - s)) * @radius_of_earth_meters
  end

  @spec coerce_location(any()) :: {lon :: number(), lat :: number()} | :error
  def coerce_location(value) do
    case value do
      [lon, lat] when is_number(lon) and is_number(lat) ->
        {lon, lat}

      [lon: lon, lat: lat] when is_number(lon) and is_number(lat) ->
        {lon, lat}

      [lat: lat, lon: lon] when is_number(lon) and is_number(lat) ->
        {lon, lat}

      %{lat: lat, lon: lon} when is_number(lon) and is_number(lat) ->
        {lon, lat}

      %{"lat" => lat, "lon" => lon} when is_number(lon) and is_number(lat) ->
        {lon, lat}

      [{_, _} | _] = v ->
        coerce_location([v[:lon], v[:lat]])

      str when is_binary(str) ->
        with [latstr, lonstr] <- :binary.split(str, ","),
             {lat, ""} <- Float.parse(latstr),
             {lon, ""} <- Float.parse(lonstr) do
          {lon, lat}
        else
          _ ->
            :error
        end

      _ ->
        :error
    end
  end
end

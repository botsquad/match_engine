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

  def coerce_locations(list) when is_list(list) do
    list |> Enum.map(&coerce_location/1) |> Enum.reject(&(&1 == :error))
  end

  def coerce_locations(_) do
    []
  end

  def closest_point(_, [point]) do
    point
  end

  def closest_point(point, [_ | _] = points) do
    segments = Enum.chunk_every(points, 2, 1, [hd(points)])

    Enum.map(segments, fn [a, b] -> closest_point_on_line_segment(point, a, b) end)
    |> Enum.map(&{distance(point, &1), &1})
    |> Enum.sort()
    |> List.first()
    |> elem(1)
  end

  def closest_point_on_line_segment({x, y}, {x1, y1}, {x2, y2}) do
    a = x - x1
    b = y - y1
    c = x2 - x1
    d = y2 - y1

    dot = a * c + b * d
    len_sq = c * c + d * d

    param =
      if len_sq != 0 do
        dot / len_sq
      else
        -1
      end

    cond do
      param < 0.0 ->
        {x1, y1}

      param > 1.0 ->
        {x2, y2}

      true ->
        {x1 + param * c, y1 + param * d}
    end
  end
end

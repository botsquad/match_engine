defmodule MatchEngine.DataTests do
  use ExUnit.Case

  @data "test/fixture/regio.json" |> File.read!() |> Poison.decode!()

  import MatchEngine

  test "foo" do
    docs = @data["value"]

    # docs
    # |> score_all([title: "Amsterdam"])
    # |> Enum.slice(0..3)
    # |> IO.inspect(label: "x")

#    [user__title: "bla"]

    docs
    |> filter_all([title: "Amsterdam", key: "GM0363  "])
    |> Enum.slice(0..3)

#    title == "Aap"
#    title =~ "Aap" ||

  end

end

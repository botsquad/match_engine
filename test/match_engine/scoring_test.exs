defmodule MatchEngine.ScoringTests do
  use ExUnit.Case

  @data "test/fixture/regio.json" |> File.read!() |> Poison.decode!()

  import MatchEngine

  test "score_all" do
    docs = @data["value"]

    result = docs
    |> score_all([title: "Amsterdam"])
    |> Enum.slice(0..1)

    assert [%{_match: %{score: 1}}, %{_match: %{score: 0}}] = result
  end

  test "filter_all" do
    docs = @data["value"]

    assert [m] = filter_all(docs, [title: "Amsterdam", key: "GM0363    "])
    assert 1 == m._match.score
  end

end

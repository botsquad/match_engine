defmodule MatchEngine do
  @moduledoc """
  Documentation for MatchEngine.
  """

  defdelegate score(parts, doc), to: MatchEngine.Score
  defdelegate filter(parts, doc), to: MatchEngine.Score

end

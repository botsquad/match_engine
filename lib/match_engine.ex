defmodule MatchEngine do
  @moduledoc """
  Documentation for MatchEngine.
  """

  defdelegate score(parts, doc), to: MatchEngine.Score

end

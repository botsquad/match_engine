defmodule MatchEngine.Mixfile do
  use Mix.Project

  def project do
    [
      app: :match_engine,
      version: File.read!("VERSION"),
      elixir: "~> 1.12",
      elixirc_options: [warnings_as_errors: true],
      description: description(),
      package: package(),
      source_url: "https://github.com/botsquad/match_engine",
      homepage_url: "https://github.com/botsquad/match_engine",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp description do
    "In-memory matching/filtering engine with Mongo-like query syntax"
  end

  defp package do
    %{
      files: ["lib", "mix.exs", "*.md", "LICENSE", "VERSION"],
      maintainers: ["Arjan Scherpenisse"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/botsquad/match_engine"}
    }
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:timex, "~> 3.1"},
      {:simetric, "~> 0.2.0"},
      {:jason, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.19", runtime: false, only: :dev}
    ]
  end
end

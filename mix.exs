defmodule Aic.MixProject do
  use Mix.Project

  def project do
    [
      app: :aic,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
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
      # or latest version
      {:tesla, "~> 1.11"},
      # optional, required by JSON middleware
      {:jason, "~> 1.4"},
      # optional, required by Mint adapter, recommended
      {:mint, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

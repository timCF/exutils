defmodule Exutils.Mixfile do
  use Mix.Project

  def project do
    [
     app: :exutils,
     version: "0.0.1",
     #elixir: "~> 0.15.1",
     deps: deps,
     dialyzer: [plt_add_deps: true]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :hashex, :extask, :uuid],
     mod: {Exutils, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:hashex, github: "timCF/hashex"},
      {:extask, github: "timCF/extask"},
      {:uuid, github: "okeuday/uuid"}
    ]
  end
end

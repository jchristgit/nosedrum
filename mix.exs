defmodule Nosedrum.MixProject do
  use Mix.Project

  def project do
    [
      app: :nosedrum,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/jchristgit/nosedrum",
      homepage_url: "https://github.com/jchristgit/nosedrum",
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def package do
    [
      description: "A command framework for nostrum",
      licenses: ["ISC"],
      links: %{
        "Documentation" => "https://hexdocs.pm/nosedrum",
        "GitHub" => "https://github.com/jchristgit/nosedrum"
      },
      maintainers: ["Johannes Christ"]
    ]
  end

  defp docs do
    [
      groups_for_modules: [
        Functionality: [Nosedrum.Converters, Nosedrum.Helpers],
        Behaviours: [Nosedrum.Command, Nosedrum.Invoker, Nosedrum.Storage],
        Implementations: [Nosedrum.Invoker.Split, Nosedrum.Storage.ETS]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [],
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, "~> 0.2"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end
end

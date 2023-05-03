defmodule Nosedrum.MixProject do
  use Mix.Project

  def project do
    [
      app: :nosedrum,
      version: "0.5.0",
      elixir: "~> 1.12",
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
      # ???
      source_ref: "master",
      groups_for_functions: [
        Evaluation: &(&1[:section] == :evaluation),
        Predicates: &(&1[:section] == :predicates)
      ],
      groups_for_modules: [
        "Application Commands": [
          Nosedrum.ApplicationCommand,
          Nosedrum.Interactor,
          Nosedrum.Interactor.Dispatcher
        ],
        Functionality: [Nosedrum.Converters, Nosedrum.Helpers, Nosedrum.Predicates],
        Behaviours: [Nosedrum.Command, Nosedrum.Invoker, Nosedrum.MessageCache, Nosedrum.Storage],
        Implementations: [
          Nosedrum.Invoker.Split,
          Nosedrum.MessageCache.Agent,
          Nosedrum.MessageCache.ETS,
          Nosedrum.Storage.ETS
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [],
      extra_applications: [:nostrum]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, "~> 0.7"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.0", only: :dev, optional: true, runtime: false}
    ]
  end
end

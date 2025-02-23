defmodule Nosedrum.MixProject do
  use Mix.Project

  def project do
    [
      app: :nosedrum,
      version: "0.6.0",
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
      groups_for_docs: [
        Evaluation: &(&1[:section] == :evaluation),
        Predicates: &(&1[:section] == :predicates)
      ],
      groups_for_modules: [
        "Application Commands": [
          Nosedrum.ApplicationCommand,
          Nosedrum.Storage,
          Nosedrum.Storage.Dispatcher
        ],
        "Component Handler": [
          Nosedrum.ComponentHandler,
          Nosedrum.ComponentInteraction
        ],
        Functionality: [Nosedrum.Converters, Nosedrum.Helpers, Nosedrum.TextCommand.Predicates],
        Behaviours: [
          Nosedrum.TextCommand,
          Nosedrum.TextCommand.Invoker,
          Nosedrum.MessageCache,
          Nosedrum.TextCommand.Storage
        ],
        Implementations: [
          Nosedrum.TextCommand.Invoker.Split,
          Nosedrum.MessageCache.Agent,
          Nosedrum.MessageCache.ETS,
          Nosedrum.TextCommand.Storage.ETS,
          Nosedrum.ComponentHandler.ETS
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:nostrum]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, "~> 0.10.1"},
      # {:nostrum, "Kraigie/nostrum"},
      # {:nostrum, path: "../nostrum"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false}
    ]
  end
end

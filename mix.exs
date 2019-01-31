defmodule Nosedrum.MixProject do
  use Mix.Project

  def project do
    [
      app: :nosedrum,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, git: "https://github.com/Kraigie/nostrum.git"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end
end

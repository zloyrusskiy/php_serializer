defmodule PhpSerializer.Mixfile do
  use Mix.Project

  @source_url "https://github.com/zloyrusskiy/php_serializer"
  @version "2.0.0"

  def project do
    [
      app: :php_serializer,
      version: @version,
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs(),
      preferred_cli_env: [docs: :docs]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :docs, runtime: false}
    ]
  end

  defp package do
    [
      description: "PHP serialize/unserialize support for Elixir",
      maintainers: ["Alexander Fyodorov"],
      licenses: ["MIT"],
      links: %{"Github" => @source_url}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      # the git tagged version and library version is mismatch, "2.0" and
      # "2.0.0", default to master branch.
      source_ref: "master",
      formatters: ["html"],
      api_reference: false
    ]
  end
end

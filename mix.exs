defmodule PhpSerializer.Mixfile do
  use Mix.Project

  def project do
    [app: :php_serializer,
     version: "0.9.3",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/zloyrusskiy/php_serializer",
     description: description(),
     package: package(),
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:mix_test_watch, "~> 0.3", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    "PHP serialize/unserialize support for Elixir"
  end

  defp package do
    [maintainers: ["Alexander Fyodorov"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/zloyrusskiy/php_serializer"}]
  end
end

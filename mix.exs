defmodule Curtail.Mixfile do
  use Mix.Project

  def project do
    [app: :curtail,
     version: "0.1.0",
     elixir: "~> 1.0",
     description: description,
     package: package,
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end

  defp description do
    "HTML-safe string truncation."
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      contributors: ["Sean Kay"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/seankay/curtail"}
    ]
  end
end

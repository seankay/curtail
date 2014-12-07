defmodule Curtail.Mixfile do
  use Mix.Project

  @source_url "https://github.com/seankay/curtail"

  def project do
    [app: :curtail,
     version: "0.1.0",
     elixir: "~> 1.0",
     description: description,
     package: package,
     deps: deps,
     name: "Curtail",
     source_url:  @source_url
   ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.6", only: :dev}]
  end

  defp description do
    "HTML-safe string truncation."
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      contributors: ["Sean Kay"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end
end

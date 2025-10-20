defmodule Curtail.MixProject do
  use Mix.Project

  @source_url "https://github.com/seankay/curtail"

  def project do
    [
      app: :curtail,
      version: "3.0.0",
      elixir: ">= 1.16.1",
      description: description(),
      package: package(),
      deps: deps(),
      name: "Curtail",
      source_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:earmark, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "HTML-safe string truncation."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      contributors: ["Sean Kay"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end

defmodule PasswordlessAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :passwordless_auth,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:wx]],
      name: "PasswordlessAuth",
      source_url: "https://github.com/madebymany/passwordless_auth",
      docs: [
        main: "PasswordlessAuth",
        extras: ["README.md"]
      ],
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PasswordlessAuth, [:ex_twilio]},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_twilio, "~> 0.5.1"},
      {:mox, "~> 0.3", only: :test},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp description do
    "This library enables you to implement a simple passwordless login or 2-factor / multi-factor authentication. It can also be used as part of a user registration process."
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Sam Murray"],
      links: %{"GitHub" => "https://github.com/madebymany/passwordless_auth"}
    ]
  end
end

defmodule TaggedTupleShorthand.MixProject do
  use Mix.Project

  @version "VERSION" |> File.read!() |> String.trim()
  @erlang_version :otp_release |> :erlang.system_info() |> List.to_string() |> String.to_integer()

  @name "TaggedTupleShorthand"
  @description "Field punning for Elixir via a tagged 2-tuple variable reference macro"
  @authors ["Chris Keele"]
  @maintainers ["Chris Keele"]
  @licenses ["MIT"]
  @github_url "https://github.com/christhekeele/tagged_tuple_shorthand"
  @homepage_url @github_url
  @release_branch "release"
  @dev_envs [:dev, :test]

  def project do
    [
      app: :tagged_tuple_shorthand,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_options: [debug_info: Mix.env() in @dev_envs],
      # Informational
      name: @name,
      description: @description,
      source_url: @github_url,
      homepage_url: @homepage_url,
      # Configuration
      aliases: aliases(),
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      package: package()
    ]
  end

  def application, do: []

  def cli,
    do: [
      preferred_envs: [
        check: :test,
        lint: :test,
        "lint.compile": :test,
        "lint.deps": :test,
        "lint.format": :test,
        "lint.style": :test,
        test: :test,
        typecheck: :test,
        "typecheck.build-cache": :test,
        "typecheck.clean": :test,
        "typecheck.explain": :test,
        "typecheck.run": :test
      ]
    ]

  defp deps,
    do: [
      {:ex_doc, "~> 0.29", only: [:dev], runtime: false},
      {:makeup_diff, ">= 0.0.0", only: [:dev], runtime: false},
      {:credo, "~> 1.0", only: [:test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:test], runtime: false},
    ]

  defp aliases,
    do: [
      # High-level build tasks
      build: [
        "compile",
        "typecheck.build-cache"
      ],
      # Combination check utility
      check: [
        "test",
        "lint",
        "typecheck"
      ],
      # Combination clean utility
      clean: [
        "typecheck.clean"
      ],
      # Mix installation tasks
      install: [
        "install.rebar",
        "install.hex",
        "install.deps"
      ],
      "install.rebar": "local.rebar --force",
      "install.hex": "local.hex --force",
      "install.deps": "deps.get",
      # Linting tasks
      lint: [
        "lint.compile",
        "lint.deps",
        "lint.format",
        "lint.style"
      ],
      "lint.compile": "compile --force --warnings-as-errors",
      "lint.deps": "deps.unlock --check-unused",
      "lint.format": "format --check-formatted",
      "lint.style": "credo --strict",
      # Release tasks
      release: "hex.publish",
      # Typecheck tasks
      typecheck: [
        "typecheck.run"
      ],
      "typecheck.build-cache": "dialyzer --plt --format dialyxir",
      "typecheck.clean": "dialyzer.clean",
      "typecheck.explain": "dialyzer.explain --format dialyxir",
      "typecheck.run": "dialyzer --format dialyxir"
    ]

  defp docs,
    do: [
      # Metadata
      name: @name,
      authors: @authors,
      source_ref: @release_branch,
      source_url: @github_url,
      homepage_url: @homepage_url,
      main: "TaggedTupleShorthand",
      markdown_processor: {ExDoc.Markdown.Earmark, gfm_tables: true, sub_sup: true}
    ]

  defp dialyzer,
    do: [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      flags:
        ["-Wunmatched_returns", :error_handling, :underspecs] ++
          if @erlang_version < 25 do
            [:race_conditions]
          else
            []
          end,
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true,
      plt_add_apps: [],
      plt_ignore_apps: []
    ]

  defp package,
    do: [
      maintainers: @maintainers,
      licenses: @licenses,
      links: %{
        Home: @homepage_url,
        GitHub: @github_url
      },
      files: [
        "lib",
        "mix.exs",
        "LICENSE.md",
        "README.md",
        "VERSION"
      ]
    ]
end

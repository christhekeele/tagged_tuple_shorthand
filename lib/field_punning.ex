defmodule FieldPunning do
  @readme "README.md"
  @external_resource @readme
  @readme_blurb @readme
                |> File.read!()
                |> String.split("<!-- README BLURB -->")
                |> Enum.fetch!(1)
  @readme_setup @readme
                |> File.read!()
                |> String.split("<!-- README SETUP -->")
                |> Enum.fetch!(1)
  @readme_usage @readme
                |> File.read!()
                |> String.split("<!-- README USAGE -->")
                |> Enum.fetch!(1)
  @readme_impl @readme
               |> File.read!()
               |> String.split("<!-- README IMPL -->")
               |> Enum.fetch!(1)
  @readme_about @readme
                |> File.read!()
                |> String.split("<!-- README ABOUT -->")
                |> Enum.fetch!(1)

  @moduledoc """
  #{@readme_blurb}

  > #### `use FieldPunning` {: .info}
  >
  > When you `use FieldPunning`, you are replacing `Kernel.@/1` with:
  > - an overloaded `FieldPunning.@/1` implementation
  > - that supports `@:atom` and `@"string"` syntax sugar
  > - allowing for field punning in `Keyword`/`Map` literals
  > - and otherwise falls back to normal `@module_attribute` semantics

  ## Usage

  #{@readme_usage}

  ## Setup

  Field punning can be made to work with formatting and linting.

  > #### Using `FieldPunning.Formatter` {: .info}
  >
  > When you use the `FieldPunning.Formatter`:
  > - any key/value pair in `Keyword`/`Map` literals that can use `FieldPunning.@/1`, will be rewritten to
  > - any other use of `FieldPunning.@/1` will be un-written into a normal two-tuple
  > - any file left using `FieldPunning.@/1` will have `use FieldPunning` injected at the top

  #{@readme_setup}

  ## Background

  #{@readme_about}

  ## Notes

  #{@readme_impl}
  """

  @doc false
  defmacro __using__(_ \\ []) do
    quote do
      import Kernel, except: [@: 1]
      import FieldPunning, only: [@: 1]
    end
  end

  @doc """
  Generates tagged two-tuple variable references from atom and string literals.

  Falls back to `Kernel.@/1` for other inputs:

  Form               | Expands To
  -------------------|-----------
  `@:atom`           | `{:atom, atom}`
  `@"string"`        | `{"string", string}`
  `@anything_else`   | Fallback to `Kernel.@/1`

  ## Examples

      iex> use FieldPunning
      iex> foo = 1
      iex> @:foo
      {:foo, 1}
      iex> @:foo = {:foo, 2}
      {:foo, 2}
      iex> foo
      2

  Intended to be used in `Keyword` and `Map` literals to enable field punning,
  see the module documentation for an explanation of
  [field punning](https://field_punning.hexdocs.pm/FieldPunning.html#module-background)
  and its
  [intended usage](https://field_punning.hexdocs.pm/FieldPunning.html#module-usage).

  """
  defmacro @literal

  defmacro @atom when is_atom(atom) do
    {atom, Macro.var(atom, nil)}
  end

  defmacro @string when is_binary(string) do
    {string, Macro.var(String.to_atom(string), nil)}
  end

  defmacro @other do
    quote do
      Kernel.@(unquote(other))
    end
  end
end

defmodule TaggedTupleShorthand do
  @readme "README.md"
  @external_resource @readme
  @readme_blurb @readme
                |> File.read!()
                |> String.split("<!-- MODULEDOC BLURB -->")
                |> Enum.fetch!(1)
  @readme_extra @readme
                |> File.read!()
                |> String.split("<!-- MODULEDOC EXTRA -->")
                |> Enum.fetch!(1)
  @readme_usage @readme
                |> File.read!()
                |> String.split("<!-- MODULEDOC USAGE -->")
                |> Enum.fetch!(1)
  @readme_about @readme
                |> File.read!()
                |> String.split("<!-- MODULEDOC ABOUT -->")
                |> Enum.fetch!(1)

  @moduledoc """
  #{@readme_blurb}

  > #### `use TaggedTupleShorthand` {: .info}
  >
  > When you `use TaggedTupleShorthand`, you are replacing `Kernel.@/1` with:
  > - an overloaded `TaggedTupleShorthand.@/1` implementation
  > - that supports `@:atom` and `@"string"` tagged tuple variable references
  > - and otherwise falls back to normal `@module_attribute` semantics

  ## Field Punning

  #{@readme_about}

  ## Usage

  #{@readme_usage}

  ## Extras

  #{@readme_extra}
  """

  @doc false
  defmacro __using__(_ \\ []) do
    quote do
      import Kernel, except: [@: 1]
      import TaggedTupleShorthand, only: [@: 1]
    end
  end

  @doc """
  Generates tagged two-tuple variable references from atom and string literals.

  Otherwise falls back to `Kernel.@/1`:

  Form              | Expands To
  ------------------|-----------
  `@:atom`          | `{:atom, atom}`
  `@^:atom`         | `{:atom, ^atom}`
  `@"string"`       | `{"string", string}`
  `@^"string"`      | `{"string", ^string}`
  `@anything_else`  | Fallback to `Kernel.@/1`

  ## Examples

      iex> use TaggedTupleShorthand
      iex> foo = 1
      iex> @:foo
      {:foo, 1}
      iex> @:foo = {:foo, 2}
      {:foo, 2}
      iex> foo
      2
      iex> @^:foo = {:foo, 2}
      iex> @^:foo = {:foo, 3}
      ** (MatchError) no match of right hand side value: {:foo, 3}

  Intended to be used in pattern matching constructs to enable field punning,
  see the module documentation for an explanation of
  [field punning](https://hexdocs.pm/tagged_tuple_shorthand/TaggedTupleShorthand.html#module-field-punning)
  and its
  [intended usage](https://hexdocs.pm/tagged_tuple_shorthand/TaggedTupleShorthand.html#module-field-punning-usage).

  """
  defmacro @literal

  defmacro @atom when is_atom(atom) do
    {atom, Macro.var(atom, nil)}
  end

  defmacro @string when is_binary(string) do
    {string, Macro.var(String.to_existing_atom(string), nil)}
  end

  defmacro @{:^, meta, [atom]} when is_atom(atom) do
    {atom, {:^, meta, [Macro.var(atom, nil)]}}
  end

  defmacro @{:^, meta, [string]} when is_binary(string) do
    {string, {:^, meta, [Macro.var(String.to_existing_atom(string), nil)]}}
  end

  defmacro @other do
    quote do
      Kernel.@(unquote(other))
    end
  end
end

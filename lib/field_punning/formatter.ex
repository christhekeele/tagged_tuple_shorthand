defmodule FieldPunning.Formatter do
  @readme "README.md"
  @external_resource @readme

  @readme_formatter_instructions @readme
                                 |> File.read!()
                                 |> String.split("<!-- README FORMATTER INSTRUCTIONS -->")
                                 |> Enum.fetch!(1)
  @readme_formatter_options @readme
                            |> File.read!()
                            |> String.split("<!-- README FORMATTER OPTIONS -->")
                            |> Enum.fetch!(1)

  @moduledoc """
  #{@readme_formatter_instructions}
  """

  @default_line_length 98

  @behaviour Mix.Tasks.Format

  @impl Mix.Tasks.Format
  @doc """
  Registers the formatter to rewrite `.ex` and `exs` source files.
  """
  def features(_formatter_opts) do
    [extensions: [".ex", ".exs"]]
  end

  @impl Mix.Tasks.Format
  @doc """
  Formats `source` code to use `FieldPunning.@/1` syntax inside `Keyword`/`Map` literals.

  #### Options

  #{@readme_formatter_options}
  """

  def format(source, formatter_opts \\ []) do
    file = Keyword.get(formatter_opts, :file, "nofile")
    field_punning_opts = Keyword.get(formatter_opts, :field_punning, [])
    reorder_puns_in_maps? = Keyword.get(field_punning_opts, :reorder_puns_in_maps?, false)

    {quoted, comments} =
      source
      |> string_to_quoted(to_string(file))

    {rewritten,
     %{
       needs_rewrite?: needs_rewrite?,
       needs_use_field_punning?: needs_use_field_punning?
     }} =
      quoted
      |> Macro.prewalk(&strip_use_field_punning/1)
      |> Macro.prewalk(
        %{
          needs_rewrite?: false,
          needs_use_field_punning?: false,
          reorder_puns_in_maps?: reorder_puns_in_maps?
        },
        &rewrite_puns/2
      )

    result =
      if needs_rewrite? do
        if needs_use_field_punning? do
          add_use_field_punning(rewritten)
        else
          rewritten
        end
      else
        quoted
      end

    quoted_to_string(result, comments, formatter_opts)
  end

  @doc false
  # Wrap `Code.string_to_quoted_with_comments` with our desired options
  def string_to_quoted(source, file) when is_binary(source) do
    Code.string_to_quoted_with_comments!(source,
      literal_encoder: &{:ok, {:__block__, &2, [&1]}},
      token_metadata: true,
      unescape: false,
      file: file
    )
  end

  @doc "Turns an ast and comments back into code, formatting it along the way."
  def quoted_to_string(quoted, comments, formatter_opts \\ []) do
    opts = [{:comments, comments}, {:escape, false} | formatter_opts]
    line_length = Keyword.get(formatter_opts, :line_length, @default_line_length)

    quoted
    |> Code.quoted_to_algebra(opts)
    |> Inspect.Algebra.format(line_length)
    |> formatted_iodata_to_binary()
  end

  defp formatted_iodata_to_binary(formatted) do
    case formatted do
      [] -> ""
      _ -> IO.iodata_to_binary([formatted, ?\n])
    end
  end

  defp strip_use_field_punning({node, meta, args}) when is_list(args) do
    {node, meta,
     Enum.reject(args, fn
       {:use, _, [{:__aliases__, _, [:FieldPunning]}]} -> true
       _ -> false
     end)}
  end

  defp strip_use_field_punning(other) do
    other
  end

  defp add_use_field_punning({:__block__, meta, expressions}) do
    {:__block__, meta,
     [{:use, [context: Elixir], [{:__aliases__, [alias: false], [:FieldPunning]}]} | expressions]}
  end

  defp add_use_field_punning(expression) do
    {:__block__, [],
     [{:use, [context: Elixir], [{:__aliases__, [alias: false], [:FieldPunning]}]}, expression]}
  end

  defp rewrite_puns(map = {:%{}, meta, pairs}, acc) do
    if Enum.any?(pairs, &parse_pun/1) do
      rewritten =
        if acc.reorder_puns_in_maps? do
          {:%{}, meta, pairs |> reorder_puns |> Enum.map(&rewrite_valid_pun/1)}
        else
          {:%{}, meta, pairs |> Enum.map(&rewrite_valid_pun/1)}
        end

      {_, needs_use_field_punning?} =
        Macro.prewalk(rewritten, false, fn
          pun = {:@, _, [key | []]}, _ when is_atom(key) or is_binary(key) -> {pun, true}
          other, acc -> {other, acc}
        end)

      {rewritten, %{acc | needs_rewrite?: true, needs_use_field_punning?: needs_use_field_punning?}}
    else
      {map, acc}
    end
  end

  defp rewrite_puns(list, acc) when is_list(list) do
    if Enum.any?(list, &parse_pun/1) do
      rewritten = Enum.map(list, &rewrite_valid_pun/1)

      {_, needs_use_field_punning?} =
        Macro.prewalk(rewritten, false, fn
          pun = {:@, _, [key | []]}, _ when is_atom(key) or is_binary(key) -> {pun, true}
          other, acc -> {other, acc}
        end)

      {rewritten, %{acc | needs_rewrite?: true, needs_use_field_punning?: needs_use_field_punning?}}
    else
      {list, acc}
    end
  end

  defp rewrite_puns(field_pun = {:@, meta, [{:__block__, _, [key | []]}]}, acc)
       when is_atom(key) do
    if Keyword.get(meta, :valid_field_pun) do
      {field_pun, %{acc | needs_use_field_punning?: true}}
    else
      {{key, Macro.var(key, Elixir)}, %{acc | needs_rewrite?: true}}
    end
  end

  defp rewrite_puns(field_pun = {:@, meta, [{:__block__, _, [key | []]}]}, acc)
       when is_binary(key) do
    if Keyword.get(meta, :valid_field_pun) do
      {field_pun, %{acc | needs_use_field_punning?: true}}
    else
      {{key, Macro.var(String.to_atom(key), Elixir)}, %{acc | needs_rewrite?: true}}
    end
  end

  defp rewrite_puns(other, acc) do
    {other, acc}
  end

  defp parse_pun({:__block__, _, [{key, variable} | []]}) do
    parse_pun({key, variable})
  end

  defp parse_pun({{:__block__, _, [key | []]}, variable}) do
    parse_pun({key, variable})
  end

  defp parse_pun({key, {:__block__, _, [variable | []]}}) do
    parse_pun({key, variable})
  end

  defp parse_pun(pair = {atom_key, {variable_name, variable_meta, variable_context}})
       when is_atom(atom_key) and is_atom(variable_name) and is_list(variable_meta) and
              is_atom(variable_context) do
    if atom_key == variable_name do
      pair
    else
      nil
    end
  end

  defp parse_pun(pair = {string_key, {variable_name, variable_meta, variable_context}})
       when is_binary(string_key) and is_atom(variable_name) and is_list(variable_meta) and
              is_atom(variable_context) do
    if string_key == Atom.to_string(variable_name) do
      pair
    else
      nil
    end
  end

  defp parse_pun({:@, meta, [{:__block__, _, [literal | []]} | []]}) do
    parse_pun({:@, meta, [literal]})
  end

  defp parse_pun({:@, meta, [key | []]})
       when (is_list(meta) and is_atom(key)) or is_binary(key) do
    {:@, Keyword.put(meta, :valid_field_pun, true), [key]}
  end

  defp parse_pun(_) do
    nil
  end

  defp rewrite_valid_pun({:@, meta, [{:__block__, _, [key | []]} | []]})
       when is_list(meta) do
    rewrite_valid_pun({:@, meta, [key]})
  end

  defp rewrite_valid_pun({:@, meta, [key | []]})
       when (is_list(meta) and is_atom(key)) or is_binary(key) do
    {:@, Keyword.put(meta, :valid_field_pun, true), [key]}
  end

  defp rewrite_valid_pun(pair) do
    case parse_pun(pair) do
      {key, _variable} ->
        {:@, [valid_field_pun: true], [key]}

      _ ->
        pair
    end
  end

  defp reorder_puns(pairs) do
    {puns, not_puns} = Enum.split_with(pairs, &parse_pun/1)
    puns ++ not_puns
  end
end

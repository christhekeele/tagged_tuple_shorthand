# FieldPunning

<!-- README BLURB -->

> **_[Field punning](https://field_punning.hexdocs.pm/FieldPunning.html#module-background) syntax sugar for Elixir: shorthand key/value variable assignment and pattern matching._**

<!-- README BLURB -->

[![Version][hex-pm-version-badge]][hex-pm-versions]
[![Documentation][docs-badge]][docs]
[![License][hex-pm-license-badge]][hex-pm-package]
[![Dependencies][deps-badge]][deps]

## Setup

### Installation

`FieldPunning` is distributed via [hex.pm][hex-pm].

You can add it to your mix project's dependencies by modifying your `mix.exs`:

```elixir
def deps do
  [
    # ...
    {:field_punning, "~> 0.1", runtime: false},
    # ...
  ]
end
```

In scripting projects like in [`IEx`](https://iex.hexdocs.pm) or [`Livebook`s](https://livebook.hexdocs.pm), you can add it to your `Mix.install/2` invocations:

```elixir
Mix.install([
  # ...
  {:field_punning, "~> 0.1", runtime: false},
  # ...
])
```

<!-- README SETUP -->
<!--
  all hyperlinks within this snippet must be inline
-->

### Formatting

<!-- README FORMATTER INSTRUCTIONS -->
<!--
  all hyperlinks within this snippet must be inline
-->

`FieldPunning` comes with a formatter. To automatically re-write valid field puns within map/list literals to `FieldPunning.@/1` notation (and prevent abuse of the syntax elsewhere), add `FieldPunning.Formatter` to your list of formatter plugins:

```elixir
# .formatter.exs
[
  plugins: [
    FieldPunning.Formatter
  ],
  field_punning: [
    reorder_puns_in_maps?: false | true
  ]
]
```

<!-- README FORMATTER INSTRUCTIONS -->

#### Options

All options to this library are provided as keywords to the `:field_punning` key:

<!-- README FORMATTER OPTIONS -->

- `:reorder_puns_in_maps?`
  - `false` _(default)_:
    Do not place field puns first in maps. May cause a change to `=>` syntax in atom keys of existing maps, see the limitations below.
  - `true`:
    Automatically place field puns first in maps. May cause reordering of existing maps.

<!-- README FORMATTER OPTIONS -->

#### Limitations

These are the known limitations of the formatter, that stem from how it interacts with Elixir's default syntax sugar formatting rules. They are warts that would hopefully be fixed with actual language adoption.

1. **_Implicit trailing `Keyword` args list literals with puns are made explicit._**

   Normally, a trailing `Keyword` list in a function call can omit the list literal brackets:

   ```elixir
   fizzbuzz(foo: foo)
   ```

   Pun formatting rewrites this with an explicit list literal:

   ```elixir
   fizzbuzz([@:foo])
   ```

2. **_`Keyword` trailing-colon atom key/value pair syntax may shift to use tuples._**

   There is a syntax sugar for atom keys in `Keyword` pairs, such that they can leave the atom's colon on the right side to indicate pairing as shorthand for an `Atom` two-tuple:

   ```elixir
   [
     this: that,
     unity: unity,
     here: there,
   ]
   ```

   When a pun interrupts this flow, formatting forces the prior pairs back to two-tuple syntax:

   ```elixir
   [
     {:this, that},
     @:unity,
     here: there
   ]
   ```

3. **_`Map` trailing-colon atom key/value pair syntax may shift to use arrows._**

   Similar to the problem above with `Keyword` lists, `Map`s use an atom shorthand for key/value association:

   ```elixir
   %{
     this: that,
     unity: unity,
     here: there
   }
   ```

   When a pun interrupts this flow, earlier fields are rewritten to use the full `Map` association arrow syntax (`=>`):

   ```elixir
   %{
     :this => that,
     @:unity,
     here: there
   }
   ```

   To prevent this, the formatter provides an opt-in option to promote field puns earlier in the `Map`, since unlike a `Keyword`, they are not order-dependent.

   With these settings:

   ```elixir
   # .formatter.exs
   [
     field_punning: [
       reorder_puns_in_maps?: true
     ]
   ]
   ```

   The formatter will instead reorder the field puns first, preserving trailing-colon syntax sugar, producing:

   ```elixir
   %{
     @:unity,
     this: that,
     here: there
   }
   ```

### Linting

At time of writing, `Credo` is reasonably upset by how we re-appropriate the module attribute operator. We may offer a replacement check in the future, but for now you should disable the `Credo.Check.Readability.ModuleAttributeNames` check in your configuration, ex:

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: %{
        disabled: [
          {Credo.Check.Readability.ModuleAttributeNames, false}
        ]
      }
    }
  ]
}
```

<!-- README SETUP -->

## Usage

<!-- README USAGE -->
<!--
  all hyperlinks within this snippet must be inline
-->

`use FieldPunning` overrides the `@` operator to accept a literal atom or string. When used this way inside `Keyword`/`Map` literals, it acts as [a "field pun"](https://field_punning.hexdocs.pm/FieldPunning.html#module-background).

Field punning can be used to construct literal `Keyword`/`Map` pairs from variables in scope:

    iex> use FieldPunning
    iex> {foo, bar, baz} = {1, 2, nil}
    iex>
    iex> # Shorthand for:
    iex> # list = [:fizzbuzz, {"foo", foo}, bar: bar]
    iex> list = [:fizzbuzz, @"foo", @:bar]
    iex> list
    [:fizzbuzz, {"foo", 1}, {:bar, 2}]
    iex>
    iex> # Shorthand for:
    iex> # map = %{"foo" => foo, bar: bar, baz: baz}
    iex> map = %{@"foo", @:bar, @:baz}
    iex> map
    %{:bar => 2, :baz => nil, "foo" => 1}
    iex>
    iex> baz = 3
    iex> # Shorthand for:
    iex> # %{map | baz: baz}
    iex> %{map | @:baz}
    %{:bar => 2, :baz => 3, "foo" => 1}

Field punning works in pattern matching, assigning to a variable of the same name as the provided `Atom`/`String` key:

    iex> use FieldPunning
    iex> list = [{"foo", 1}, bar: 2]
    iex> map = %{"fizz" => 3, buzz: 4}
    iex>
    iex> # Shorthand for:
    iex> # [{"foo", foo}, bar: bar] = list
    iex> [@"foo", @:bar] = list
    iex> {foo, bar}
    {1, 2}
    iex>
    iex> # Shorthand for:
    iex> # %{"fizz" => fizz, buzz: buzz} = map
    iex> %{@"fizz", @:buzz} = map
    iex> {fizz, buzz}
    {3, 4}

This syntax works inside function heads, `case`s, and all other pattern matching constructs to concisely declare variables from named key/value pairs received as arguments:

    iex> use FieldPunning
    iex> map = %{"foo" => 1, bar: 2}
    iex>
    iex> # Shorthand for:
    iex> # destructure_map = fn %{"foo" => foo, bar: bar} ->
    iex> #   {foo, bar}
    iex> # end
    iex> destructure_map = fn %{@"foo", @:bar} ->
    ...>   {foo, bar}
    ...> end
    iex> destructure_map.(map)
    {1, 2}
    iex>
    iex> # Shorthand for:
    iex> # case map do
    iex> #   %{"foo" => foo, bar: bar} ->
    iex> #     {foo, bar}
    iex> # end
    iex> case map do
    ...>   %{@"foo", @:bar} -> {foo, bar}
    ...> end
    {1, 2}

Field punning is a syntax sugar that targets repetition to provide visual clarity and reduce typos. As such, it provides no sugar for other pattern matching constructs like the variable pinning (`^`) and ignore-unused-variables (`_`) syntaxes.

This keeps attention focused on these intentional expressions of programmer intent, only streamlining the cases where the programmer was compelled to provide a variable name without any additional semantics:

    iex> use FieldPunning
    iex> map = %{"foo" => 1, bar: 2, baz: 3}
    iex> bar = 2
    iex>
    iex> # Not eligible for field punning, to call attention
    iex> # to noteworthy semantic decisions:
    iex> case map do
    iex>   %{
    ...>     "foo" => something_foo, # Noteworthy: a more explanatory variable was chosen
    ...>     bar: ^bar, # Noteworthy: a variable match is being asserted
    ...>     baz: _baz, # Noteworthy: the value of baz is not useful in this context, just the key
    ...>   } ->
    ...>     {something_foo, bar}
    ...> end

### Real-World Examples

#### In Phoenix Channels

[Before](https://groups.google.com/g/elixir-lang-core/c/NoUo2gqQR3I/m/ddgTD3DU4oMJ):

```elixir
def handle_in(
      event,
      %{
        "chat" => chat,
        "question_id" => question_id,
        "data" => data,
        "attachment" => attachment
      },
      socket
    )
    when is_binary(chat) do...
```

After:

```elixir
def handle_in(event, %{@"chat", @"question_id", @"data", @"attachment"}, socket)
    when is_binary(chat) do...
```

Diff:

```diff
-def handle_in(
-      event,
-      %{
-        "chat" => chat,
-        "question_id" => question_id,
-        "data" => data,
-        "attachment" => attachment
-      },
-      socket
-    )
+def handle_in(event, %{@"chat", @"question_id", @"data", @"attachment"}, socket)
     when is_binary(chat) do...
```

The resulting version is much more concise and less error-prone to typos around parameter names.

#### In Phoenix Controller Actions

[Before](https://github.com/fly-apps/live_beats/blob/ac9780472e7019af274110a1cf71250a8d40c986/lib/live_beats_web/controllers/file_controller.ex#L11-L20):

```elixir
def show(conn, %{"id" => id, "token" => token}) do
  case Phoenix.Token.decrypt(conn, "file", token, max_age: :timer.minutes(1)) do
    {:ok, %{id: ^id, vsn: 1, size: _size}} ->
     path = MediaLibrary.local_filepath(id)
     do_send_file(conn, path)

    _ ->
      send_resp(conn, :unauthorized, "")
  end
end
```

After:

```elixir
def show(conn, %{@"id", @"token"}) do
  case Phoenix.Token.decrypt(conn, "file", token, max_age: :timer.minutes(1)) do
    {:ok, %{id: ^id, vsn: 1, size: _size}} ->
     path = MediaLibrary.local_filepath(id)
     do_send_file(conn, path)

    _ ->
      send_resp(conn, :unauthorized, "")
  end
end
```

Diff:

```diff
-def show(conn, %{"id" => id, "token" => token}) do
+def show(conn, %{@"id", @"token"}) do
   case Phoenix.Token.decrypt(conn, "file", token, max_age: :timer.minutes(1)) do
    {:ok, %{id: ^id, vsn: 1, size: _size}} ->
      path = MediaLibrary.local_filepath(id)
      do_send_file(conn, path)

    _ ->
      send_resp(conn, :unauthorized, "")
  end
end
```

Notice that in pattern matching on the return value of `Phoenix.Token.decrypt/4`, none of the fields are eligable for field punning. Only the normal, boring params destructuring is terser, and now demands less of our attention when parsing the semantics of this code, so we are more likely to notice the interesting decisions in the later pattern match.

<!-- README USAGE -->

## Implementation

<!-- README IMPL -->

When you `@:field_pun`, it turns into a tagged two-tuple variable reference at compile-time:

| Form             | Expands To                                                            |
| ---------------- | --------------------------------------------------------------------- |
| `@:atom`         | `{:atom, atom}`                                                       |
| `@"string"`      | `{"string", string}`                                                  |
| `@anything_else` | [Fallback to `Kernel.@/1`](https://elixir.hexdocs.pm/Kernel.html#@/1) |

Due to limitations in the implementation, this syntax can be used valid anywhere, though it probably shouldn't be:

#### Examples

    iex> use FieldPunning
    iex> foo = 1
    iex> @:foo
    {:foo, 1}
    iex> @:foo = {:foo, 2}
    {:foo, 2}
    iex> foo
    2

Is this synax useful? No. Should you do this? Absolutely not! Except inside literal lists and maps: then, it becomes very handy for destructuring!

In general, [using the `FieldPunning.Formatter`](https://field_punning.hexdocs.pm/FieldPunning.html#module-formatting) in your project will prevent against this sort of usage.

### Why the module attribute operator (`@`)?

Several reasons.

- It one of a few overridable unary macros in Elixir's syntax.
  - `+`, `-`, `!`, and `not` would be confusing for this macro to use.
  - `&` and `^` might work for this purpose, but they are special forms and cannot be overriden without compiler changes.
  - `...` is available, but has problematically low operator precedence.
  - `@` is in general the highest-precedence operator, eliminating many syntactical edge cases.
  - Most critically, `@` is the only unary operator today whose use with string/atom literals raises a compile-time error, ensuring that existing compiling programs are not using it this way already, and can adopt this library freely.
- The current purpose of `@` (to read and write module attributes) is somewhat sympathetic with field punning (both are compile-time conceits that interact with variables in scope to insert literals into code that reduce duplication).

<!-- README IMPL -->

## Background

<!-- README ABOUT -->
<!--
  all hyperlinks within this snippet must be inline
-->

What is field punning? It's a common form of syntactic sugar you may already be familiar with from other languages. It goes by many names:

- [Field Punning](https://dev.realworldocaml.org/records.html) — OCaml
- [Record Puns](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/record_puns.html) — Haskell
- [Object Property Value Shorthand](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Object_initializer#property_definitions) — ES6 Javascript
- [Hash Key Pattern Matching](https://docs.ruby-lang.org/en/3.0/syntax/pattern_matching_rdoc.html#label-Matching+non-primitive+objects-3A+deconstruct+and+deconstruct_keys) — Ruby

We'll stick with "field punning" throughout this explanation.

### Motivation

We often use `Keyword` lists and `Map`s to associate values with a given key:

```elixir
list = [foo: 1, bar: 2]
map = %{fizz: 3, buzz: 4}
```

Often, we want to get values of interest associated with a given key out of an associative data structure. There are functions as well as syntax sugar for this already:

```elixir
Keyword.get(list, :foo) #=> 1
list[:bar] #=> 2
map[:fizz] #=> 3
map.buzz #=> 4
```

If we're interested in a value, we are probably going to assign it to a variable. What's a good name for that variable? 94% of the time[‡](https://en.wikipedia.org/wiki/Citation_needed), the key name itself makes for a fine variable name:

```elixir
foo = Keyword.get(list, :foo)
bar = list[:bar]
fizz = map[:fizz]
buzz = map.buzz
```

And thanks to the glory of pattern matching, we can express this with destructuring:

```elixir
[foo: foo, bar: bar] = list
%{fizz: fizz, buzz: buzz} = map
foo #=> 1
bar #=> 2
fizz #=> 3
buzz #=> 4
```

This begs the question: if this is so common, **_why do we have to type out the same name twice_**, _once to name the key, and again to name the variable_, when destructuring?

Syntax sugar to reduce the duplication is called "field punning".

#### In Javascript

You can do this destructuring of key/value pairs into matching variable names by assigning to a "barewords" style object literal:

```js
data = {foo: 1, bar: 2, baz: 3}
//=> {foo: 1, bar: 2, baz: 3}
{foo, bar} = data
foo //=> 1
bar //=> 2
```

Objects use strings as keys and colon/quote syntax interchangeably, and this syntax does not work in arrays, so barewords syntax is the perfect lowest common denomniator for this language.

#### In Ruby

You can do this destructuring of key/value pairs into matching variable names by pattern matching into a "keywords" style hash literal:

```rb
data = {foo: 1, bar: 2, baz: 3}
#=> {:foo=>1, :bar=>2, :baz=>3}
data => {foo:, bar:}
foo #=> 1
bar #=> 2
```

Hashes can use atoms or strings as keys and this syntax only supports atoms, but as atoms in Ruby are garbage collected atom keys are fairly ubiquitous for this purpose, making atom literals a good choice for this shorthand.

#### Benefits

That is what _field punning_ is: **_a short-hand syntactic sugar for deconstruction and construction of key/value pairs in associative data structures, interacting with variable names in the current scope_**. It is popular for several reasons:

- This syntax saves on visual noise, expressing destructuring key/value data tersely in the common case of the key making for a sufficient variable name.
- This syntax calls attention to the cases where we are intentionally _not_ re-using the key as a variable name, placing emphasis on a subtle decision a developer decided was important for readability or understanding.
- This syntax prevents common typos, and ensures that variable names match keys throughout refactors when that is the desired behaviour.

#### In Elixir

Any Elixir implementation of field punning has to work in several more scenarios than other languages, since:

- We have two different common key types:
  - `Atom`s
  - `String`s
- We have two different common associative data structures:
  - `Keyword` lists are just a syntax convention around normal lists, which don't have to be composed fully of key/value pairs
  - `Map` datastructures must be composed fully of key/value pairs
- We have two different syntaxes for key/value associativity:
  - `arbitrary => value` (maps only)
  - `{arbitrary, value}` (keywords only)
  - With `atom: value` syntax sugar supported for both (atom keys only)
- We have two different syntax contexts for interpreting data structure literals:
  - pattern matching
  - normal lexical scope
- We have an existing data structure literal (tuples) that would be one character away syntactically (`%`) from being a valid map if we implemented field punning with a "barewords" style.

The `FieldPunning.@/1` macro lets us thread the needle of these concerns with a decently terse syntax that supports all possible usecases.

<!-- README ABOUT -->

## Supported Versions

`FieldPunning` is tested against many combinations of Elixir and OTP, and this syntax only works from Elixir v1.17.0 and onwards. Check the latest [test matrix run][test-matrix] to see if it will work for your combination.

<!-- LINKS & IMAGES -->

<!-- Hex -->

[hex-pm]: https://hex.pm
[hex-pm-package]: https://hex.pm/packages/field_punning
[hex-pm-versions]: https://hex.pm/packages/field_punning/versions
[hex-pm-version-badge]: https://img.shields.io/hexpm/v/field_punning.svg?cacheSeconds=86400&style=flat-square
[hex-pm-downloads-badge]: https://img.shields.io/hexpm/dt/field_punning.svg?cacheSeconds=86400&style=flat-square
[hex-pm-license-badge]: https://img.shields.io/badge/license-MIT-7D26CD.svg?cacheSeconds=86400&style=flat-square

<!-- Docs -->

[docs]: https://field_punning.hexdocs.pm/index.html
[docs-badge]: https://img.shields.io/badge/documentation-online-purple?cacheSeconds=86400&style=flat-square

<!-- Deps -->

[deps]: https://hex.pm/packages/field_punning
[deps-badge]: https://img.shields.io/badge/dependencies-0-blue?cacheSeconds=86400&style=flat-square

# TaggedTupleShorthand

<!-- MODULEDOC BLURB -->

> **_Field punning in Elixir via a shorthand for constructing tagged two-tuple variable references._**

<!-- MODULEDOC BLURB -->

[![Version][hex-pm-version-badge]][hex-pm-versions]
[![Documentation][docs-badge]][docs]
[![License][hex-pm-license-badge]][hex-pm-package]
[![Dependencies][deps-badge]][deps]

## Setup

### Installation

`TaggedTupleShorthand` is distributed via [hex.pm][hex-pm], you can install it with your dependency manager of choice using the config provided on its [hex.pm package][hex-pm-package] listing.

<!-- MODULEDOC EXTRA -->
<!--
  all hyperlinks within this snippet must be inline,
  rather than using markdown link references
-->

### Formatting

At time of writing, this library does not do any custom formatting, but that will likely change. To get support for it on release, you can add `:tagged_tuple_shorthand` to your formatter options' `:import_deps` today, ex:

```elixir
# project/.formatter.exs
[
  import_deps: [:tagged_tuple_shorthand]
]
```

### Linting

At time of writing, `Credo` is reasonably upset by how we re-appropriate the module attribute operator. We may offer a replacement check in the future, but for now you should disable the `Credo.Check.Readability.ModuleAttributeNames` check in your configuration, ex:

```elixir
# project/.credo.exs
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

<!-- MODULEDOC EXTRA -->

## Usage

<!-- MODULEDOC USAGE -->
<!--
  all hyperlinks within this snippet must be inline,
  rather than using markdown link references
-->

### Basic Usage

`TaggedTupleShorthand` overrides the `@` operator to accept a literal atom or string, that turns into a tagged two-tuple variable reference at compile-time:

Form              | Expands To
------------------|-----------
`@:atom`          | `{:atom, atom}`
`@^:atom`         | `{:atom, ^atom}`
`@"string"`       | `{"string", string}`
`@^"string"`      | `{"string", ^string}`
`@anything_else`  | Fallback to `Kernel.@/1`

#### Examples

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

      
This is not the most useful construct, until we start to use it in destructuring.

### Field Punning Usage

As it so happens, this tagged two-tuple variable reference shorthand expands at compile-time to AST that gives us field punning. Just use `@:atom` and `@"string"` when destructuring:

    iex> use TaggedTupleShorthand
    iex> destructure_map = fn %{@:foo, @"bar"} ->
    ...>   {foo, bar}
    ...> end
    iex> map = %{"bar" => 2, foo: 1}
    iex> destructure_map.(map)
    {1, 2}

Some more realistic examples:

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
    {:ok, %{@^:id, vsn: 1, size: _size}} ->
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
-    {:ok, %{id: ^id, vsn: 1, size: _size}} ->
+    {:ok, %{@^:id, vsn: 1, size: _size}} ->
      path = MediaLibrary.local_filepath(id)
      do_send_file(conn, path)
```

<!-- MODULEDOC USAGE -->

## Motivation

<!-- MODULEDOC ABOUT -->
<!--
  all hyperlinks within this snippet must be inline,
  rather than using markdown link references
-->

What is field punning? It's a common form of syntactic sugar you may already be familiar with from other languages. It goes by many names:

- [Field Punning](https://dev.realworldocaml.org/records.html) — OCaml
- [Record Puns](https://ghc.gitlab.haskell.org/ghc/doc/users_guide/exts/record_puns.html) — Haskell
- [Object Property Value Shorthand](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Object_initializer#property_definitions) — ES6 Javascript
- [Hash Key Pattern Matching](https://docs.ruby-lang.org/en/3.0/syntax/pattern_matching_rdoc.html#label-Matching+non-primitive+objects-3A+deconstruct+and+deconstruct_keys) — Ruby

We'll stick with "field punning" throughout this explanation.

### Background

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

If we're interested in a value, we are probably going to assign it to a variable. What's a good name for that variable? 94% of the time[‡](https://en.wikipedia.org/wiki/Citation_needed), the key itself makes for a fine variable name:

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

This begs the question: if this is so common, ***why do we have to type out the same name twice***, *once to name the key, and again to name the variable*, when destructuring?

#### In Javascript

You can do this destructuring of key/value pairs into matching variable names by assigning to a "barewords" style object literal:

```js
data = {foo: 1, bar: 2, baz: 3}
//=> {foo: 1, bar: 2, baz: 3}
{foo, bar} = data
foo //=> 1
bar //=> 2
```

#### In Ruby

You can do this destructuring of key/value pairs into matching variable names by pattern matching into a "keywords" style hash literal:

```rb
data = {foo: 1, bar: 2, baz: 3}
#=> {:foo=>1, :bar=>2, :baz=>3}
data => {foo:, bar:}
foo #=> 1
bar #=> 2
```

#### Benefits

That is what *field punning* is: ***a short-hand syntactic sugar for deconstruction of key/value pairs in associative data structures, interacting with variable names in the current scope***. It is popular for several reasons:

- This syntax saves on visual noise, expressing destructuring key/value data tersely in the common case of the key making for a sufficient variable name.
- This syntax calls attention to the cases where we are intentionally *not* re-using the key as a variable name, placing emphasis on a subtle decision a developer decided was important for readability or understanding.
- This syntax prevents common typos, and ensures that variable names match keys throughout refactors when that is the desired behaviour.

#### In Elixir

An Elixir implementation of field punning has to work in several more scenarios than other languages, since:

- We have two different common associative data structures, `Keyword` lists and `Map`s
- We have two different common key types, `Atom`s and `String`s
- We have two different common syntaxes for key/value associativity, `arbitrary => value` (maps only) and `atom: value` (atom keys only)

This particular macro for tagged two-tuple variable references gets us just that.

<!-- MODULEDOC ABOUT -->

## Supported Versions

`TaggedTupleShorthand` is tested against many combinations of Elixir and OTP, and this syntax only works from Elixir v1.17.0 and onwards. Check the latest [test matrix run][test-matrix] to see if it will work for your combination.

<!-- LINKS & IMAGES -->

<!-- Hex -->

[hex-pm]: https://hex.pm
[hex-pm-package]: https://hex.pm/packages/tagged_tuple_shorthand
[hex-pm-versions]: https://hex.pm/packages/tagged_tuple_shorthand/versions
[hex-pm-version-badge]: https://img.shields.io/hexpm/v/tagged_tuple_shorthand.svg?cacheSeconds=86400&style=flat-square
[hex-pm-downloads-badge]: https://img.shields.io/hexpm/dt/tagged_tuple_shorthand.svg?cacheSeconds=86400&style=flat-square
[hex-pm-license-badge]: https://img.shields.io/badge/license-MIT-7D26CD.svg?cacheSeconds=86400&style=flat-square

<!-- Docs -->

[docs]: https://hexdocs.pm/tagged_tuple_shorthand/index.html
<!-- [docs-guides]: https://hexdocs.pm/tagged_tuple_shorthand/usage.html#content -->
[docs-badge]: https://img.shields.io/badge/documentation-online-purple?cacheSeconds=86400&style=flat-square

<!-- Deps -->

[deps]: https://hex.pm/packages/tagged_tuple_shorthand
[deps-badge]: https://img.shields.io/badge/dependencies-0-blue?cacheSeconds=86400&style=flat-square

<!-- Benchmarks -->

<!-- [benchmarks]: https://christhekeele.github.io/tagged_tuple_shorthand/bench -->
<!-- [benchmarks-badge]: https://img.shields.io/badge/benchmarks-online-2ab8b5?cacheSeconds=86400&style=flat-square -->

<!-- Contributors -->

<!-- [contributors]: https://hexdocs.pm/tagged_tuple_shorthand/contributors.html -->
<!-- [contributors-badge]: https://img.shields.io/badge/contributors-%F0%9F%92%9C-lightgrey -->

<!-- Status -->

[suite]: https://github.com/christhekeele/tagged_tuple_shorthand/actions?query=workflow%3A%22Test+Suite%22
<!-- [coverage]: https://coveralls.io/github/christhekeele/tagged_tuple_shorthand -->

<!-- Release Status -->

[release]: https://github.com/christhekeele/tagged_tuple_shorthand/tree/release
[release-suite]: https://github.com/christhekeele/tagged_tuple_shorthand/actions?query=workflow%3A%22Test+Suite%22+branch%3Arelease
[release-suite-badge]: https://img.shields.io/github/actions/workflow/status/christhekeele/tagged_tuple_shorthand/test-suite.yml?branch=release&cacheSeconds=86400&style=flat-square
<!-- [release-coverage]: https://coveralls.io/github/christhekeele/tagged_tuple_shorthand?branch=release -->
<!-- [release-coverage-badge]: https://img.shields.io/coverallsCoverage/github/christhekeele/tagged_tuple_shorthand?branch=release&cacheSeconds=86400&style=flat-square -->

<!-- Latest Status -->

[latest]: https://github.com/christhekeele/tagged_tuple_shorthand/tree/latest
[latest-suite]: https://github.com/christhekeele/tagged_tuple_shorthand/actions?query=workflow%3A%22Test+Suite%22+branch%3Alatest
[latest-suite-badge]: https://img.shields.io/github/actions/workflow/status/christhekeele/tagged_tuple_shorthand/test-suite.yml?branch=latest&cacheSeconds=86400&style=flat-square
<!-- [latest-coverage]: https://coveralls.io/github/christhekeele/tagged_tuple_shorthand?branch=latest -->
<!-- [latest-coverage-badge]: https://img.shields.io/coverallsCoverage/github/christhekeele/tagged_tuple_shorthand?branch=latest&cacheSeconds=86400&style=flat-square -->

<!-- Other -->

<!-- [changelog]: https://hexdocs.pm/tagged_tuple_shorthand/changelog.html -->
[test-matrix]: https://github.com/christhekeele/tagged_tuple_shorthand/actions/workflows/test-matrix.yml
<!-- [test-edge]: https://github.com/christhekeele/tagged_tuple_shorthand/actions/workflows/test-edge.yml -->
<!-- [contributing]: https://hexdocs.pm/tagged_tuple_shorthand/contributing.html -->

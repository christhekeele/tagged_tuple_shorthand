####
# invalid_use/input.exs
##

@:foo = {:foo, 1}
@"bar" = {"bar", 2}

{foo, bar} == {1, 2}

var = {@"foo", @:bar}
var == {{"foo", foo}, {:bar, bar}}

####
# README.md examples
##

use FieldPunning
{foo, bar, baz} = {1, 2, nil}

# Shorthand for:
# list = [:fizzbuzz, {"foo", foo}, bar: bar]
list = [:fizzbuzz, @"foo", @:bar]
list
[:fizzbuzz, {"foo", 1}, {:bar, 2}]

# Shorthand for:
# map = %{"foo" => foo, bar: bar, baz: baz}
map = %{@"foo", @:bar, @:baz}
map
%{:bar => 2, :baz => nil, "foo" => 1}

baz = 3
# Shorthand for:
# %{map | baz: baz}
%{map | @:baz}
%{:bar => 2, :baz => 3, "foo" => 1}

use FieldPunning
list = [{"foo", 1}, bar: 2]
map = %{"fizz" => 3, buzz: 4}

# Shorthand for:
# [{"foo", foo}, bar: bar] = list
[@"foo", @:bar] = list
{foo, bar}
{1, 2}

# Shorthand for:
# %{"fizz" => fizz, buzz: buzz} = map
%{@"fizz", @:buzz} = map
{fizz, buzz}
{3, 4}

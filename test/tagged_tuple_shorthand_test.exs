defmodule TaggedTupleShorthandTest do
  use ExUnit.Case
  doctest TaggedTupleShorthand
  use TaggedTupleShorthand

  test "basic usage" do
    {foo, bar, baz} = {1, 2, 3}

    assert @:foo == {:foo, 1}
    assert @:bar == {:bar, 2}
    assert @:baz == {:baz, 3}

    assert @"foo" == {"foo", 1}
    assert @"bar" == {"bar", 2}
    assert @"baz" == {"baz", 3}
  end

  test "basic list usage" do
    {foo, bar, baz} = {1, 2, 3}

    assert [@:foo, @"bar"] == [{:foo, 1}, {"bar", 2}]

    list = [@:foo, @"bar"]
    assert [@:baz | list] == [{:baz, 3}, {:foo, 1}, {"bar", 2}]

    list = [{:foo, 10}, {"bar", 20}]
    [@:foo, @"bar"] = list
    assert {foo, bar} == {10, 20}
  end

  test "basic map usage" do
    {foo, bar, baz} = {1, 2, 3}

    assert %{@:foo, @"bar"} == %{"bar" => 2, foo: 1}

    map = %{@:foo, @"bar", baz: nil}
    assert %{map | @:baz} == %{"bar" => 2, foo: 1, baz: 3}

    %{@:foo, @:bar, @:baz} = %{foo: 10, bar: 20, baz: 30}
    assert {foo, bar, baz} == {10, 20, 30}
  end

  test "pin operator usage" do
    foo = 1

    assert match?(@(^:foo), {:foo, 1})

    assert_raise MatchError, "no match of right hand side value: {:foo, 2}", fn ->
      @(^:foo) = {:foo, 2}
    end
  end

  test "function usage" do
    destructure_map = fn %{@:foo, @"bar"} ->
      {foo, bar}
    end

    {foo, bar} = {1, 2}
    assert destructure_map.(%{@:foo, @"bar"}) == {1, 2}
  end
end

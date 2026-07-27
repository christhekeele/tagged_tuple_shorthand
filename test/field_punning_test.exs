use FieldPunning

defmodule FieldPunningTest do
  use ExUnit.Case
  @subject FieldPunning
  doctest @subject

  describe "#{inspect(@subject)}.@/1" do
    test "basic (improper) usage" do
      @:foo = {:foo, 1}
      @"bar" = {"bar", 2}

      assert {foo, bar} == {1, 2}

      var = {@"foo", @:bar}
      assert var == {{"foo", foo}, {:bar, bar}}
    end

    test "list literals" do
      fizzbuzz = :fizzbuzz
      {foo, bar, baz} = {1, 2, 3}

      assert [fizzbuzz, @:foo, @"bar"] == [:fizzbuzz, {:foo, 1}, {"bar", 2}]

      keyword = [@:foo, @"bar"]
      assert [@:baz | keyword] == [{:baz, 3}, {:foo, 1}, {"bar", 2}]

      keyword = [{:foo, 10}, {"bar", 20}]
      [@:foo, @"bar"] = keyword
      assert {foo, bar} == {10, 20}
    end

    test "map literals" do
      {foo, bar, baz} = {1, 2, 3}

      assert %{@:foo, @"bar"} == %{"bar" => 2, foo: 1}

      map = %{@:foo, @"bar", baz: nil}
      assert %{map | @:baz} == %{"bar" => 2, foo: 1, baz: 3}

      %{@:foo, @:bar, @:baz} = %{foo: 10, bar: 20, baz: 30}
      assert {foo, bar, baz} == {10, 20, 30}
    end

    test "function usage" do
      destructure_map = fn %{@"foo", @:bar} ->
        {foo, bar}
      end

      destructure_keyword = fn [foo, @"bar", @:baz] ->
        {foo, bar, baz}
      end

      {foo, bar, baz} = {1, 2, 3}

      assert destructure_map.(%{@"foo", @:bar}) == {1, 2}
      assert destructure_keyword.([foo, @"bar", @:baz]) == {1, 2, 3}
    end
  end
end

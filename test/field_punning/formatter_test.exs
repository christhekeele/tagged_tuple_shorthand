defmodule FieldPunning.FormatterTest do
  use ExUnit.Case
  @subject FieldPunning.Formatter
  doctest @subject

  describe "#{inspect(@subject)}.format/1" do

    for path <- Path.wildcard("test/fixtures/real_world/*") do
      test "real world #{path}" do
        input = File.read!("#{unquote(path)}/input.exs")
        expected = File.read!("#{unquote(path)}/expected.exs")

        first_pass = @subject.format(input)
        second_pass = @subject.format(first_pass)

        assert first_pass == expected
        assert second_pass == expected
      end
    end

    @tag :focus
    test "simple path" do
      input = File.read!("test/fixtures/simple_path/input.exs")
      expected = File.read!("test/fixtures/simple_path/expected.exs")

      first_pass = @subject.format(input)
      second_pass = @subject.format(first_pass)

      assert first_pass == expected
      assert second_pass == expected
    end

    test "unwrites invalid field puns" do
      input = File.read!("test/fixtures/invalid_use/input.exs")
      expected = File.read!("test/fixtures/invalid_use/expected.exs")

      first_pass = @subject.format(input)
      second_pass = @subject.format(first_pass)

      assert first_pass == expected
      assert second_pass == expected
    end

    test "handles mixed invalid field puns" do
      input = File.read!("test/fixtures/mixed_use/input.exs")
      expected = File.read!("test/fixtures/mixed_use/expected.exs")

      first_pass = @subject.format(input)
      second_pass = @subject.format(first_pass)

      assert first_pass == expected
      assert second_pass == expected
    end

    test "moves any `use FieldPunning` to top of file" do
      input = File.read!("test/fixtures/deep_use_field_punning/input.exs")
      expected = File.read!("test/fixtures/deep_use_field_punning/expected.exs")

      first_pass = @subject.format(input)
      second_pass = @subject.format(first_pass)

      assert first_pass == expected
      assert second_pass == expected
    end
  end

  describe "#{inspect(@subject)}.format/2" do
    test "does not reorder maps when `reorder_puns_in_maps?: false`" do
      options = [field_punning: [reorder_puns_in_maps?: false]]
      input = File.read!("test/fixtures/reorder_puns_in_maps/input.exs")
      expected = File.read!("test/fixtures/reorder_puns_in_maps/expected_without_reorder.exs")

      first_pass = @subject.format(input, options)
      second_pass = @subject.format(first_pass, options)

      assert first_pass == expected
      assert second_pass == expected
    end

    test "does reorder maps when `reorder_puns_in_maps?: true`" do
      options = [field_punning: [reorder_puns_in_maps?: true]]
      input = File.read!("test/fixtures/reorder_puns_in_maps/input.exs")
      expected = File.read!("test/fixtures/reorder_puns_in_maps/expected_with_reorder.exs")

      first_pass = @subject.format(input, options)
      second_pass = @subject.format(first_pass, options)

      assert first_pass == expected
      assert second_pass == expected
    end
  end
end

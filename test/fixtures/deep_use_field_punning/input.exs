defmodule Foo do
  use FieldPunning

  def bar(baz) do
    use FieldPunning
    %{@:baz}
  end
end

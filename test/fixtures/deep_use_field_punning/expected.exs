use FieldPunning

defmodule Foo do
  def bar(baz) do
    %{@:baz}
  end
end

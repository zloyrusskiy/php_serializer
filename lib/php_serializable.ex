defmodule PhpSerializable do
  @moduledoc false

  defmodule Class do
    defstruct class: nil, data: nil
  end

  defmodule Object do
    defstruct class: nil, data: nil
  end
end

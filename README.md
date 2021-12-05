# PhpSerializer

[![Module Version](https://img.shields.io/hexpm/v/php_serializer.svg)](https://hex.pm/packages/php_serializer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/php_serializer/)
[![Total Download](https://img.shields.io/hexpm/dt/php_serializer.svg)](https://hex.pm/packages/php_serializer)
[![License](https://img.shields.io/hexpm/l/php_serializer.svg)](https://github.com/zloyrusskiy/php_serializer/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/zloyrusskiy/php_serializer.svg)](https://github.com/zloyrusskiy/php_serializer/commits/master)

PHP serialize/unserialize support for Elixir

## Installation

The package can be installed by adding `:php_serializer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:php_serializer, "~> 2.0"}
  ]
end
```

## Examples

*serialize/1*
```elixir
PhpSerializer.serialize(123)
# "i:123;"
PhpSerializer.serialize([1,2,3])
# "a:3:{i:0;i:1;i:1;i:2;i:2;i:3;}"
PhpSerializer.serialize([1, :some_atom, %{1=> "a", "b" => 2}])
# "a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}"
```

*unserialize/1*
By default mimics PHP behavior (ignoring excess part of input string)
```elixir
PhpSerializer.unserialize("i:0;i:34;")
# {:ok, 0}
```

```elixir
PhpSerializer.unserialize("a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}")
# {:ok, [{0, 1}, {1, "some_atom"}, {2, [{1, "a"}, {"b", 2}]}]}
```

### With options
```elixir
PhpSerializer.unserialize("a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}", array_to_map: true)
# {:ok, %{0 => 1, 1 => "some_atom", 2 => %{1 => "a", "b" => 2}}}
```

```elixir
PhpSerializer.unserialize("i:0;i:34;", with_excess: true)
# {:ok, 0, "i:34;"}
```

#### strict mode
```elixir
PhpSerializer.unserialize("i:0;")
# {:ok, 0}
```

```elixir
PhpSerializer.unserialize("i:0;i:34;", strict: true)
# {:error, "excess characters found"}
```

```elixir
PhpSerializer.unserialize("i:0;i:34;", strict: true, with_excess: true)
# {:error, "excess characters found", "i:34;"}
```

## Copyright and License

Copyright (c) 2017 Alexander Fyodorov <alexandr.v.fedorov@yandex.ru>

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.


# PhpSerializer

PHP serialize/unserialize support for Elixir

## Installation

The package can be installed by adding `php_serializer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:php_serializer, "~> 2.0"}]
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

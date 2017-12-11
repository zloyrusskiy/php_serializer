# PhpSerializer

PHP serialize/unserialize support for Elixir

## Installation

The package can be installed by adding `php_serializer` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:php_serializer, "~> 0.9.0"}]
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
```elixir
{ status, data } = PhpSerializer.unserialize("a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}")
# {:ok, [{0, 1}, {1, "some_atom"}, {2, [{1, "a"}, {"b", 2}]}]}
List.keyfind(data, 1, 0)
# {1, "some_atom"}
```

*unserialize/2* (with options)
```elixir
{ status, data } = PhpSerializer.unserialize("a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}", array_to_map: true)
# {:ok, %{0 => 1, 1 => "some_atom", 2 => %{1 => "a", "b" => 2}}}
```

bad input
```elixir
{ status, data } = PhpSerializer.unserialize("i:0;i:34;")
# {:error, "left extra characters: 'i:34;'"}

```

## Todo
* Improve error reporting


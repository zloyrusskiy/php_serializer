defmodule PhpSerializer do
  @doc ~S"""
    Serialize Elixir data

      iex> PhpSerializer.serialize(123)
      "i:123;"

      iex> PhpSerializer.serialize([1, :some_atom, %{1 => "a", "b" => 2}])
      "a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}"

      iex> PhpSerializer.serialize(%PhpSerializable.Class{class: "NameOfTheClass", data: "somedata"})
      "C:14:\"NameOfTheClass\":8:{somedata}"
  """
  @spec serialize(any) :: String.t()
  def serialize(nil), do: "N;"

  def serialize(true), do: "b:1;"

  def serialize(false), do: "b:0;"

  def serialize(%PhpSerializable.Class{class: class, data: data}) do
    ~s(C:#{byte_size(class)}:"#{class}":#{byte_size(data)}:{#{data}})
  end

  def serialize(%PhpSerializable.Object{class: class, data: data}) do
    ~s(O:#{byte_size(class)}:"#{class}":#{length(data)}:{#{serialize_object(data)}})
  end

  def serialize(val) when is_integer(val), do: "i:#{val};"

  def serialize(val) when is_float(val) do
    float_str = to_string(val) |> String.replace("e", "E+")
    "d:#{float_str};"
  end

  def serialize(val) when is_binary(val) do
    ~s(s:#{byte_size(val)}:"#{val}";)
  end

  def serialize(val) when is_atom(val), do: val |> to_string |> serialize()

  def serialize(val) when is_list(val), do: serialize_list(val, -1, [])

  def serialize(val) when is_tuple(val), do: val |> Tuple.to_list() |> serialize()

  def serialize(val) when is_map(val), do: serialize(Map.to_list(val))

  defp serialize_list([{key, val} | rest], last_index, rslt) do
    cond do
      is_integer(key) ->
        serialize_list(rest, key, [serialize(key) <> serialize(val) | rslt])

      is_binary(key) and Regex.match?(~r/^\d+$/, key) ->
        serialize_list(rest, String.to_integer(key), [
          serialize(String.to_integer(key)) <> serialize(val) | rslt
        ])

      true ->
        serialize_list(rest, last_index, [serialize(key) <> serialize(val) | rslt])
    end
  end

  defp serialize_list([val | rest], last_index, rslt) do
    serialize_list(rest, last_index + 1, [serialize(last_index + 1) <> serialize(val) | rslt])
  end

  defp serialize_list([], _, rslt) do
    inner = rslt |> Enum.reverse() |> Enum.join("")

    "a:#{length(rslt)}:{#{inner}}"
  end

  defp serialize_object(val) do
    case Regex.named_captures(~r/^a:\d+:\{(?<inner>.*)/, serialize(val)) do
      nil -> "#{val}"
      %{"inner" => x} -> "#{x}"
    end
  end

  @doc ~S"""
    Unserialize PHP data

      iex> PhpSerializer.unserialize("a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}")
      {:ok, [{0, 1}, {1, "some_atom"}, {2, [{1, "a"}, {"b", 2}]}]}

      iex> {:ok, data } = PhpSerializer.unserialize("a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}")
      iex> List.keyfind(data, 1, 0)
      {1, "some_atom"}

    converted to maps:

      iex> PhpSerializer.unserialize("a:3:{i:0;i:1;i:1;s:9:\"some_atom\";i:2;a:2:{i:1;s:1:\"a\";s:1:\"b\";i:2;}}", array_to_map: true)
      {:ok, %{0 => 1, 1 => "some_atom", 2 => %{1 => "a", "b" => 2}}}

    with excess data:

      iex> PhpSerializer.unserialize("i:0;i:34;")
      {:ok, 0}

      iex> PhpSerializer.unserialize("i:0;i:34;", with_excess: true)
      {:ok, 0, "i:34;"}

      iex> PhpSerializer.unserialize("i:0;i:34;", strict: true)
      {:error, "excess characters found"}

      iex> PhpSerializer.unserialize("i:0;i:34;", strict: true, with_excess: true)
      {:error, "excess characters found", "i:34;"}
  """
  @type error_msg() :: String.t()
  @type excess_data() :: String.t()
  @spec unserialize(String.t(), array_to_map: boolean(), strict: boolean(), with_excess: boolean()) ::
          {:ok, any()}
          | {:ok, any(), excess_data()}
          | {:error, error_msg(), excess_data()}
          | {:error, error_msg()}
  def unserialize(str, opts \\ []) do
    strict = Keyword.get(opts, :strict, false)
    with_excess = Keyword.get(opts, :with_excess, false)

    {rslt, rest} = unserialize_value(str, opts)

    case {strict, with_excess} do
      {false, false} ->
        {:ok, rslt}

      {false, true} ->
        {:ok, rslt, rest}

      {true, false} ->
        case {rslt, rest} do
          {rslt, ""} -> {:ok, rslt}
          {_rslt, _rest} -> {:error, "excess characters found"}
        end

      {true, true} ->
        case {rslt, rest} do
          {rslt, ""} -> {:ok, rslt, ""}
          {_rslt, rest} -> {:error, "excess characters found", rest}
        end
    end
  rescue
    e -> {:error, "can't unserialize that string, got exception: #{Exception.format(:error, e)}"}
  end

  defp unserialize_value("N;" <> rest, _opts), do: {nil, rest}

  defp unserialize_value("b:1;" <> rest, _opts), do: {true, rest}

  defp unserialize_value("b:0;" <> rest, _opts), do: {false, rest}

  defp unserialize_value("i:" <> rest, _opts) do
    {value, new_rest} = Integer.parse(rest)

    {value, remove_semicolon(new_rest)}
  end

  defp unserialize_value("d:" <> rest, _opts) do
    {value, new_rest} = Float.parse(rest)

    {value, remove_semicolon(new_rest)}
  end

  defp unserialize_value("s:" <> rest, _opts) do
    {len, new_rest} = Integer.parse(rest)
    <<":\"", value::binary-size(len), "\";", rslt_rest::binary>> = new_rest

    {value, rslt_rest}
  end

  defp unserialize_value("C:" <> rest, _opts) do
    {classname_len, rest2} = Integer.parse(rest)
    <<":\"", classname::binary-size(classname_len), "\":", rest3::binary>> = rest2
    {data_len, rest4} = Integer.parse(rest3)
    <<":{", data::binary-size(data_len), "}", rest5::binary>> = rest4
    {%PhpSerializable.Class{class: classname, data: data}, rest5}
  end

  defp unserialize_value("O:" <> rest, _opts) do
    {classname_len, rest2} = Integer.parse(rest)
    <<":\"", classname::binary-size(classname_len), "\":", rest3::binary>> = rest2
    val = unserialize_value("a:" <> rest3, [])
    {%PhpSerializable.Object{class: classname, data: val}, ""}
  end

  defp unserialize_value("a:" <> rest, opts) do
    {array_size, new_rest} = Integer.parse(rest)
    unserialize_array(new_rest, array_size, opts)
  end

  defp unserialize_value(value, _opts),
    do: raise("Don't know how to unserialize value: " <> value)

  defp unserialize_array(":{" <> rest, array_size, opts),
    do: unserialize_array(rest, array_size, [], opts)

  defp unserialize_array(array_part, _, _),
    do: raise("Don't know how to unserialize array part: " <> array_part)

  defp unserialize_array("}" <> rest, 0, acc, [array_to_map: true] = _opts),
    do: {Enum.reverse(acc) |> Enum.into(%{}), rest}

  defp unserialize_array("}" <> rest, 0, acc, _opts), do: {Enum.reverse(acc), rest}

  defp unserialize_array(rest, array_size, acc, opts) do
    {key, new_rest} = unserialize_value(rest, opts)
    {value, rslt_rest} = unserialize_value(new_rest, opts)

    unserialize_array(rslt_rest, array_size - 1, [{key, value} | acc], opts)
  end

  defp remove_semicolon(";" <> rest), do: rest
end

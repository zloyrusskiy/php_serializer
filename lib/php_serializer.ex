defmodule PhpSerializer do
  @moduledoc false

  def serialize(nil), do: "N;"

  def serialize(true), do: "b:1;"

  def serialize(false), do: "b:0;"

  def serialize(val) when is_integer(val), do: "i:#{val};"

  def serialize(val) when is_float(val) do
    float_str = to_string(val) |> String.replace("e", "E+")
    "d:#{float_str};"
  end

  def serialize(val) when is_binary(val) do
    ~s(s:#{byte_size(val)}:"#{val}";)
  end

  def serialize(val) when is_atom(val), do: val |> to_string |> serialize

  def serialize(val) when is_list(val), do: serialize_list(val, -1, [])

  def serialize(val) when is_tuple(val), do: val |> Tuple.to_list |> serialize

  def serialize(val) when is_map(val), do: serialize(Map.to_list(val))

  defp serialize_list([{key, val} | rest], last_index, rslt) do
    cond do
      is_integer(key) -> serialize_list(rest, key, [serialize(key) <> serialize(val) | rslt])
      is_binary(key) and Regex.match?(~r/^\d+$/, key) -> serialize_list(rest, String.to_integer(key), [serialize(String.to_integer(key)) <> serialize(val) | rslt])
      true -> serialize_list(rest, last_index, [serialize(key) <> serialize(val) | rslt])
    end
  end

  defp serialize_list([val | rest], last_index, rslt) do
    serialize_list(rest, last_index + 1, [serialize(last_index + 1) <> serialize(val) | rslt])
  end

  defp serialize_list([], _, rslt) do
    inner = rslt |> Enum.reverse |> Enum.join("")

    "a:#{length(rslt)}:{#{inner}}"
  end

  def unserialize(str, opts \\ []) do
    case unserialize_value(str, opts) do
      { rslt, "" } -> { :ok, rslt }
      { _rslt, rest } -> { :error, "left extra characters: '#{rest}'" }
    end
  end

  defp unserialize_value("N;" <> rest, _opts), do: { nil, rest }

  defp unserialize_value("b:1;" <> rest, _opts), do: { true, rest }

  defp unserialize_value("b:0;" <> rest, _opts), do: { false, rest }

  defp unserialize_value("i:" <> rest, _opts) do
    {value, new_rest} = Integer.parse(rest)

    { value, remove_semicolon(new_rest) }
  end

  defp unserialize_value("d:" <> rest, _opts) do
    {value, new_rest} = Float.parse(rest)

    { value, remove_semicolon(new_rest) }
  end

  defp unserialize_value("s:" <> rest, _opts) do
    {len, new_rest} = Integer.parse(rest)
    <<":\"", value::binary-size(len), "\";", rslt_rest::binary>> = new_rest

    { value, rslt_rest }
  end

  defp unserialize_value("C:" <> rest, _opts) do
    { classname_len, rest2 } = Integer.parse(rest)
    <<":\"", classname::binary-size(classname_len), "\":", rest3::binary>> = rest2
    { data_len, rest4 } = Integer.parse(rest3)
    <<":{", data::binary-size(data_len), "}", rest5::binary>> = rest4

    { %PhpSerializable{class: classname, data: data}, rest5 }
  end


  defp unserialize_value("a:" <> rest, opts) do
    { array_size, new_rest } = Integer.parse(rest)

    unserialize_array(new_rest, array_size, opts)
  end

  defp unserialize_array(":{" <> rest, array_size, opts), do: unserialize_array(rest, array_size, [], opts)

  defp unserialize_array("}" <> rest, 0, acc, [array_to_map: true] = _opts), do: { Enum.reverse(acc) |> Enum.into(%{}), rest }
  defp unserialize_array("}" <> rest, 0, acc, _opts), do: { Enum.reverse(acc), rest }

  defp unserialize_array(rest, array_size, acc, opts) do
    { key, new_rest } = unserialize_value(rest, opts)
    { value, rslt_rest } = unserialize_value(new_rest, opts)

    unserialize_array(rslt_rest, array_size - 1, [{key, value} | acc], opts)
  end

  defp remove_semicolon(";" <> rest), do: rest
end

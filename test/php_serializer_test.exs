defmodule PhpSerializerTest do
  use ExUnit.Case, async: true
  import PhpSerializer
  doctest PhpSerializer

  @tag method: "unserialize"

  test "unserialize null" do
    assert unserialize("N;") == { :ok, nil }
  end

  test "unserialize boolean true" do
    assert unserialize("b:1;") == { :ok, true }
  end

  test "unserialize boolean false" do
    assert unserialize("b:0;") == { :ok, false }
  end

  test "unserialize number" do
    assert unserialize("i:123;") == { :ok, 123 }
  end

  test "unserialize negative number" do
    assert unserialize("i:-321;") == { :ok, -321 }
  end

  test "unserialize float" do
    assert unserialize("d:1.5;") == { :ok, 1.5 }
  end

  test "unserialize negative float" do
    assert unserialize("d:-2.5;") == { :ok, -2.5 }
  end

  test "unserialize big float" do
    assert unserialize("d:2.1E+17;") == { :ok, 2.1e17 }
  end

  test "unserialize string" do
    assert unserialize(~S(s:6:"foobar";)) == { :ok, "foobar" }
  end

  test "unserialize unicode string" do
    assert unserialize(~S(s:7:"star☆";)) == { :ok, "star☆" }
  end

  test "unserialize string with double quote" do
    assert unserialize(~S(s:5:"star"";)) == { :ok, ~S(star") }
  end

  test "unserialize array" do
    assert unserialize("a:3:{i:0;i:4;i:1;i:5;i:2;i:6;}") == { :ok, [{0, 4}, {1, 5}, {2, 6}] }
  end

  test "unserialize array with custom order" do
    assert unserialize("a:3:{i:2;i:4;i:3;i:5;i:4;i:6;}") == { :ok, [{2, 4}, {3, 5}, {4, 6}] }
  end

  test "unserialize array with string keys" do
    assert unserialize(~S(a:3:{s:1:"a";i:4;s:1:"b";i:5;s:1:"c";i:6;})) == { :ok, [{"a", 4}, {"b", 5}, {"c", 6}] }
  end

  test "unserialize option array_to_map" do
    assert unserialize(~S(a:3:{s:1:"a";i:4;s:1:"b";i:5;s:1:"c";i:6;}), array_to_map: true) == { :ok, %{"a" => 4, "b" => 5, "c" => 6} }
  end

  test "unserialize can catch error when there are some excess data" do
    assert unserialize("N;i:0;") == { :error, "left extra characters: 'i:0;'" }
  end

  test "unserialize serializable object" do
    assert unserialize(~S(C:3:"obj":23:{s:15:"My private data";})) == { :ok, %PhpSerializable{ class: "obj", data: ~S(s:15:"My private data";)} }
  end

  test "unserialize serializable object with namespace" do
    assert unserialize(~S(C:19:"Namespace\Classname":8:{somedata})) == { :ok, %PhpSerializable{ class: "Namespace\\Classname", data: "somedata"} }
  end

  @tag method: "serialize"

  test "serialize null" do
    assert serialize(nil) == "N;"
  end

  test "serialize boolean true" do
    assert serialize(true) == "b:1;"
  end

  test "serialize boolean false" do
    assert serialize(false) == "b:0;"
  end

  test "serialize number" do
    assert serialize(123) == "i:123;"
  end

  test "serialize negative number" do
    assert serialize(-321) == "i:-321;"
  end

  test "serialize float" do
    assert serialize(1.5) == "d:1.5;"
  end

  test "serialize negative float" do
    assert serialize(-2.5) == "d:-2.5;"
  end

  test "serialize big float" do
    assert serialize(2.1e17) == "d:2.1E+17;"
  end

  test "serialize string" do
    assert serialize("foobar") == ~S(s:6:"foobar";)
  end

  test "serialize unicode string" do
    assert serialize("star☆") == ~S(s:7:"star☆";)
  end

  test "serialize string with double quote" do
    assert serialize(~S(star")) == ~S(s:5:"star"";)
  end

  test "serialize atom" do
    assert serialize(:test) == ~S(s:4:"test";)
  end

  test "serialize map" do
    assert serialize(%{ 1 => "a", "b" => 2}) == ~S(a:2:{i:1;s:1:"a";s:1:"b";i:2;})
  end

  test "serialize array of tuples" do
    assert serialize([{0, 4}, {1, 5}, {2, 6}]) == "a:3:{i:0;i:4;i:1;i:5;i:2;i:6;}"
  end

  test "serialize array with tuples with custom keys order" do
    assert serialize([4, {3, 5}, 6]) == ~S(a:3:{i:0;i:4;i:3;i:5;i:4;i:6;})
  end

  test "serialize array with tuples with mixed keys" do
    assert serialize([{"3", 4}, 5, 6]) == ~S(a:3:{i:3;i:4;i:4;i:5;i:5;i:6;})
  end

  test "serialize array of tuples with string keys" do
    assert serialize([{"a", 4}, {"b", 5}, {"c", 6}]) == ~S(a:3:{s:1:"a";i:4;s:1:"b";i:5;s:1:"c";i:6;})
  end

  test "serialize tuple" do
    assert serialize({4,5}) == ~S(a:2:{i:0;i:4;i:1;i:5;})
  end
end

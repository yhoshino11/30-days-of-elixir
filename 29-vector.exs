# Managing a list

defmodule Vector do
  @template :erlang.make_tuple(10, nil)

  require Record
  Record.defrecordp :vec, Vector, size: 0, children: {nil, @template}

  def new do
    vec()
  end

  def new(list) do
    from_list(list, new)
  end

  def new(count, val) do
    Enum.reduce 0..(count - 1), new, fn i, v ->
      Vector.put(v, i, val)
    end
  end

  def size(vec(size: size)) do
    size
  end

  def get(vec(children: children), index) do
    do_get(children, hash(index))
  end

  def put(v = vec(size: size, children: children), index, value) do
    children = do_put(children, hash(index), value)
    if index >= size do
      vec(size: index + 1, children: children)
    else
      v
    end
  end
  def put(nil, index, value), do: put(new, index, value)

  def reduce(v = vec(size: size), acc, fun) do
    Enum.reduce 0..(size - 1), acc, fn index, acc ->
      fun.(get(v, index), acc)
    end
  end

  def find(v = vec(size: size), value, index \\ 0) do
    cond do
      index         >= size  -> nil
      get(v, index) == value -> index
      true                   -> find(v, value, index + 1)
    end
  end

  def from_list(list, v), do: from_list(list, v, 0)
  def from_list([val | rest], v, index) do
    v = put(v, index, val)
    from_list(rest, v, index + 1)
  end
  def from_list([], v, _), do: v

  defp do_get(nil, _) do
    nil
  end

  defp do_get({val, _}, []) do
    val
  end

  defp do_get({_, children}, [pos | hash_rest]) do
    node = elem(children, pos)
    do_get(node, hash_rest)
  end

  defp do_put(_, [], value) do
    {value, @template}
  end

  defp do_put(nil, hash, value) do
    do_put({nil, @template}, hash, value)
  end

  defp do_put({val, children}, [pos | hash_rest], value) do
    tree = do_put(elem(children, pos), hash_rest, value)
    {val, put_elem(children, pos, tree)}
  end

  defp hash(index) do
    chars = index
      |> :erlang.phash2
      |> Integer.to_char_list
    for c <- chars, do: List.to_integer([c])
  end
end

defimpl Enumerable, for: Vector do
  def count(v) do
    {:ok, Vector.size(v)}
  end

  def reduce(v, acc, fun) do
    Vector.reduce(v, acc, fun)
  end

  def member?(v, val) do
    {:ok, Vector.index(v, val) != nil}
  end
end

ExUnit.start

defmodule VectorTest do
  use ExUnit.Case

  test 'stores a value at an index in a tree structure' do
    v = Vector.new
    v = Vector.put(v, 0, "tim")
    assert v == {Vector, 1, {nil, {
      nil, nil, nil, nil, nil, nil, nil, nil,
      {nil, {
        nil, nil, nil, nil, nil, nil, nil, nil,
        {nil, {
          nil, nil, nil, nil, nil, nil, nil,
          {nil, {
            nil, nil,
            {nil, {
              nil, nil, nil,
              {nil, {
                nil, nil, nil, nil, nil, nil, nil,
                {nil, {
                  nil, nil,
                  {nil, {
                    nil, nil, nil, nil, nil,
                    {"tim", {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil}},
                    nil, nil, nil, nil}},
                  nil, nil, nil, nil, nil, nil, nil}},
                nil, nil}},
              nil, nil, nil, nil, nil, nil}},
            nil, nil, nil, nil, nil, nil, nil}},
          nil, nil}},
        nil}},
      nil}}}
  end

  test 'size' do
    v = Vector.new
    v = Vector.put(v, 0, "tim")
    v = Vector.put(v, 1, "jen")
    assert Vector.size(v) == 2

    v = Vector.put(v, 9, "mac")
    assert Vector.size(v) == 10
  end

  test 'get' do
    v = Vector.new
    v = Vector.put(v, 0, "tim")
    v = Vector.put(v, 1, "jen")
    v = Vector.put(v, 2, "mac")
    assert Vector.get(v, 0) == "tim"
    assert Vector.get(v, 1) == "jen"
    assert Vector.get(v, 2) == "mac"
  end

  test 'get non-existent key' do
    v = Vector.new
    assert Vector.get(v, 10) == nil
  end

  test 'count' do
    v = Vector.new([1, 2, 3])
    assert tuple_size(v) == 3
  end

  test 'reduce' do
    v = Vector.new([1, 2, 3])
    sum = Vector.reduce(v, 0, &(&1 + &2))
    assert sum == 6
  end

  test 'find' do
    v = Vector.new([1, 2, 3])
    index = Vector.find(v, 3)
    assert index == 2
  end

  @size 100_000

  test 'creation speed' do
    {microsecs, _} = :timer.tc fn ->
      List.duplicate("foo", @size)
    end
    IO.puts "List creation took #{microsecs} microsecs"
    {microsecs, _} = :timer.tc fn ->
      Vector.new(@size, "foo")
    end
    IO.puts "Vector creation took #{microsecs} microsecs"
  end

  test 'iteration speed' do
    list = List.duplicate("foo", @size)
    {microsecs, _} = :timer.tc fn ->
      Enum.reduce list, 0, fn _, count -> count + 1 end
    end
    IO.puts "List traversal took #{microsecs} microsecs"
    vector = Vector.new(@size, "foo")
    {microsecs, _} = :timer.tc fn ->
      Vector.reduce vector, 0, fn _, count -> count + 1 end
    end
    IO.puts "Vector traversal took #{microsecs} microsecs"
  end

  test 'access speed' do
    list = List.duplicate("foo", @size)
    {microsecs, _} = :timer.tc fn ->
      assert Enum.at(list, @size - 1) == "foo"
    end
    IO.puts "List access took #{microsecs} microsecs"
    vector = Vector.new(@size, "foo")
    {microsecs, _} = :timer.tc fn ->
      assert Vector.get(vector, @size - 1) == "foo"
    end
    IO.puts "Vector access took #{microsecs} microsecs"
  end
end

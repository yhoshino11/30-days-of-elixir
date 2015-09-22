defmodule Vector do
  import Bitwise

  @bits 2
  @width 1 <<< @bits
  @mask @width - 1

  require Record
  Record.defrecordp :vec, Vector, size: 0, depth: 0, tree: []

  def new do
    vec()
  end

  def new(list) do
    depth = round(Float.ceil(length(Integer.to_char_list((length(list) - 1), 2)) / @bits))
    vec(size: length(list), depth: depth, tree: tree_from_list(list, depth))
  end

  def size(vec(size: size)) do
    size
  end

  def get(vec(depth: depth, tree: tree), index) do
    do_get(tree, key(index, depth))
  end

  def put(vec(size: size, depth: depth, tree: tree), index, value) do
    if index > size, do: raise "index too large"
    if index == size, do: size = index + 1
    if size > depth * @width do
      depth = depth + 1
      tree = [tree]
    end

    tree = do_put tree, key(index, depth), value
    vec(size: size, depth: depth, tree: tree)
  end

  def reduce(vec(size: size, depth: depth, tree: tree), acc, fun) do
    do_reduce tree, depth - 1, size, 0, acc, fun
  end

  defp do_reduce(node, depth, size, index, acc, fun) when depth > 0 and is_list(node) do
    Enum.reduce Enum.with_index(node), acc, fn {n, i}, acc ->
      do_reduce n, depth - 1, size, index + (i * @width), acc, fun
    end
  end
  defp do_reduce(node, _, size, index, acc, fun) when is_list(node) do
    Enum.reduce Enum.slice(node, 0..(size - index - 1)), acc, fun
  end
  defp do_reduce(_, _, _, _, acc, _), do: acc

  defp key(index, depth) when depth > 0, do: key(index, depth, [])
  defp key(index, depth, indeces) when depth > 0 do
    level = (depth - 1) * @bits
    indeces = indeces ++ [(index >>> level) &&& @mask]
    key(index, depth - 1, indeces)
  end
  defp key(_, _, indeces), do: indeces

  defp tree_from_list(list, depth) when depth > 1 do
    list
      |> Enum.chunk(@width, @width, List.duplicate(nil, @width))
      |> tree_from_list(depth - 1)
  end
  defp tree_from_list(list, _), do: list

  defp do_get(node, [idx | rest_key]) do
    node = Enum.at(node, idx)
    do_get(node, rest_key)
  end
  defp do_get(node, []), do: node

  defp do_put(tree, [idx | rest_key], value) do
    rest = do_put(Enum.at(tree, idx) || [], rest_key, value)
    if length(tree) <= idx do
      tree = tree ++ List.duplicate(nil, idx - length(tree) + 1)
    end
    List.replace_at tree, idx, rest
  end
  defp do_put(_, [], value), do: value
end

ExUnit.start

defmodule VectorTest do
  use ExUnit.Case

  test 'put' do
    v = Vector.new
    v = Vector.put(v, 0, "first")
    assert v == {Vector, 1, 1, ["first"]}

    v = Vector.put(v, 1, "second")
    assert v == {Vector, 2, 1, ["first", "second"]}

    v = Vector.put(v, 2, "third")
    assert v == {Vector, 3, 1, ["first", "second", "third"]}

    v = Vector.put(v, 3, "fourth")
    assert v == {Vector, 4, 1, ["first", "second", "third", "fourth"]}

    v = Vector.put(v, 4, "fifth")
    assert v == {Vector, 5, 2, [["first", "second", "third", "fourth"], ["fifth"]]}

    v = Vector.put(v, 2, "third changed")
    assert v == {Vector, 5, 2, [["first", "second", "third changed", "fourth"], ["fifth"]]}
  end

  test 'new' do
    v = Vector.new(List.duplicate(1, 5))
    assert v == {Vector, 5, 2, [[1, 1, 1, 1], [1, nil, nil, nil]]}

    v = Vector.new(List.duplicate(1, 64))
    assert v == {Vector, 64, 3, [
      [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]],
      [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]],
      [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]],
      [[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]]
    ]}
  end

  test 'reduce' do
    v = Vector.new([1, 2, 3, 4, 5, 6])
    sum = Vector.reduce(v, 0, &(&1 + &2))
    assert sum == 21
  end

  @size 100_000

  test 'creation speed' do
    {microsecs, _} = :timer.tc fn ->
      List.duplicate("foo", @size)
    end
    IO.puts "List creation took #{microsecs} microsecs"
    list = List.duplicate("foo", @size)
    {microsecs, _} = :timer.tc fn ->
      Vector.new(list)
    end
    IO.puts "Vector creation took #{microsecs} microsecs"
  end

  test "iteration speed" do
    list = List.duplicate("foo", @size)
    {microsecs, _} = :timer.tc fn ->
      Enum.reduce list, 0, fn _, count -> count + 1 end
    end
    IO.puts "List traversal took #{microsecs} microsecs"
    list = List.duplicate("foo", @size)
    vector = Vector.new(list)
    {microsecs, _} = :timer.tc fn ->
      Vector.reduce vector, 0, fn _, count -> count + 1 end
    end
    IO.puts "Vector traversal took #{microsecs} microsecs"
  end

  test "access speed" do
    list = List.duplicate("foo", @size)
    {microsecs, _} = :timer.tc fn ->
      assert Enum.at(list, @size-1) == "foo"
    end
    IO.puts "List access took #{microsecs} microsecs"
    list = List.duplicate("foo", @size)
    vector = Vector.new(list)
    {microsecs, _} = :timer.tc fn ->
      assert Vector.get(vector, @size-1) == "foo"
    end
    IO.puts "Vector access took #{microsecs} microsecs"
  end
end

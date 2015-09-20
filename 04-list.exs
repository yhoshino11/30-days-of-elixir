ExUnit.start

defmodule ListTest do
  use ExUnit.Case, async: true

  def sample do
    ["Tim", "Jen", "Mac", "Kai"]
  end

  test 'sigil' do
    assert sample == ~w(Tim Jen Mac Kai)
  end

  test 'head' do
    [head | _] = sample
    assert head == "Tim"
  end

  test 'tail' do
    [_ | tail] = sample
    assert tail == ~w(Jen Mac Kai)
  end

  test 'last item' do
    assert List.last(sample) == "Kai"
  end

  test 'delete item' do
    assert List.delete(sample, "Mac") == ~w(Tim Jen Kai)
    assert List.delete([1, 2, 2, 3], 2) == [1, 2, 3]
  end

  test 'List.fold' do
    list = [20, 10, 5, 2.5]
    sum = List.foldr list, 0, &(&1 + &2)
    assert sum == 37.5
  end

  test 'Enum.reduce' do
    list = [20, 10, 5, 2.5]
    sum = Enum.reduce list, 0, &(&1 + &2)
    assert sum == 37.5
  end

  test 'wrap' do
    assert List.wrap(sample) == sample
    assert List.wrap(1)      == [1]
    assert List.wrap([])     == []
    assert List.wrap(nil)    == []
  end

  test 'Enum.filter_map' do
    some = Enum.filter_map sample, &(String.first(&1) >= "M"), &(&1 <> " Morgan")
    assert some == ["Tim Morgan", "Mac Morgan"]
  end

  test 'list comprehension' do
    some = for n <- sample, String.first(n) < "M", do: n <> " Morgan"
    assert some == ["Jen Morgan", "Kai Morgan"]
  end

  test 'manual reverse speed' do
    {microsec, reversed} = :timer.tc fn ->
      Enum.reduce 1..1_000_000, [], fn (i, l) -> List.insert_at(l, 0, i) end
    end
    assert reversed == Enum.to_list(1_000_000..1)
    IO.puts "manual reverse took #{microsec} microsecs"
  end

  test 'speed of inserting at the end of a list' do
    {microsec, reversed} = :timer.tc fn ->
      Enum.reduce 1..10000, [], fn (i, l) -> List.insert_at(l, -1, i) end
    end
    assert reversed == Enum.to_list(1..10000)
    IO.puts "inserting at the end of a list tok #{microsec} microsecs"
  end

  test 'Enum.reverse speed' do
    {microsec, reversed} = :timer.tc fn ->
      Enum.reverse 1..1_000_000
    end
    assert reversed == Enum.to_list(1_000_000..1)
    IO.puts "Enum.reverse took #{microsec} microsecs"
  end
end

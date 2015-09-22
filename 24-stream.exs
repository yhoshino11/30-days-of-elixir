defmodule Fib do
  @moduledoc """
  Lazy Fibonacci Sequence
  """

  defmodule FibVal do
    defstruct val: 0, next: 1
  end

  @doc """
  iex> Fib.fib |> Stream.map(&(&1.val)) |> Enum.take(10)
  """
  def fib do
    Stream.iterate %FibVal{}, fn %FibVal{val: val, next: next} ->
      %FibVal{val: next, next: val + next}
    end
  end

  @doc """
  iex> Fib.fib2 |> Enum.take(10)
  """
  def fib2 do
    Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
  end
end

ExUnit.start

defmodule FibTest do
  use ExUnit.Case

  test 'fib' do
    fib = Fib.fib |> Stream.map(&(&1.val)) |> Enum.take(10)
    assert fib == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  end

  test 'fib2' do
    fib = Fib.fib2 |> Enum.take(10)
    assert fib == [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
  end
end

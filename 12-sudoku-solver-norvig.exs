defmodule SudokuSolver do
  @moduledoc """
  Solves 9x9 Sudoku puzzles, Peter Norvig style.

  http://norvig.com/sudoku.html
  """

  @size 9
  @rows 'ABCDEFGHI'
  @cols '123456789'

  import Enum

  defmodule Board do
    defstruct squares: nil, units: nil, peers: nil
  end

  def cross(list_a, list_b) do
    for a <- list_a, b <- list_b, do: [a] ++ [b]
  end

  @doc "Return all squares"
  def squares, do: cross(@rows, @cols)

  @doc "All squares divided by row, column, and box."
  def unit_list do
    (for c <- @cols, do: cross(@rows, [c])) ++
    (for r <- @rows, do: cross([r], @cols)) ++
    (for rs <- chunk(@rows, 3), cs <- chunk(@cols, 3), do: cross(rs, cs))
  end

  def units do
    ul = unit_list
    list = for s <- squares, do: {s, (for u <- ul, s in u, do: u)}
    Enum.into(list, HashDict.new)
  end

  def peers do
    squares = cross(@rows, @cols)
    u = units
    list = for s <- squares do
      all = u |> Dict.get(s) |> concat |> Enum.into(HashSet.new)
      me  = [s] |> Enum.into(HashSet.new)
      {s, HashSet.difference(all, me)}
    end
    Enum.into(list, HashDict.new)
  end

  def parse_grid(grid, board) do
    values = Enum.into((for s <- board.squares, do: {s, @cols}), HashDict.new)
    do_parse_grid(values, Dict.to_list(grid_values(grid)), board)
  end

  defp do_parse_grid(values, [{square, value} | rest], board) do
    values = do_parse_grid(values, rest, board)
    if value in ').' do
      values
    else
      assign(values, square, value, board)
    end
  end
  defp do_parse_grid(values, [], _), do: values

  def grid_values(grid) do
    chars = for c <- grid, c in @cols or c in '0.', do: c
    unless count(chars) == 81, do: raise('error')
    Enum.into(zip(squares, chars), HashDict.new)
  end

  def assign(values, s, d, board) do
    values = Dict.put(values, s, [d])
    p = Dict.to_list(Dict.get(board.peers, s))
    eliminate(values, p, [d], board)
  end

  def eliminate(values, squares, vals_to_remove, board) do
    reduce_if_truthy squares, values, fn square, values ->
      eliminate_vals_from_square(values, square, vals_to_remove, board)
    end
  end

  defp eliminate_vals_from_square(values, square, vals_to_remove, board) do
    vals = Dict.get(values, square)
    if Set.intersection(Enum.into(vals, HashSet.new), Enum.into(vals_to_remove, HashSet.new)) |> any? do
      vals = reduce vals_to_remove, vals, fn val, vals -> List.delete(vals, val) end
      if length(vals) == 0 do
        false
      else
        values = Dict.put(values, square, vals)
        values = if length(vals) == 1 do
          eliminate(values, Dict.to_list(Dict.get(board.peers, square)), vals, board)
        else
          values
        end
        eliminate_from_units(values, Dict.get(board.units, square), vals_to_remove, board)
      end
    else
      values
    end
  end

  defp eliminate_from_units(values, units, vals_to_remove, board) do
    reduce_if_truthy units, values, fn unit, values ->
      reduce_if_truthy vals_to_remove, values, fn val, values ->
        dplaces = for s <- unit, val in Dict.get(values, s), do: s
        case length(dplaces) do
          0 -> false
          1 -> assign(values, at(dplaces, 0), val, board)
          _ -> values
        end
      end
    end
  end

  defp reduce_if_truthy(coll, acc, fun) do
    reduce coll, acc, fn i, a ->
      a && fun.(i, a)
    end
  end

  def solve(grid) do
    board = %Board{squares: squares, units: units, peers: peers}
    grid
      |> parse_grid(board)
      |> search(board)
      |> flatten(board)
  end

  def flatten(values, board) do
    board.squares
      |> map(fn s -> Dict.get(values, s) end)
      |> concat
  end

  def search(false, _), do: false
  def search(values, board) do
    if all?(board.squares, fn s -> count(Dict.get(values, s)) == 1 end) do
      values
    else
      {square, _count} = map(board.squares, &({&1, count(Dict.get(values, &1))}))
                          |> filter(fn {_, c} -> c > 1 end)
                          |> sort(fn {_, c1}, {_, c2} -> c1 < c2 end)
                          |> List.first
      find_value Dict.get(values, square), fn d ->
        assign(values, square, d, board) |> search(board)
      end
    end
  end

  def display(grid) do
    chunk(grid, @size)
      |> map(fn row -> chunk(row, 1) |> join(" ") end)
      |> join("\n")
      |> IO.puts
  end
end

ExUnit.start

defmodule SudokuSolverTest do
  use ExUnit.Case

  import SudokuSolver

  def print(grid, solved) do
    IO.puts "puzzle-----------"
    display(grid)
    IO.puts "solved-----------"
    display(solved)
    IO.puts "\n"
  end

  test 'solve easy' do
    grid1 = '..3.2.6..9..3.5..1..18.64....81.29..7.......8..67.82....26.95..8..2.3..9..5.1.3..'
    solved = solve(grid1)
    assert solved == '483921657967345821251876493548132976729564138136798245372689514814253769695417382'
    print(grid1, solved)
  end

  test 'solve hard' do
    grid2 = '4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......'
    solved = solve(grid2)
    assert solved == '417369825632158947958724316825437169791586432346912758289643571573291684164875293'
    print(grid2, solved)
  end
end

Code.load_file("./10-sudoku-board.exs")

defmodule SudokuSolver do
  @moduledoc """
  Brute force solve a Sudoku puzzle.
  """

  import Enum

  def solve(board) do
    board
      |> solutions
      |> map(fn s -> apply_solution(board, s) end)
      |> find fn b -> SudokuBoard.solved?(b) end
  end

  def apply_solution(board, [first | rest]) do
    size = count(board)
    board = List.flatten(board)
    pos = find_index board, fn col -> col == nil end
    List.replace_at(board, pos, first)
      |> chunk(size)
      |> apply_solution(rest)
  end
  def apply_solution(board, []), do: board

  def solutions(board) do
    possibles(board) |> combinations
  end

  defp possibles([row | rest]) do
    possible = to_list(1..count(row)) -- row
    [possible | possibles(rest)]
  end
  defp possibles([]), do: []

  def combinations([list | rest]) do
    crest = combinations(rest)
    for p <- permutations(list), r <- crest do
      flat_map p, fn i -> [i | r] end
    end
  end
  def combinations([]), do: [[]]

  def permutations([]), do: [[]]
  def permutations(list) do
    for h <- list, t <- permutations(list -- [h]), do: [h | t]
  end
end

ExUnit.start

defmodule SudokuSolverTest do
  use ExUnit.Case

  import SudokuSolver

  test 'solves a small board' do
    board = [[1, nil, 3],
             [3, nil, 2],
             [nil, 3, nil]]
    assert solve(board) == [[1, 2, 3],
                            [3, 1, 2],
                            [2, 3, 1]]
  end

  test 'returns nil on unsolvable board' do
    board = [[1, nil, 3],
             [3, nil, 2],
             [nil, 2, nil]]
    assert solve(board) == nil
  end
end

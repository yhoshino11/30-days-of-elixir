defmodule Table do
  @moduledoc """
  http://rosettacode.org/wiki/Dining_philosophers
  """

  defmodule Philosopher do
    defstruct name: nil, ate: 0, thunk: 0
  end

  def simulate do
    forks = [:fork1, :fork2, :fork3, :fork4, :fork5]

    table = spawn_link(Table, :manage_resources, [forks])

    spawn(Dine, :dine, [%Philosopher{name: "Aristotle"}, table])
    spawn(Dine, :dine, [%Philosopher{name: "Kant"},      table])
    spawn(Dine, :dine, [%Philosopher{name: "Spinoza"},   table])
    spawn(Dine, :dine, [%Philosopher{name: "Marx"},      table])
    spawn(Dine, :dine, [%Philosopher{name: "Russell"},   table])

    receive do: (_ -> :ok)
  end

  def manage_resources(forks, waiting \\ []) do
    if length(waiting) > 0 do
      names = for {_, phil} <- waiting, do: phil.name
      IO.puts "#{length waiting} philosopher#{if length(waiting) == 1, do: '', else: 's'} waiting: #{Enum.join names, ", "}"
      if length(forks) >= 2 do
        [{pid, _} | waiting] = waiting
        [fork1, fork2 | forks] = forks
        send pid, {:eat, [fork1, fork2]}
      end
    end
    receive do
      {:sit_down, pid, phil} ->
        manage_resources(forks, [{pid, phil} | waiting])
      {:give_up_seat, free_forks, _} ->
        forks = free_forks ++ forks
        IO.puts "#{length forks} fork#{if length(forks) == 1, do: '', else: 's'} available"
        manage_resources(forks, waiting)
    end
  end
end

defmodule Dine do
  def dine(phil, table) do
    send table, {:sit_down, self, phil}
    receive do
      {:eat, forks} ->
        phil = eat(phil, forks, table)
        phil = think(phil, table)
    end
    dine(phil, table)
  end

  def eat(phil, forks, table) do
    phil = %{phil | ate: phil.ate + 1}
    IO.puts "#{phil.name} is eating (count: #{phil.ate})"
    :timer.sleep(:random.uniform(1000))
    IO.puts "#{phil.name} is done eating"
    send table, {:give_up_seat, forks, phil}
    phil
  end

  def think(phil, _) do
    IO.puts "#{phil.name} is thinking (count: #{phil.thunk})"
    :timer.sleep(:random.uniform(1000))
    %{phil | thunk: phil.thunk + 1}
  end
end

:random.seed(:os.system_time)
Table.simulate

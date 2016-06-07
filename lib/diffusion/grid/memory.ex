defmodule Diffusion.Grid.Memory do
  use GenServer
  alias Diffusion.Grid
  alias Diffusion.Grid.Cell
  
  # Interface

  def grid() do
    GenServer.call(__MODULE__, :grid, 15_000)
  end

  def update() do
    GenServer.cast(__MODULE__, :update)
  end
  
  # Initialization

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_initial_val) do
    {:ok, Grid.new_grid() |> Grid.seed_grid()}
  end

  
  # Callbacks

  defp grid_key(x, y), do: "#{x},#{y}"
  
  defp to_pure_map(g) do
    Enum.reduce(g, %{}, fn({[x, y], %Cell{a: a, b: b}}, acc) ->
      Map.put(acc, grid_key(x, y), %{a: a, b: b})
    end)
  end

  def handle_call(:grid, _from, g) do
    {:reply, g |> to_pure_map(), g}
  end

  def handle_cast(:update, g) do
    {:noreply, Grid.update_grid(g)}
  end

end

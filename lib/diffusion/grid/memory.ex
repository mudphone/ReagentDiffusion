defmodule Diffusion.Grid.Memory do
  use GenServer
  alias Diffusion.Grid
  alias Diffusion.Grid.Cell
  require Logger
  
  # Interface

  def grid() do
    GenServer.call(__MODULE__, :grid, 25_000)
  end

  def update() do
    GenServer.cast(__MODULE__, :update)
  end
  
  # Initialization

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_initial_val) do
    {:ok, %{grid: Grid.new_grid() |> Grid.seed_grid(), update_count: 0}}
  end

  
  # Callbacks

  defp grid_key(x, y), do: "#{x},#{y}"
  
  defp js_mappable(g) do
    Enum.reduce(g, %{}, fn({[x, y], %Cell{a: a, b: b}}, acc) ->
      Map.put(acc, grid_key(x, y), %{a: a, b: b})
    end)
  end

  def handle_call(:grid, _from, %{grid: g}=state) do
    {:reply, js_mappable(g), state}
  end

  def handle_cast(:update, %{grid: grid, update_count: count}=state) do
    Logger.debug "grid update: #{count}"
    ng = Grid.update_grid(grid, limit: 2_000, timeout: 5_000)
    {:noreply, %{state | grid: ng, update_count: count+1}}
  end

end

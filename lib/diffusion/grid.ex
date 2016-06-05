defmodule Diffusion.Grid do
  use GenServer
  alias Diffusion.Cell
  require Logger
  
  @grid_width 100
  @grid_height 100

  @dA 1.0
  @dB 0.5
  @feed_factor 0.055
  @kill_factor 0.062
  
  # Interface

  def grid() do
    GenServer.call(__MODULE__, :grid, 15_000)
  end

  def update() do
    GenServer.cast(__MODULE__, :update)
  end

  # Diffiusion

  defp grid_key(x, y), do: "#{x},#{y}"
  
  defp coords(start_w, end_w, start_h, end_h) do
    for x <- start_w..end_w, y <- start_h..end_h, do: [x, y]
  end
  defp coords(w, h) do
    coords(0, w-1, 0, h-1)
  end
  defp coords() do
    coords(@grid_width, @grid_height)
  end
  
  defp seed_grid(g) do
    seed_box = for x <- 45..54, y <- 45..54, do: [x, y]
    Enum.reduce(seed_box, g, fn([x, y], acc) ->
      Map.update!(acc, grid_key(x, y), &(Map.put(&1, :b, 1.0)))
    end)
  end

  # returns weighted sums of neighbors
  # v4 is at x,y
  #
  #   v0, v1, v2
  #   v3, v4, v5
  #   v6, v7, v8
  #
  defp laplace(g, x, y) do
    %Cell{a: v0_a, b: v0_b} = Map.fetch!(g, grid_key(x-1, y-1))
    %Cell{a: v1_a, b: v1_b} = Map.fetch!(g, grid_key(x,   y-1))
    %Cell{a: v2_a, b: v2_b} = Map.fetch!(g, grid_key(x+1, y-1))
    %Cell{a: v3_a, b: v3_b} = Map.fetch!(g, grid_key(x-1, y))
    %Cell{a: v4_a, b: v4_b} = Map.fetch!(g, grid_key(x,   y))
    %Cell{a: v5_a, b: v5_b} = Map.fetch!(g, grid_key(x+1, y))
    %Cell{a: v6_a, b: v6_b} = Map.fetch!(g, grid_key(x-1, y+1))
    %Cell{a: v7_a, b: v7_b} = Map.fetch!(g, grid_key(x,   y+1))
    %Cell{a: v8_a, b: v8_b} = Map.fetch!(g, grid_key(x+1, y+1))
    [%{a: v0_a * 0.05, b: v0_b * 0.05},
     %{a: v1_a * 0.2,  b: v1_b * 0.2},
     %{a: v2_a * 0.05, b: v2_b * 0.05},
     %{a: v3_a * 0.2,  b: v3_b * 0.2},
     %{a: v4_a * -1.0, b: v4_b * -1.0},
     %{a: v5_a * 0.2,  b: v5_b * 0.2},
     %{a: v6_a * 0.05, b: v6_b * 0.05},
     %{a: v7_a * 0.2,  b: v7_b * 0.2},
     %{a: v8_a * 0.05, b: v8_b * 0.05}]
     |> Enum.reduce(%{sum_a: 0.0, sum_b: 0.0}, fn(%{a: a, b: b}, acc) ->
      acc
      |> Map.update!(:sum_a, &(&1 + a))
      |> Map.update!(:sum_b, &(&1 + b))
    end)
  end
  
  defp update_cell(g, %Cell{a: a, b: b, x: x, y: y}=cell) do
    %{sum_a: laplace_a, sum_b: laplace_b} = laplace(g, x, y)
    abb = a * b * b
    new_a = a + (@dA * laplace_a) - abb + (@feed_factor * (1.0 - a))
    new_a = Enum.max([0.0, new_a])
    new_a = Enum.min([1.0, new_a])
    new_a = Float.floor(new_a, 5)
    new_b = b + (@dB * laplace_b) + abb - ((@kill_factor + @feed_factor) * b)
    new_b = Enum.max([0.0, new_b])
    new_b = Enum.min([1.0, new_b])
    new_b = Float.floor(new_b, 5)
    cell
    |> Map.put(:a, new_a)
    |> Map.put(:b, new_b)
  end
  
  defp update_grid(old_grid) do
    # don't update the edges (start at 1 and end at n-2)
    upd_coords = coords(1, @grid_width-2, 1, @grid_height-2)
    next_grid = Map.new(old_grid)
    Enum.reduce(upd_coords, next_grid, fn([x, y], acc) ->
      Map.update!(acc, grid_key(x, y), &update_cell(old_grid, &1))
    end)
  end

  
  # Initialization

  defp new_grid() do
    Enum.reduce(coords(), %{}, fn([x, y], acc) ->
      Map.put(acc, grid_key(x, y), struct(Cell, %{x: x, y: y}))
    end)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_initial_val) do
    {:ok, new_grid() |> seed_grid()}
  end

  
  # Callbacks

  defp to_pure_map(g) do
    Enum.reduce(g, %{}, fn({k, %Cell{a: a, b: b}}, acc) ->
      Map.put(acc, k, %{a: a, b: b})
    end)
  end

  def handle_cast(:update, g) do
    {:noreply, update_grid(g)}
  end

  def handle_call(:grid, _from, g) do
    {:reply, g |> to_pure_map(), g}
  end

end

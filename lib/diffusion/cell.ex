defmodule Diffusion.Cell do
  defstruct a: 1.0, b: 0.0, x: nil, y: nil

  @grid_width 100
  @grid_height 100

  @dA 1.0
  @dB 0.5
  @feed_factor 0.055
  @kill_factor 0.062

  # Update Cell

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
  
  defp update_cell(%Cell{a: a, b: b, x: x, y: y}=cell, g) do
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
   
  # OTP
  
  def start_link(coord, grid, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [coord, grid, query_ref, owner, limit])
  end

  def fetch(coord, grid, query_ref, owner, _limit) do
    cell = update_cell(Map.get(grid, coord), grid)
    send_results(cell, query_ref, owner)
  end

  defp send_results(cell, query_ref, owner) do
    results = [cell]
    send(owner, {:results, query_ref, results})
  end
end

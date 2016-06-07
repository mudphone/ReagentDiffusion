defmodule Diffusion.Grid do
  alias Diffusion.Grid.Cell

  @grid_width 60
  @grid_height 60
  
  def start_link(coord, grid, query_ref, owner) do
    Cell.start_link(coord, grid, query_ref, owner)
  end

  defp spawn_query(coord, grid) do
    query_ref = make_ref()
    opts = [coord, grid, query_ref, self()]

    {:ok, pid} = Supervisor.start_child(Diffusion.Grid.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    {:pid, monitor_ref, query_ref} 
  end

  defp await_results(children), do: await_result(children, [], :inifinity)
  
  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    receive do
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
    end
  end
  defp await_result([], acc, _), do: acc

  
  # Diffiusion
  
  defp coords(start_w, end_w, start_h, end_h) do
    for x <- start_w..end_w, y <- start_h..end_h, do: [x, y]
  end
  defp coords(w, h) do
    coords(0, w-1, 0, h-1)
  end
  defp coords() do
    coords(@grid_width, @grid_height)
  end
  
  def seed_grid(g) do
    seed_box = for x <- 5..8, y <- 5..8, do: [x, y]
    Enum.reduce(seed_box, g, fn(coord, acc) ->
      Map.update!(acc, coord, &(Map.put(&1, :b, 1.0)))
    end)
  end

  def new_grid() do
    Enum.reduce(coords(), %{}, fn([x, y]=k, acc) ->
      Map.put(acc, k, struct(Cell, %{x: x, y: y}))
    end)
  end

  
  # Update
  
  def update_grid(old_grid) do
    # don't update the edges (start at 1 and end at n-2)
    upd_coords = coords(1, @grid_width-2, 1, @grid_height-2)
    next_cells = upd_coords
    |> Enum.map(&spawn_query(&1, old_grid))
    |> await_results()

    next_grid = Map.new(old_grid)
    Enum.reduce(next_cells, next_grid, fn(%Cell{x: x, y: y}=cell, acc) ->
      Map.put(acc, [x, y], cell)
    end)
  end

end

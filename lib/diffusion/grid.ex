defmodule Diffusion.Grid do
  alias Diffusion.Grid.Cell

  @grid_width 100
  @grid_height 100
  
  def start_link(coord_chunk, grid, query_ref, owner) do
    Cell.start_link(coord_chunk, grid, query_ref, owner)
  end

  defp spawn_query(coord_chunk, grid) do
    query_ref = make_ref()
    opts = [coord_chunk, grid, query_ref, self()]

    {:ok, pid} = Supervisor.start_child(Diffusion.Grid.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, query_ref} 
  end

  defp await_results(children, opts) do
    timeout = opts[:timeout] || 5000 # milliseconds
    timer = Process.send_after(self(), :timedout, timeout)
    results = await_result(children, [], :infinity)
    cleanup(timer)
    results
  end
  
  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    receive do
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
      :timedout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)

    after
      timeout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    end
  end
  defp await_result([], acc, _), do: acc

  defp kill(pid, ref) do
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)
    receive do
      :timedout -> :ok

    after
      0 -> :ok
    end
  end
  
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
  
  def update_grid(old_grid, opts \\ []) do
    limit = opts[:limit] || 100
    
    # don't update the edges (start at 1 and end at n-2)
    upd_coords = coords(1, @grid_width-2, 1, @grid_height-2)
    next_cells = upd_coords
    |> Enum.chunk(limit)
    |> Enum.map(&spawn_query(&1, old_grid))
    |> await_results(opts)

    next_grid = Map.new(old_grid)
    Enum.reduce(next_cells, next_grid, fn(%Cell{x: x, y: y}=cell, acc) ->
      Map.put(acc, [x, y], cell)
    end)
  end

end

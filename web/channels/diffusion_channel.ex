defmodule Diffusion.DiffusionChannel do
  use Diffusion.Web, :channel
  alias Diffusion.Grid.Memory

  def join("diffusion:" <> diff_id, _params, socket) do
    :timer.send_interval(2_000, :ping)
    :timer.send_interval(50, :update)
    :timer.send_interval(1_000, :grid)

    s = socket
    |> assign(:diff_id, String.to_integer(diff_id))
    {:ok, s}
  end
  
  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    push socket, "ping", %{count: count}

    {:noreply, assign(socket, :count, count + 1)}
  end

  def handle_info(:grid, socket) do
    grid = Memory.grid()
    push socket, "grid", %{grid: grid}
    {:noreply, assign(socket, :grid, grid)}
  end
  
  def handle_info(:update, socket) do
    Memory.update()
    {:noreply, socket}
  end

end

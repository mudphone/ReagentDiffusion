defmodule Diffusion.DiffusionChannel do
  use Diffusion.Web, :channel
  alias Diffusion.Grid

  def join("diffusion:" <> diff_id, _params, socket) do
    :timer.send_interval(2_000, :ping)
    s = socket
    |> assign(:diff_id, String.to_integer(diff_id))
    |> assign(:grid, Grid.grid())
    {:ok, s}
  end

  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    grid = socket.assigns[:grid]
    
    push socket, "ping", %{count: count, grid: grid}

    {:noreply, assign(socket, :count, count + 1)}
  end

end

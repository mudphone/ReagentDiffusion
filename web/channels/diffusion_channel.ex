defmodule Diffusion.DiffusionChannel do
  use Diffusion.Web, :channel

  def join("diffusion:" <> diff_id, _params, socket) do
    :timer.send_interval(1_000, :ping)
    {:ok, assign(socket, :diff_id, String.to_integer(diff_id))}
  end

  def handle_info(:ping, socket) do
    count = socket.assigns[:count] || 1
    push socket, "ping", %{count: count}

    {:noreply, assign(socket, :count, count + 1)}
  end

end

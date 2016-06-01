defmodule Diffusion.Grid do
  use GenServer

  # Interface

  def grid() do
    GenServer.call(__MODULE__, :grid)
  end


  # Initialization

  defp new_grid() do
    %{"10,10" => %{a: 1, b: 0.5},
      "40,40" => %{a: 1, b: 0.5}}
  end

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_initial_val) do
    {:ok, new_grid()}
  end

  
  # Callbacks
  
  def handle_call(:grid, _from, g) do
    {:reply, g, g}
  end
end

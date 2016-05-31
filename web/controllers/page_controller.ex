defmodule Diffusion.PageController do
  use Diffusion.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end

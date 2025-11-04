defmodule GroupDealsWeb.PageController do
  use GroupDealsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

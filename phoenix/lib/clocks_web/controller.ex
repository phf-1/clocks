defmodule ClocksWeb.Controller do
  @moduledoc false

  use ClocksWeb, :controller

  def spa(conn, _params) do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, Application.app_dir(:clocks, "priv/static/index.html"))
  end
end

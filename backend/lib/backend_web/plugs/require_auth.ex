defmodule BackendWeb.Plugs.RequireAuth do
  @moduledoc false

  import Plug.Conn

  alias Backend.Accounts
  alias Backend.Auth.Token

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user_id} <- Token.verify(token),
         user <- Accounts.get_user!(user_id) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_status(401)
        |> Phoenix.Controller.json(%{error: "Not authenticated"})
        |> halt()
    end
  end
end

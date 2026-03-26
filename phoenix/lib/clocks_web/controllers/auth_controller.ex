defmodule ClocksWeb.AuthController do
  use ClocksWeb, :controller
  alias Clocks.{Accounts, Auth.Token}

  def signup(conn, params) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        token = Token.sign(user.id)
        conn |> put_status(201) |> json(%{token: token, user: %{email: user.email}})

      {:error, changeset} ->
        conn |> put_status(422) |> json(%{error: error_message(changeset)})
    end
  end

  def signin(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user} ->
        token = Token.sign(user.id)
        conn |> json(%{token: token, user: %{email: user.email}})

      {:error, _} ->
        conn |> put_status(401) |> json(%{error: "Invalid credentials"})
    end
  end

  def signout(conn, _params),
    do: conn |> send_resp(204, "")

  def me(conn, _params) do
    user = conn.assigns.current_user
    conn |> json(%{email: user.email})
  end

  defp error_message(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
    |> Enum.map_join("; ", fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
  end
end

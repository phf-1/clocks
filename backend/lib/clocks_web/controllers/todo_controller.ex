defmodule ClocksWeb.TodoController do
  use ClocksWeb, :controller
  alias Clocks.Todos

  def index(conn, _params) do
    todos = Todos.list_todos(conn.assigns.current_user.id)
    conn |> json(Enum.map(todos, &serialize/1))
  end

  def create(conn, params) do
    case Todos.create_todo(conn.assigns.current_user.id, params) do
      {:ok, todo} -> conn |> put_status(201) |> json(serialize(todo))
      {:error, _cs} -> conn |> put_status(422) |> json(%{error: "Validation failed"})
    end
  end

  def update(conn, %{"todo_id" => id} = params) do
    case Todos.update_todo(conn.assigns.current_user.id, id, params) do
      {:ok, todo} -> conn |> json(serialize(todo))
      {:error, :not_found} -> conn |> put_status(404) |> json(%{error: "Not found"})
      {:error, _} -> conn |> put_status(422) |> json(%{error: "Validation failed"})
    end
  end

  def delete(conn, %{"todo_id" => id}) do
    case Todos.delete_todo(conn.assigns.current_user.id, id) do
      {:ok, _} -> conn |> send_resp(204, "")
      {:error, :not_found} -> conn |> put_status(404) |> json(%{error: "Not found"})
    end
  end

  defp serialize(todo),
    do: %{
      id: todo.id,
      text: todo.text,
      completed: todo.completed,
      createdAt: todo.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601()
    }
end

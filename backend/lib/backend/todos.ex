defmodule Backend.Todos do
  @moduledoc false

  import Ecto.Query
  alias Backend.Repo
  alias Backend.Todos.Todo

  def list_todos(user_id) do
    Todo
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def create_todo(user_id, attrs) do
    %Todo{user_id: user_id}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  def update_todo(user_id, todo_id, attrs) do
    case Repo.get_by(Todo, id: todo_id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> todo |> Todo.changeset(attrs) |> Repo.update()
    end
  end

  def delete_todo(user_id, todo_id) do
    case Repo.get_by(Todo, id: todo_id, user_id: user_id) do
      nil -> {:error, :not_found}
      todo -> Repo.delete(todo)
    end
  end
end

defmodule Backend.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "todos" do
    field :text, :string
    field :completed, :boolean, default: false
    belongs_to :user, Backend.Accounts.User, type: :binary_id
    timestamps()
  end

  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:text, :completed])
    |> validate_required([:text])
    |> validate_length(:text, min: 1)
  end
end

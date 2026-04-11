defmodule Clocks.Todos.Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "todos" do
    field :text, :string
    field :completed, :boolean, default: false
    field :importance, :string, default: "medium"
    belongs_to :user, Clocks.Accounts.User, type: :binary_id
    timestamps()
  end

  def changeset(todo, attrs) do
    todo
    |> cast(attrs, [:text, :completed, :importance])
    |> validate_required([:text])
    |> validate_length(:text, min: 1)
    |> validate_inclusion(:importance, ["low", "medium", "high"])
  end
end

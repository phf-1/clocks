defmodule Backend.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    has_many :todos, Backend.Todos.Todo
    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs),
    do: put_change(cs, :hashed_password, Bcrypt.hash_pwd_salt(pw))

  defp put_pass_hash(cs), do: cs
end

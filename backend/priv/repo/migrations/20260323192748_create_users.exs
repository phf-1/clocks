defmodule Clocks.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      timestamps()
    end

    create unique_index(:users, [:email])
  end
end

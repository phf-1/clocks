defmodule Clocks.Repo.Migrations.CreateTodos do
  use Ecto.Migration

  def change do
    create table(:todos, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :text, :string, null: false
      add :completed, :boolean, null: false, default: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:todos, [:user_id])
  end
end

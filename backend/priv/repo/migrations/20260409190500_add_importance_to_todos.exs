defmodule Clocks.Repo.Migrations.AddImportanceToTodos do
  use Ecto.Migration

  def change do
    alter table(:todos) do
      add :importance, :string, default: "medium", null: false
    end
  end
end

defmodule Clocks.Accounts do
  @moduledoc false

  alias Clocks.Accounts.User
  alias Clocks.Repo

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def authenticate(email, password) do
    user = get_user_by_email(email)

    cond do
      user && Bcrypt.verify_pass(password, user.hashed_password) ->
        {:ok, user}

      user ->
        {:error, :wrong_password}

      true ->
        Bcrypt.no_user_verify()
        {:error, :not_found}
    end
  end

  def get_user!(id), do: Repo.get!(Clocks.Accounts.User, id)
end

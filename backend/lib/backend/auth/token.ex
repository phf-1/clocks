defmodule Backend.Auth.Token do
  @moduledoc false

  @secret Application.compile_env(:backend, [__MODULE__, :secret], "dev-secret-change-in-prod")
  # 24 hours
  @ttl 86_400

  def sign(user_id) do
    claims = %{"sub" => user_id, "exp" => System.system_time(:second) + @ttl}

    JOSE.JWT.sign(JOSE.JWK.from_oct(@secret), %{"alg" => "HS256"}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  def verify(token) do
    jwk = JOSE.JWK.from_oct(@secret)

    case JOSE.JWT.verify(jwk, token) do
      {true, %JOSE.JWT{fields: %{"sub" => uid, "exp" => exp}}, _} ->
        if System.system_time(:second) < exp, do: {:ok, uid}, else: {:error, :expired}

      _ ->
        {:error, :invalid}
    end
  end
end

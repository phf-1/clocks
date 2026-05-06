defmodule Backend.Generic do
  @moduledoc """
  [[ref:0ce56d92-d628-4799-999e-d97ee613ad73][Spec]]
  """

  alias Backend.Generic.Base64
  alias Backend.Generic.Id
  alias Backend.Generic.Result

  @doc """
  [[ref:dd2e9e39-cbdd-4a01-879b-e2bfca328852][Spec]]
  """
  @spec path_to_sha256(Path.t()) :: {:ok, String.t()} | {:error, File.posix()}
  def path_to_sha256(path) when is_binary(path) do
    path
    |> File.stream!(2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), &:crypto.hash_update(&2, &1))
    |> :crypto.hash_final()
    |> then(&{:ok, &1})
  rescue
    e in File.Error -> {:error, e.reason}
  end

  @spec path_to_sha256!(Path.t()) :: String.t()
  def path_to_sha256!(path) do
    case path_to_sha256(path) do
      {:ok, hash} -> hash
      {:error, reason} -> raise File.Error, reason: reason, action: "stream", path: path
    end
  end

  def to_base64(bits) when is_bitstring(bits),
    do: Base.encode64(bits, padding: false) |> Base64.base64()

  def to_id(str) when is_binary(str) do
    case Base.decode64(str, padding: false) do
      {:ok, bits} -> Result.ok(Id.id(bits))
      :error -> Result.error(__ENV__.function, "An id has been built from str.", str: str)
    end
  end
end

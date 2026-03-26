defmodule Clocks.Generic.Base64 do
  @moduledoc """
  [[id:9231628b-c890-4a7f-aa04-92a8d62293be][Id]]
  """

  alias Clocks.Generic.Result

  # Constructor

  defstruct [:string]

  def base64(string) when is_binary(string) do
    case Base.decode64(string, padding: false) do
      {:ok, _bin} ->
        %__MODULE__{string: string} |> Result.ok()

      error ->
        invariant = "string is a base64 encoded string without padding"
        Result.error(__ENV__.function, invariant, string: string, error: error)
    end
  end

  def base64(bits, :bits) when is_bitstring(bits) do
    %__MODULE__{string: Base.encode64(bits, padding: false)}
  end

  # Eliminator

  def elim(func), do: fn %__MODULE__{string: string} -> func.(string) end

  # Interface

  def string(%__MODULE__{string: string}), do: string
  def bitstring(%__MODULE__{string: string}), do: Base.decode64!(string, padding: false)
end

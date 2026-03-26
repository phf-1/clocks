defmodule Clocks.Generic.Sha256 do
  @moduledoc """
  [[id:9231628b-c890-4a7f-aa04-92a8d62293be][Id]] implements TODO(f7bb)
  """

  alias Clocks.Generic.Base64

  # Constructor

  defstruct [:bits]

  def sha256(bits, :bits) when is_bitstring(bits) do
    %__MODULE__{bits: :crypto.hash(:sha256, bits)}
  end

  # Eliminator

  def elim(func), do: fn %__MODULE__{bits: bits} -> func.(bits) end

  # Interface

  def base64(%__MODULE__{bits: bits}), do: Base64.base64(bits, :bits)
  def string(%__MODULE__{} = sha256), do: base64(sha256) |> Base64.string()
  def bitstring(%__MODULE__{bits: bits}), do: bits
end

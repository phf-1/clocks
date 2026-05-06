defmodule Backend.Generic.Id do
  @moduledoc """
  [[id:2320cb24-3933-4b90-bcd4-4a62f91574a5][Id]] implements [[ref:6c22b7a9-40f5-4340-a966-bd099f7ebeae][Spec]].
  """

  alias Backend.Generic.Base64

  # Constructor

  defstruct [:bits]

  def id(bits) when is_bitstring(bits), do: %__MODULE__{bits: bits}
  def id(%Base64{} = base64), do: base64 |> Base64.bitstring() |> id()

  # Eliminator

  def elim(func), do: fn %__MODULE__{bits: bits} -> func.(bits) end

  # Interface

  def bitstring(%__MODULE__{bits: bits}), do: bits

  def string(%__MODULE__{bits: bits}) do
    bits
    |> Base64.base64(:bits)
    |> Base64.string()
  end

  # Protocol

  defimpl Inspect do
    def inspect(%@for{} = id, _opts) do
      "#Id<0x#{@for.string(id)}>"
    end
  end
end

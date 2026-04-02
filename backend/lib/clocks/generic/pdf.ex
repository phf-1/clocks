defmodule Clocks.Generic.Pdf do
  @moduledoc """
  [[id:42442de1-907e-48b6-8100-9fee11e1a2b3][Id]] implements [[ref:0975ffbf-0375-4760-ac27-2ab30b8d21a7][Spec]]
  """

  alias Clocks.Generic.Path
  alias Clocks.Generic.Result

  # Constructor

  defstruct [:bits]

  def pdf(bits) when is_bitstring(bits) do
    case bits do
      <<0x25, 0x50, 0x44, 0x46, 0x2D, _rest::binary>> ->
        Result.ok(%__MODULE__{bits: bits})

      _ ->
        Result.error(__ENV__.function, "not a PDF: magic bytes mismatch")
    end
  end

  def pdf(%Path{} = path) do
    case File.read(Path.string(path)) do
      {:ok, bits} ->
        pdf(bits)

      {:error, msg} ->
        Result.error(__ENV__.function, "path cannot be read.", path: path, msg: msg)
    end
  end

  # Eliminator

  def elim(func), do: fn %__MODULE__{bits: bits} -> func.(bits) end

  # Interface

  def bitstring(%__MODULE__{bits: bits}), do: bits

  # Protocol

  defimpl Inspect do
    def inspect(%@for{bits: bits}, _opts) do
      size = byte_size(bits)
      preview = Base.encode64(:binary.part(bits, 0, min(8, size)))
      "#Pdf<#{size} bytes, 0x#{preview}>"
    end
  end
end

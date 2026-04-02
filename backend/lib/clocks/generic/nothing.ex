defmodule Clocks.Generic.Nothing do
  @moduledoc """
  [[id:3c5e6972-ce16-43b8-8202-c8f9edcbfef8][Id]] implements TODO(ffbc)
  """

  # Constructor

  defstruct []

  def nothing, do: %__MODULE__{}

  # Eliminator

  def elim(x), do: fn %__MODULE__{} -> x end

  # Interface

  # Protocol

  defimpl Inspect do
    def inspect(%@for{}, _opts) do
      "#Nothing<>"
    end
  end
end

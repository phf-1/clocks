defmodule Backend.Generic.Path do
  @moduledoc """
  [[id:36d114fc-f3c2-442a-b935-6b91f1db4a45][Id]] implements TODO(409e)
  """

  alias Backend.Generic.Result

  # Constructor

  defstruct [:value]

  def path(value) when is_binary(value) do
    %__MODULE__{value: value} |> Result.ok()
  end

  # Eliminator

  def elim(func), do: fn %__MODULE__{value: value} -> func.(value) end

  # Interface

  def string(%__MODULE__{value: value}), do: value
end

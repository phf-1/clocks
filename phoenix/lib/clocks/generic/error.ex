defmodule Clocks.Generic.Error do
  @moduledoc """
  [[id:26cfd632-d285-44b6-89d3-ddb6f45f4e5d]] implements [[ref:e5e0f065-208e-406f-a655-fbdadc842263][Spec]].
      implements [[ref:42767f3e-de71-4a56-999a-5f00bc3b2722][Struct]]
  """

  require Logger

  defstruct [:name, :assertion, :params]

  # Constructor

  def error(atom_or_tuple, assertion, params \\ [])
      when (is_atom(atom_or_tuple) or is_tuple(atom_or_tuple)) and
             is_binary(assertion) and
             is_list(params) do
    %__MODULE__{name: atom_or_tuple, assertion: assertion, params: params}
  end

  # Eliminator

  def elim(func) when is_function(func, 3) do
    fn %__MODULE__{name: atom_or_tuple, assertion: assertion, params: params} ->
      func.(atom_or_tuple, assertion, params)
    end
  end

  # Interface

  def name(%__MODULE__{name: name}), do: name
  def assertion(%__MODULE__{assertion: assertion}), do: assertion
  def params(%__MODULE__{params: params}), do: params

  def string(%__MODULE__{name: name, assertion: assertion, params: params}) do
    "#{inspect(name)} | #{assertion} | #{inspect(params)}"
  end

  def log(error), do: string(error) |> Logger.error()

  # Protocol

  defimpl Inspect do
    def inspect(%@for{} = error, _opts) do
      "#Error<#{@for.string(error)}>"
    end
  end
end

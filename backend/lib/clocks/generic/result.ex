defmodule Clocks.Generic.Result do
  @moduledoc """
  [[id:f045754f-e6eb-4102-b2a1-251f209c3ac6][Id]] implements [[ref:5dd2a34c-6f34-4b56-b9a7-449fcc7ca453][Spec]]
      implements [[ref:42767f3e-de71-4a56-999a-5f00bc3b2722][Struct]]
  """

  defstruct [:ok, :error]

  alias Clocks.Generic.Error

  defp apply_if_ok(%__MODULE__{error: nil, ok: value}, if_ok), do: if_ok.(value)
  defp apply_if_ok(%__MODULE__{ok: nil} = result, _if_ok), do: result

  # Constructor

  def ok(value), do: %__MODULE__{ok: value}

  def error(caller, assertion, params \\ []) do
    %__MODULE__{error: Error.error(caller, assertion, params)}
  end

  # Eliminator

  def elim(if_ok, if_error)
      when is_function(if_ok, 1) and
             is_function(if_error, 1) do
    fn %__MODULE__{ok: value, error: error} ->
      case error do
        nil -> if_ok.(value)
        _ -> if_error.(error)
      end
    end
  end

  # Interface

  def value(%__MODULE__{ok: value}), do: value

  def pipe(init, funcs) when is_list(funcs) do
    Enum.reduce(funcs, ok(init), fn func, result -> apply_if_ok(result, func) end)
  end

  def pipe(init, funcs, if_error)
      when is_list(funcs) and
             is_function(if_error, 1) do
    result = pipe(init, funcs)
    elim(&Function.identity/1, if_error).(result)
  end

  # Protocol

  defimpl Inspect do
    def inspect(%@for{ok: ok, error: error}, _opts) do
      "#Result<ok: #{inspect(ok)}, error: #{inspect(error)}>"
    end
  end
end

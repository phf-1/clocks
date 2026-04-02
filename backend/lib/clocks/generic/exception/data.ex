defmodule Clocks.Exception.Data do
  @moduledoc "[[ref:9c09ee9c-8f9e-4dd6-858e-40d59e3a1119]]"

  # Context ————————————————————————————————————————————————————————————————————————————————————————

  use Clocks.Exception

  # Build ——————————————————————————————————————————————————————————————————————————————————————————

  def mk(data, invariant) when is_bitstring(data) and is_binary(invariant) do
    %__MODULE__{data: data, invariant: invariant}
  end

  # Use ————————————————————————————————————————————————————————————————————————————————————————————

  @impl true
  def message(%__MODULE__{data: data, invariant: invariant}) do
    "expected: #{invariant} | data: #{inspect(data, pretty: true, limit: 50, width: 50)}"
  end
end

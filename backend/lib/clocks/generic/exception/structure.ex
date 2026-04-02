defmodule Clocks.Exception.Structure do
  @moduledoc "[[ref:c981e10e-7ea7-4160-a3fc-fe1a8a2c129e]]"

  # Context ————————————————————————————————————————————————————————————————————————————————————————

  use Clocks.Exception

  # Build ——————————————————————————————————————————————————————————————————————————————————————————

  def mk(data, invariant) when is_atom(invariant) do
    %__MODULE__{data: data, invariant: invariant}
  end

  # Use ————————————————————————————————————————————————————————————————————————————————————————————

  @impl true
  def message(%__MODULE__{data: data, invariant: invariant}) do
    "expected: #{invariant} | data: #{inspect(data, pretty: true, limit: 150, width: 100)}"
  end
end

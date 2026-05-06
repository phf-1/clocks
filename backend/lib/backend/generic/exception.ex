defmodule Backend.Exception do
  @moduledoc "[[ref:19c529a5-7f0e-4d88-89e4-1883d921cce7]]"

  defmacro __using__(_opts) do
    quote do
      # Context ————————————————————————————————————————————————————————————————————————————————————————

      defexception [:data, :invariant]

      # Build ——————————————————————————————————————————————————————————————————————————————————————————

      # Use ————————————————————————————————————————————————————————————————————————————————————————————

      @impl true
      def exception(kws) do
        kws = Keyword.validate!(kws, [:data, :invariant])
        data = Keyword.get(kws, :data)
        invariant = Keyword.get(kws, :invariant)
        __MODULE__.mk(data, invariant)
      end
    end
  end
end

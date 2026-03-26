defmodule Clocks.Generic.ResultTest do
  @moduledoc """
  [[id:a1309a4d-bd6d-40f1-963b-56f139e88155][Id]] test [[ref:f045754f-e6eb-4102-b2a1-251f209c3ac6][Result]]
  """

  use ExUnit.Case, async: true

  alias Clocks.Generic.Error
  alias Clocks.Generic.Result

  describe "Result" do
    @desribetag id: "a1309a4d"

    test "build and use", _state do
      ok = Result.ok(42)
      assert 42 = Result.value(ok)
      assert 43 = Result.elim(&(&1 + 1), &Function.identity/1).(ok)

      err = Result.error(__ENV__.function, "This is true")
      assert %Error{} = Result.elim(&Function.identity/1, &Function.identity/1).(err)

      assert Result.ok(6) ==
               Result.pipe(
                 1,
                 [
                   fn x -> Result.ok(x + 1) end,
                   fn x -> Result.ok(x * 3) end
                 ]
               )

      result =
        Result.pipe(
          1,
          [
            fn _ -> Result.error(__ENV__.function, "This is true") end,
            fn _ -> flunk() end
          ]
        )

      assert Result.elim(fn _value -> false end, fn _error -> true end).(result)
    end
  end
end

defmodule Clocks.HealthControllerTest do
  @moduledoc """
  [[id:8e6f93c1-186f-42bf-8e0a-a799f32576a7]]
  """

  use ClocksWeb.ConnCase, async: true

  describe "GET /api/health" do
    @describetag id: "8e6f93c1"

    test "80fe", %{conn: conn} do
      conn = get(conn, ~p"/api/health")
      assert json_response(conn, 200) == %{"health" => "ok"}
    end
  end
end

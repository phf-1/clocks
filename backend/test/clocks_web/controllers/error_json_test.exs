defmodule ClocksWeb.ErrorJSONTest do
  use ClocksWeb.ConnCase, async: true

  # [[id:cd391604-848b-4375-ae67-f44fb98d09f9]]
  describe "unmatched api routes" do
    @describetag id: "cd391604"

    test "GET unknown path returns 404 json", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> get("/nonexistent")

      assert %{"errors" => %{"detail" => "Not Found"}} = json_response(conn, 404)
    end
  end
end

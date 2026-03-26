defmodule ClocksWeb.ErrorHTMLTest do
  use ClocksWeb.ConnCase, async: true

  # [[id:8fe06c76-e9d2-4102-b24c-503d86571a21]]
  describe "unmatched browser routes" do
    @describetag id: "8fe06c76"

    test "GET unknown path returns 404 plain text", %{conn: conn} do
      conn = get(conn, "/nonexistent")
      assert response(conn, 404) =~ "Not Found"
    end
  end
end

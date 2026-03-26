defmodule ClocksWeb.HealthController do
  use ClocksWeb, :controller

  def health(conn, _params) do
    # [[id:b0e91b87-105f-4512-bd80-0af6c41923ba][Id]]
    json(conn, %{health: "ok"})
  end
end

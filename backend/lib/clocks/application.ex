defmodule Clocks.Application do
  @moduledoc """
  [[id:b47fa002-6ace-46bd-8821-1fdd5838d939][Id]]
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ClocksWeb.Telemetry,
      Clocks.Repo,
      {DNSCluster, query: Application.get_env(:clocks, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Clocks.PubSub},
      {Finch, name: Clocks.Finch},

      # [[id:af9ca75f-9047-4e0a-a76a-d71a07af880a]]
      {Registry, keys: :unique, name: Clocks.Registry},

      # [[id:d229871a-95ee-4a49-8a40-44332fa8977d][Id]]
      ClocksWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Clocks.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClocksWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

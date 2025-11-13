defmodule GroupDeals.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GroupDealsWeb.Telemetry,
      GroupDeals.Repo,
      {DNSCluster, query: Application.get_env(:group_deals, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:group_deals, Oban)},
      {Phoenix.PubSub, name: GroupDeals.PubSub},
      {GroupDeals.Gap.HttpClient, []},
      # Start a worker by calling: GroupDeals.Worker.start_link(arg)
      # {GroupDeals.Worker, arg},
      # Start to serve requests, typically the last entry
      GroupDealsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GroupDeals.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GroupDealsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

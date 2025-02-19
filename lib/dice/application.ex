defmodule Dice.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DiceWeb.Telemetry,
      Dice.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:dice, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:dice, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Dice.PubSub},
      {Registry, keys: :unique, name: Dice.GameRegistry},
      {DynamicSupervisor, name: Dice.GameRoomSupervisor, strategy: :one_for_one},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Dice.Finch},
      # Start a worker by calling: Dice.Worker.start_link(arg)
      # {Dice.Worker, arg},
      # Start to serve requests, typically the last entry
      DiceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dice.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end

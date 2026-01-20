defmodule CatchTheCat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CatchTheCatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: CatchTheCat.PubSub},
      # Start the Endpoint (http/https)
      CatchTheCatWeb.Endpoint,
      # +++ ДОБАВЛЯЕМ GameServer С ЗАПЯТОЙ В КОНЦЕ ПРЕДЫДУЩЕЙ СТРОКИ +++
      CatchTheCat.GameServer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CatchTheCat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CatchTheCatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

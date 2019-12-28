defmodule Chirper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the endpoint when the application starts
      ChirperWeb.Endpoint,

      Chirper.Engine,
      Chirper.Simulator.Driver
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chirper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ChirperWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def run_simulation(args) do
    #IO.puts("Running Simulation")
    Chirper.Simulator.Driver.run(Enum.map(args, &String.to_integer(&1)))
    #require IEx; IEx.pry
    IO.puts("Done")
  end

  def run_bonus(args) do
    [users, peak_freq, _] = args
    args = [users,peak_freq]
    Chirper.Simulator.Driver.runWithZipf(Enum.map(args, &String.to_integer(&1)))
    IO.puts("Done")
  end
end

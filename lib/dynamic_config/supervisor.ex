defmodule DynamicConfig.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
        worker(DynamicConfig.Service, [])
    ]

    supervise(children, [strategy: :one_for_one])
  end

  def stop(pid) do
    Supervisor.stop(pid)
  end

end
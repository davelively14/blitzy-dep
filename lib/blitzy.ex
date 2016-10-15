defmodule Blitzy do

  #######
  # API #
  #######

  # Uses Task to asynchronosly spawn and execute a Blitzy Worker. Uses
  # Task.await/2 to block the process until all results are gathered. Passes
  # :infinity to await in order to avoid timeout issues. The HTTP client will
  # timeout if the server takes too long, which is why we can use :infinity.
  def run(n_workers, url) when n_workers > 0 do
    worker_fun = fn -> Blitzy.Worker.start(url) end

    1..n_workers
    |> Enum.map(fn _ -> Task.async(worker_fun) end)
    |> Enum.map(&Task.await(&1, :infinity))
  end

  # Starts Blitzy.Supervisor when the app starts.
  def start(_type, _args) do
    Blitzy.Supervisor.start_link(:ok)
  end
end

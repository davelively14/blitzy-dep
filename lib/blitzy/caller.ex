defmodule Blitzy.Caller do

  # Takes number of workers and the URL to load test against.
  def start(n_workers, url) do

    # Have to set self here, because we will spawn a function that needs to know
    # our pid. If we just used "self" inside that spanwed function, it would be
    # the pid of that process, not the Caller.
    me = self

    1..n_workers
    |> Enum.map(fn _ -> spawn(fn -> Blitzy.Worker.start(url, me) end) end)
    |> Enum.map(fn _ ->
        receive do
          x -> x
        end
      end)
  end
end

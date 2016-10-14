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

  #####################
  # Private Functions #
  #####################

  defp parse_results(results) do

    # Partitions enumerable into two lists, where the first one contains
    # elements for which fun returns a truthy value, and the second one – for
    # which fun returns false or nil. We ignore the list with false values.
    # TODO great way to do this
    {successes, _failures} =
      results
      |> Enum.partition(fn x ->
        case x do
          {:ok, _} -> true
          _ -> false
        end
      end)

    total_workers = Enum.count(results)
    total_success = Enum.count(successes)
    total_failure = total_workers - total_success

    # Creates a list of successful time values in ms
    data = successes |> Enum.map(fn {:ok, time} -> time end)

    average_time = average(data)
    longest_time = Enum.max(data)
    shortest_time = Enum.max(data)

    IO.puts """
    Total workers    : #{total_workers}
    Successful reqs  : #{total_success}
    Failed res       : #{total_failure}
    Average (msecs)  : #{average_time}
    Longest (msecs)  : #{longest_time}
    Shortest (msecs) : #{shortest_time}
    """
  end

  defp average(list) do
    sum = Enum.sum(list)
    if sum > 0 do
      sum / Enum.count(list)
    else
      0
    end
  end
end

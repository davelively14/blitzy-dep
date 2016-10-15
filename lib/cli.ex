use Mix.Config
defmodule Blitzy.CLI do
  require Logger

  def main(args) do

    # Application.get_env calls here will pull the :master_node and :slave_nodes
    # from the config/config.exs file and starts the nodes.

    Application.get_env(:blitzy, :master_node)
    |> Node.start

    Application.get_env(:blitzy, :slave_nodes)
    |> Enum.each(&Node.connect(&1))

    args
    |> parse_args
    |> process_options([node | Node.list])
  end

  # Thin wrapper for OptionParser.parse/2. Accepts a list of arguments and
  # returns the parsed values, the remaining args, and the invalid options in a
  # three element tuple of lists. {[parsed_values: result], [remaining_args],
  # [invalid_options]}.
  defp parse_args(args) do

    # Alias specifies a shorthand for :requests. So the user can use either -n
    # or --requests and this will take the next element in the args list as the
    # value. It will assign the value to the longhand version of the key, which
    # is :requests in this case.
    # Example:
    # ./blitzy -n 100 http://www.bieberfever.com
    # Results in: {[requests: 100], ["http://www.bieberfever.com"], []}
    OptionParser.parse(args, aliases: [n: :requests], strict: [requests: :integer])
  end

  defp process_options(options, nodes) do
    case options do

      # Only executes if n is an integer, there are more args than just the num
      # of requests, and there are no invalid arguments.
      {[requests: n], [url], []} ->
        do_requests(n, url, nodes)
      _ ->
        do_help
    end
  end

  defp do_requests(n_requests, url, nodes) do
    Logger.info "Pummeling #{url} with #{n_requests} requests"

    total_nodes = Enum.count(nodes)

    # Uses div/2 for integer division, which rounds down by default.
    req_per_node = div(n_requests, total_nodes)

    # Distributes workload across all nodes. Although, I don't think it does
    # what the author wants. Try having 4 nodes and like 22 requests. I think
    # only 20 requests would be processed. We don't deal with the remainder.
    # TODO figure out if this is an error
    nodes
    |> Enum.flat_map(fn node ->
        1..req_per_node |> Enum.map(fn _ ->
          # Starting from Task.Supervisor makes the task supervised. We pass a
          # tuple containing the supervisor module name and the node. async/4
          # takes a supervisor reference (tuple with supervisor module and
          # node), child module, function, and args. So basically, same thing as
          # Task.async/3, but we're telling the supervisor in the first arg to
          # start a worker remotely. This can be awaited on.
          Task.Supervisor.async({Blitzy.TasksSupervisor, node}, Blitzy.Worker, :start, [url])
        end)
      end)
    # Collects the results of all nodes from the master node.
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results
  end

  defp parse_results(results) do

    # Partitions enumerable into two lists, where the first one contains
    # elements for which fun returns a truthy value, and the second one – for
    # which fun returns false or nil. We ignore the list with false values.
    # TODO great way to do this
    {successes, _failures} =
      results
      |> Enum.partition(fn x ->
        case x do
          {_, {:ok, _}} -> true
          _ -> false
        end
      end)

    total_workers = Enum.count(results)
    total_success = Enum.count(successes)
    total_failure = total_workers - total_success

    # Creates a list of successful time values in ms
    data = successes |> Enum.map(fn {_, {:ok, time}} -> time end)

    IO.inspect "Data first: #{List.first(data)}"

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

  # Displays to user what this app expects as input
  defp do_help do
    IO.puts """
    Usage:
    blitzy -n [requests] [url]

    Options:
    -n, [--requests]

    Example:
    ./blitzy -n 100 http://www.bieberfever.com
    """
    System.halt(0)
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

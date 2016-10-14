use Mix.Config
defmodule Blitzy.CLI do
  require Logger

  def main(args) do

    # Application.get_env calls here will pull the :master_node and :slave_nodes
    # from the config/config.exs file and starts the nodes.

    Application.get_env(:blitzy, :master_node)
    |> Node.start

    Application.get_env(:blitzy, :slave_nodes)
    |> Node.start

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
    req_per_node = div(n_requests, total_nodes)

    nodes
    |> Enum.flat_map(fn node ->
        1..req_per_node |> Enum.map(fn _ ->
          Task.Supervisor.async({Blitzy.TaskSupervisor, node}, Blitzy.Worker, :start, [url])
        end)
      end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results
  end

  defp parse_results(_) do
    IO.puts "Parsing results"
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
end

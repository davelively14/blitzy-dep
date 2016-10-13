use Mix.Config
defmodule Blitzy.CLI do
  require Logger

  def main(args) do
    args
    |> parse_args
    |> process_options
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

  defp process_options(options) do
    case options do

      # Only executes if n is an integer, there are more args than just the num
      # of requests, and there are no invalid arguments.
      {[requests: n], [url], []} ->
        IO.puts "Something"
        # perform action
      _ ->
        do_help
    end
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

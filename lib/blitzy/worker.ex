defmodule Blitzy.Worker do
  use Timex
  require Logger

  # Users can supply an optional call to a different library. By default, we use
  # the HTTPoison library.
  def start(url, func \\ &HTTPoison.get/1) do
    IO.puts "Running on #node-#{node}"

    # Note that when using a function variable, you have to include the period
    # between the variable name and any arguments being passed: func.(url)
    {timestamp, response} = Duration.measure(fn -> func.(url) end)
    {self, handle_response({Duration.to_milliseconds(timestamp), response})}
  end

  #####################
  # Private Functions #
  #####################

  defp handle_response({msecs, {:ok, %HTTPoison.Response{status_code: code}}}) when code >= 200 and code <= 304 do
    Logger.info "worker [#{node}-#{inspect self}] completed in #{msecs} msecs"
    {:ok, msecs}
  end

  defp handle_response({_msecs, {:error, reason}}) do
    Logger.info "worker [#{node}-#{inspect self}] error due to #{inspect reason}"
    {:error, reason}
  end

  defp handle_response({_msecs, _}) do
    Logger.info "worker [#{node}-#{inspect self} errored out]"
    {:error, :unknown}
  end
end

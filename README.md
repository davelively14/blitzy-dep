# Blitzy

App from The Little Elixir & OTP Guidebook, chapter 8

Command line program (Blitzy.CLI)

#### Learned:

- The built-in functions Elixir and the Erlang VM provide for building distributed systems
- Implementing a distributed application that demonstrates load-balancing
- How to use Tasks for short-lived computations
- Implementing a command-line application

#### Changes:
- Had to alter numerous portions of this code vs what the book had, particularly in `Blitzy.CLI`:
```
Original:

{successes, _failures} =
  results
  |> Enum.partition(fn x ->
    case x do
      {:ok, _} -> true          <---------
      _ -> false
    end
  end)

Had to change:

{successes, _failures} =
  results
  |> Enum.partition(fn x ->
    case x do
      {_, {:ok, _}} -> true     <---------
      _ -> false
    end
  end)
```
And also here:
```
Original:

data = successes |> Enum.map(fn {:ok, time} -> time end)

Altered to this:

  data = successes |> Enum.map(fn {_, {:ok, time}} -> time end)
```

#### Errors:
- We don't handle remainders at all in `Blitzy.CLI.do_requests/3`. We use the integer division in elixir without handling the remainder, so the number of workers will always be a multiple of the number of nodes.

defmodule PasswordlessAuth.GarbageCollector do
  @moduledoc """
  Verification codes are stored in the PasswordlessAuth.VerificationCodes agent
  This worker looks for expires verification codes at a set interval
  and removes them from the Agent state
  """
  use GenServer
  alias PasswordlessAuth.VerificationCodes

  @frequency_secs 30

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(args) do
    run()
    {:ok, args}
  end

  def handle_info(:run, args) do
    remove_expired_items()
    run()
    {:noreply, args}
  end

  defp run do
    Process.send_after(self(), :run, @frequency_secs * 1000)
  end

  defp remove_expired_items do
    current_date_time = NaiveDateTime.utc_now()
    Agent.update(
      VerificationCodes,
      &Enum.filter(&1, fn ({_, item}) -> 
        NaiveDateTime.compare(item[:expires], current_date_time) == :gt
      end) |> Map.new
    )
  end
end
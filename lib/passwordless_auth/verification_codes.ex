defmodule PasswordlessAuth.VerificationCodes do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end
end
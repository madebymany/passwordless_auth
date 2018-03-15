defmodule PasswordlessAuthTest do
  use ExUnit.Case
  import Mox
  doctest PasswordlessAuth

  @twilio_adapter PasswordlessAuthTest.ExTwilioMock

  test "greets the world" do
    expect(@twilio_adapter.Message, :create, fn _ -> {:ok, %{}} end)
    assert PasswordlessAuth.create_and_send_verification_code(%{}) == {:ok, %{}}
  end
end

defmodule PasswordlessAuth.GarbageCollectorTest do
  use ExUnit.Case
  alias PasswordlessAuth.{GarbageCollector, VerificationCode, Store}

  setup do
    # Clear the store before each test
    Agent.update(Store, fn _ -> %{} end)
  end

  describe "handle_info/2" do
    test ":collect_garbage removes codes whose `expires` dates are in the past" do
      Agent.update(
        Store,
        fn _ ->
          %{
            "+447123456789" => %VerificationCode{
              code: "123456",
              expires: NaiveDateTime.utc_now() |> NaiveDateTime.add(100)
            },
            "+15551234" => %VerificationCode{
              code: "555555",
              expires: NaiveDateTime.utc_now() |> NaiveDateTime.add(-100)
            }
          }
        end
      )
      GarbageCollector.handle_info(:collect_garbage, [])
      state = Agent.get(Store, fn state -> state end)
      assert Map.keys(state) == ["+447123456789"]
    end
  end
end

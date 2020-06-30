defmodule PasswordlessAuthTest do
  use ExUnit.Case
  import Mox
  alias PasswordlessAuth.{VerificationCode, Store}
  doctest PasswordlessAuth

  @sms_adapter Application.get_env(:passwordless_auth, :sms_adapter)

  setup do
    # Clear the store before each test
    Agent.update(Store, fn _ -> %{} end)
  end

  describe "create_and_send_verification_code/2" do
    test "requests message creation from Twilio API and returns response on success" do
      phone_number = "123"
      response = %{response: :data}

      expect(@sms_adapter.Message, :create, fn %{
                                                    body:
                                                      "Your verification code is: " <>
                                                        <<_::bytes-size(6)>>,
                                                    to: ^phone_number
                                                  } ->
        {:ok, response}
      end)

      assert PasswordlessAuth.create_and_send_verification_code(phone_number, []) ==
               {:ok, response}
    end

    test "requests message creation from Twilio API and returns error on failure" do
      phone_number = "123"
      error_message = "This is the error message."

      expect(@sms_adapter.Message, :create, fn %{
                                                    body:
                                                      "Your verification code is: " <>
                                                        <<_::bytes-size(6)>>,
                                                    to: ^phone_number
                                                  } ->
        {:error, error_message, 400}
      end)

      assert PasswordlessAuth.create_and_send_verification_code(phone_number, []) ==
               {:error, error_message}
    end

    test "stores verification code with expiry date in the future" do
      default_ttl = 300
      phone_number = "123"
      expect(@sms_adapter.Message, :create, fn _ -> {:ok, nil} end)
      PasswordlessAuth.create_and_send_verification_code(phone_number, [])

      assert %{
               "123" => %VerificationCode{
                 code: _,
                 expires: expires
               }
             } = Agent.get(Store, fn state -> state end)

      assert NaiveDateTime.compare(expires, NaiveDateTime.utc_now()) == :gt

      assert NaiveDateTime.compare(
               expires,
               NaiveDateTime.utc_now() |> NaiveDateTime.add(default_ttl)
             ) == :lt
    end

    test "passes twilio request options to the Twilio request" do
      phone_number = "123"
      messaging_service_sid = "abc123..."

      expect(@sms_adapter.Message, :create, fn %{ body: "Your verification code is: " <> <<_::bytes-size(6)>>,
                                                    to: ^phone_number,
                                                    messaging_service_sid: ^messaging_service_sid,
                                                    another_option: true
                                                  } ->
        {:ok, nil}
      end)

      assert PasswordlessAuth.create_and_send_verification_code(phone_number, %{
               sms_request_options: %{
                 messaging_service_sid: messaging_service_sid,
                 another_option: true
               }
             }) == {:ok, nil}
    end

    test "allows a custom message to be passed sent with the verification code" do
      phone_number = "123"

      expect(@sms_adapter.Message, :create, fn %{
                                                    body:
                                                      "Yarrr, " <>
                                                        <<_::bytes-size(6)>> <> " be the secret",
                                                    to: ^phone_number
                                                  } ->
        {:ok, nil}
      end)

      assert PasswordlessAuth.create_and_send_verification_code(
               phone_number,
               message: "Yarrr, {{code}} be the secret"
             ) == {:ok, nil}
    end

    test "allows a custom verification code length" do
      phone_number = "123"
      code_length = 9

      expect(@sms_adapter.Message, :create, fn %{
                                                    body:
                                                      "Your verification code is: " <>
                                                        <<_::bytes-size(code_length)>>,
                                                    to: ^phone_number
                                                  } ->
        {:ok, nil}
      end)

      assert PasswordlessAuth.create_and_send_verification_code(
               phone_number,
               code_length: code_length
             ) == {:ok, nil}
    end
  end

  describe "verify_code/2" do
    test "returns false when verification code doesn't exist for phone number" do
      add_verification_codes_to_store()
      assert PasswordlessAuth.verify_code("+447000000000", "123456") == {:error, :does_not_exist}
    end

    test "returns false when verification code does not match" do
      add_verification_codes_to_store()
      assert PasswordlessAuth.verify_code("+447123456789", "000000") == {:error, :incorrect_code}
    end

    test "returns false when verification code has expired" do
      expires = NaiveDateTime.utc_now() |> NaiveDateTime.add(-10)
      add_verification_codes_to_store(%{expires: expires})
      assert PasswordlessAuth.verify_code("+447123456789", "123456") == {:error, :code_expired}
    end

    test "returns false when attempts to enter the verification code are blocked" do
      attempts_blocked_until = NaiveDateTime.utc_now() |> NaiveDateTime.add(10)
      add_verification_codes_to_store(%{attempts_blocked_until: attempts_blocked_until})
      assert PasswordlessAuth.verify_code("+447123456789", "123456") == {:error, :attempt_blocked}
    end

    test "returns false after the max number of allowed_attempts for the verification code are reached" do
      add_verification_codes_to_store()

      for _ <- 1..Application.get_env(:passwordless_auth, :num_attempts_before_timeout) do
        {:error, :incorrect_code} = PasswordlessAuth.verify_code("+447123456789", "000000")
      end

      assert PasswordlessAuth.verify_code("+447123456789", "123456") == {:error, :attempt_blocked}
    end

    test "returns true when verification code matches and has not expired" do
      add_verification_codes_to_store()
      assert PasswordlessAuth.verify_code("+447123456789", "123456") == :ok
    end
  end

  describe "remove_code/1" do
    setup [:add_verification_codes_to_store]

    test "removes verification code for given phone number and does not remove other verification codes" do
      state = Agent.get(Store, fn state -> state end)
      phone_number = "+447123456789"
      removed_code = state[phone_number]
      assert PasswordlessAuth.remove_code(phone_number) == {:ok, removed_code}

      new_state = Agent.get(Store, fn state -> state end)
      assert Map.keys(new_state) == ["+15551234"]
    end

    test "returns error if verification code for given phone number does not exist in store" do
      assert PasswordlessAuth.remove_code("+447987654321") == {:error, :does_not_exist}
    end
  end

  defp add_verification_codes_to_store(context \\ %{}) do
    attempts_blocked_until = context[:attempts_blocked_until] || nil
    expires = context[:expires] || NaiveDateTime.utc_now() |> NaiveDateTime.add(300)

    Agent.update(Store, fn _ ->
      %{
        "+447123456789" => %VerificationCode{
          attempts_blocked_until: attempts_blocked_until,
          code: "123456",
          expires: expires
        },
        "+15551234" => %VerificationCode{
          attempts_blocked_until: attempts_blocked_until,
          code: "555555",
          expires: expires
        }
      }
    end)

    :ok
  end
end

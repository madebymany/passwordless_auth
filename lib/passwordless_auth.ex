defmodule PasswordlessAuth do
  use Application
  alias PasswordlessAuth.{GarbageCollector, VerificationCodes}

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(GarbageCollector, []),
      worker(VerificationCodes, [])
    ]

    opts = [strategy: :one_for_one, name: PasswordlessAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Send a verification code to the given `phone_number`
  The verification code is valid for the number of seconds given to the
  `verification_code_ttl` config option (defaults to 300)

  Returns `{:ok, twilio_response}` or `{:error, error}`.

  ## Examples

      iex> PasswordlessAuth.send_verification_code("+447123456789")
      {:ok, %ExTwilio.Message{...}}

  """
  def send_verification_code(phone_number) do
    verification_code = generate_verification_code()
    ttl = Application.get_env(:passwordless_auth, :verification_code_ttl)
    expires = NaiveDateTime.utc_now() |> NaiveDateTime.add(ttl)

    request = %{
      to: phone_number,
      messaging_service_sid: Application.get_env(:ex_twilio, :messaging_service_sid),
      body: "Your verification code is: #{verification_code}"
    }

    case ExTwilio.Message.create(request) do
      {:ok, response} ->
        Agent.update(
          VerificationCodes,
          &Map.put(&1, phone_number, %{
            verification_code: verification_code,
            expires: expires
          })
        )
        {:ok, response}
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Verifies that a the given `phone_number` has the
  given `verification_code` stores in state and that
  the verification code hasn't expired.

  Returns `true` or `false`.

  ## Examples

      iex> PasswordlessAuth.verify_code("+447123456789", "123456")
      true

  """
  def verify_code(phone_number, verification_code) do
    current_date_time = NaiveDateTime.utc_now()
    with state <- Agent.get(VerificationCodes, fn state -> state end),
         true <- Map.has_key?(state, phone_number),
         ^verification_code <- get_in(state, [phone_number, :verification_code]),
         :gt <- NaiveDateTime.compare(get_in(state, [phone_number, :expires]), current_date_time) do
      true
    else
      _ -> false
    end
  end

  def codes() do
    Agent.get(VerificationCodes, fn state -> state end)
  end

  defp generate_verification_code() do
    for _ <- 1..6 do
      :rand.uniform(10) - 1
    end
    |> Enum.join()
  end
end

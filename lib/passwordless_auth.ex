defmodule PasswordlessAuth do
  use Application
  alias PasswordlessAuth.{GarbageCollector, VerificationCode, Store}

  @twilio_adapter Application.get_env(:passwordless_auth, :twilio_adapter)

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(GarbageCollector, []),
      worker(Store, [])
    ]

    opts = [strategy: :one_for_one, name: PasswordlessAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Send a verification code to the given `phone_number`
  The verification code is valid for the number of seconds given to the
  `verification_code_ttl` config option (defaults to 300)

  Returns `{:ok, twilio_response}` or `{:error, error}`.
  """
  def create_and_send_verification_code(phone_number) do
    verification_code = VerificationCode.generate_code()
    ttl = Application.get_env(:passwordless_auth, :verification_code_ttl) || 300
    expires = NaiveDateTime.utc_now() |> NaiveDateTime.add(ttl)

    request = %{
      to: phone_number,
      messaging_service_sid: Application.get_env(:passwordless_auth, :messaging_service_sid),
      body: "Your verification code is: #{verification_code}"
    }

    case @twilio_adapter.Message.create(request) do
      {:ok, response} ->
        Agent.update(
          Store,
          &Map.put(&1, phone_number, %VerificationCode{
            code: verification_code,
            expires: expires
          })
        )

        {:ok, response}

      {:error, message, _code} ->
        {:error, message}
    end
  end

  @doc """
  Verifies that a the given `phone_number` has the
  given `verification_code` stores in state and that
  the verification code hasn't expired.

  Returns `true` or `false`.

  ## Examples

      iex> PasswordlessAuth.verify_code("+447123456789", "123456")
      false

  """
  def verify_code(phone_number, verification_code) do
    current_date_time = NaiveDateTime.utc_now()

    with state <- Agent.get(Store, fn state -> state end),
         true <- Map.has_key?(state, phone_number),
         ^verification_code <- get_in(state, [phone_number, Access.key(:code)]),
         :gt <-
           NaiveDateTime.compare(
             get_in(state, [phone_number, Access.key(:expires)]),
             current_date_time
           ) do
      true
    else
      _ -> false
    end
  end

  @doc """
  Removes a code from state based on the given `phone_number`

  Returns `{:ok, %VerificationCode{...}}` or `{:error, :reason}`.
  """
  def remove_code(phone_number) do
    state = Agent.get(Store, fn state -> state end)

    if Map.has_key?(state, phone_number) do
      code = Agent.get(Store, &Map.get(&1, phone_number))
      Agent.update(Store, &Map.delete(&1, phone_number))
      {:ok, code}
    else
      {:error, :does_not_exist}
    end
  end
end

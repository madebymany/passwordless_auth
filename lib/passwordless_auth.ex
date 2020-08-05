defmodule PasswordlessAuth do
  @moduledoc """
  PasswordlessAuth provides functionality for generating numeric codes that
  can be used for verifying a user's ownership of a phone number, email address
  or any other identifying address.

  It is designed to be used in a verification system, such as a passwordless authentication
  flow or as part of multi-factor authentication (MFA).
  """
  use Application
  alias PasswordlessAuth.{GarbageCollector, VerificationCode, Store}

  @default_verification_code_ttl 300
  @default_num_attempts_before_timeout 5
  @default_rate_limit_timeout_length 60

  @type verification_failed_reason() ::
          :attempt_blocked | :code_expired | :does_not_exist | :incorrect_code

  @doc false
  def start(_type, _args) do
    children = [
      GarbageCollector,
      Store
    ]

    opts = [strategy: :one_for_one, name: PasswordlessAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Generates a verification code for the given recipient. The code is a string of numbers that is `code_length` characters long (defaults to 6).

  The verification code is valid for the number of seconds given to the
  `verification_code_ttl` config option (defaults to 300)

  Arguments:

  - `recipient`: A reference to the recipient of the code. This is used for verifying the code with `verify_code/2`
  - `code_length`: The length of the code. Defaults to 6.

  Returns the code.
  """
  @spec generate_code(String.t(), integer()) ::
          String.t()
  def generate_code(recipient, code_length \\ 6) do
    code = VerificationCode.generate_code(code_length)

    ttl =
      Application.get_env(:passwordless_auth, :verification_code_ttl) ||
        @default_verification_code_ttl

    expires = NaiveDateTime.utc_now() |> NaiveDateTime.add(ttl)

    Agent.update(
      Store,
      &Map.put(&1, recipient, %VerificationCode{
        code: code,
        expires: expires
      })
    )

    code
  end

  @doc """
  Verifies that a the given `recipient` has the
  given `attempt_code` stored in state and that
  the code hasn't expired.

  Returns `:ok` or `{:error, :reason}`.

  ## Examples

      iex> PasswordlessAuth.verify_code("+447123456789", "123456")
      {:error, :does_not_exist}

  """
  @spec verify_code(String.t(), String.t()) :: :ok | {:error, verification_failed_reason()}
  def verify_code(recipient, attempt_code) do
    state = Agent.get(Store, fn state -> state end)

    with :ok <- check_code_exists(state, recipient),
         verification_code <- Map.get(state, recipient),
         :ok <- check_verification_code_not_expired(verification_code),
         :ok <- check_attempt_is_allowed(verification_code),
         :ok <- check_attempt_code(verification_code, attempt_code) do
      reset_attempts(recipient)
      :ok
    else
      {:error, :incorrect_code} = error ->
        increment_or_block_attempts(recipient)
        error

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Removes a code from state based on the given `recipient`

  Returns `{:ok, %VerificationCode{...}}` or `{:error, :reason}`.
  """
  @spec remove_code(String.t()) :: {:ok, VerificationCode.t()} | {:error, :does_not_exist}
  def remove_code(recipient) do
    state = Agent.get(Store, fn state -> state end)

    with :ok <- check_code_exists(state, recipient) do
      code = Agent.get(Store, &Map.get(&1, recipient))
      Agent.update(Store, &Map.delete(&1, recipient))
      {:ok, code}
    end
  end

  @spec check_code_exists(map(), String.t()) :: :ok | {:error, :does_not_exist}
  defp check_code_exists(state, recipient) do
    if Map.has_key?(state, recipient) do
      :ok
    else
      {:error, :does_not_exist}
    end
  end

  @spec check_verification_code_not_expired(VerificationCode.t()) :: :ok | {:error, :code_expired}
  defp check_verification_code_not_expired(%VerificationCode{expires: expires}) do
    case NaiveDateTime.compare(expires, NaiveDateTime.utc_now()) do
      :gt -> :ok
      _ -> {:error, :code_expired}
    end
  end

  @spec check_attempt_is_allowed(VerificationCode.t()) :: :ok | {:error, :attempt_blocked}
  defp check_attempt_is_allowed(%VerificationCode{attempts_blocked_until: nil}), do: :ok

  defp check_attempt_is_allowed(%VerificationCode{attempts_blocked_until: attempts_blocked_until}) do
    case NaiveDateTime.compare(attempts_blocked_until, NaiveDateTime.utc_now()) do
      :lt -> :ok
      _ -> {:error, :attempt_blocked}
    end
  end

  @spec check_attempt_code(VerificationCode.t(), String.t()) :: :ok | {:error, :incorrect_code}
  defp check_attempt_code(%VerificationCode{code: code}, attempt_code) do
    if attempt_code == code do
      :ok
    else
      {:error, :incorrect_code}
    end
  end

  @spec reset_attempts(String.t()) :: :ok
  defp reset_attempts(recipient) do
    Agent.update(Store, &put_in(&1, [recipient, Access.key(:attempts)], 0))
  end

  @spec increment_or_block_attempts(String.t()) :: :ok
  defp increment_or_block_attempts(recipient) do
    num_attempts_before_timeout =
      Application.get_env(:passwordless_auth, :num_attempts_before_timeout) ||
        @default_num_attempts_before_timeout

    attempts = Agent.get(Store, &get_in(&1, [recipient, Access.key(:attempts)]))

    if attempts < num_attempts_before_timeout - 1 do
      Agent.update(Store, &put_in(&1, [recipient, Access.key(:attempts)], attempts + 1))
    else
      num_attempts_before_timeout =
        Application.get_env(:passwordless_auth, :rate_limit_timeout_length) ||
          @default_rate_limit_timeout_length

      attempts_blocked_until =
        NaiveDateTime.utc_now() |> NaiveDateTime.add(num_attempts_before_timeout)

      Agent.update(Store, fn state ->
        state
        |> put_in([recipient, Access.key(:attempts)], 0)
        |> put_in([recipient, Access.key(:attempts_blocked_until)], attempts_blocked_until)
      end)
    end
  end
end

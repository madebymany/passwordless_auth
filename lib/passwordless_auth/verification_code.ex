defmodule PasswordlessAuth.VerificationCode do
  @moduledoc false
  @enforce_keys [:code, :expires]
  defstruct code: nil, expires: nil
  @type t :: %__MODULE__{code: integer(), expires: NaiveDateTime.t()}

  @doc false
  @spec generate_code(integer()) :: String.t()
  def generate_code(code_length) do
    for _ <- 1..code_length do
      :rand.uniform(10) - 1
    end
    |> Enum.join()
  end
end

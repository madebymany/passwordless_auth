defmodule PasswordlessAuth.VerificationCode do
  @moduledoc false
  defstruct code: nil, expires: nil

  @doc false
  @spec generate_code :: String.t()
  def generate_code do
    for _ <- 1..6 do
      :rand.uniform(10) - 1
    end
    |> Enum.join()
  end
end

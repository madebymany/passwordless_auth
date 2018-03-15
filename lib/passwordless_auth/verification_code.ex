defmodule PasswordlessAuth.VerificationCode do
  defstruct code: nil, expires: nil

  def generate_code do
    for _ <- 1..6 do
      :rand.uniform(10) - 1
    end
    |> Enum.join()
  end
end
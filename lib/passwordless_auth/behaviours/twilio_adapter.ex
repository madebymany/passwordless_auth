defmodule PasswordlessAuth.Behaviours.TwilioAdapter do
  @callback init() :: none()
  defmodule Message do
    @type request :: map()
    @type response :: struct()

    @doc """
    Creates a request to send an SMS based on the details given in the request map
    """
    @callback create(request()) :: {:ok, response()} | {:error, String.t(), integer()}
  end
end

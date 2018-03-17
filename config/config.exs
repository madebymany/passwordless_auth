use Mix.Config

config :passwordless_auth, twilio_adapter: ExTwilio

import_config "#{Mix.env()}.exs"

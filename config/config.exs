use Mix.Config

config :passwordless_auth,
  garbage_collector_frequency: 30,
  messaging_service_sid: "",
  twilio_adapter: ExTwilio,
  verification_code_ttl: 300

import_config "#{Mix.env}.exs"

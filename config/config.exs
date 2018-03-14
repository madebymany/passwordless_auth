use Mix.Config

config :passwordless_auth,
  messaging_service_sid: "",
  garbage_collector_frequency: 30,
  verification_code_ttl: 300

use Mix.Config

config :passwordless_auth,
  verification_code_ttl: 300,
  garbage_collector_frequency: 30

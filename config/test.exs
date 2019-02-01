use Mix.Config

config :passwordless_auth,
  num_attempts_before_timeout: 5,
  twilio_adapter: PasswordlessAuthTest.ExTwilioMock

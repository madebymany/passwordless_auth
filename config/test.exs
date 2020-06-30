use Mix.Config

config :passwordless_auth,
  num_attempts_before_timeout: 5,
  sms_adapter: PasswordlessAuthTest.ExTwilioMock

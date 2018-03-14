# PasswordlessAuth

**TODO: Add description**

## Installation

Add `passwordless_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:passwordless_auth, "~> 0.1.0"}
  ]
end
```
## Configuration

PasswordlessAuth depends on [ExTwilio config](https://github.com/danielberkompas/ex_twilio) so set ExTwilio config in your `config/config.exs` file:

```
config :ex_twilio,
  account_sid: "TWILIO_ACCOUNT_SID",
  auth_token: "TWILIO_AUTH_TOKEN",
  workspace_sid: "TWILIO_WORKSPACE_SID" # optional
```

Set PasswordlessAuth config in your `config/config.exs` file:

```
config :passwordless_auth,
  messaging_service_sid: "",
  garbage_collector_frequency: 30, # optional (defaults to 30)
  verification_code_ttl: 300 # optional (defaults to 300)
```

## TODO

- [] TESTS!
- [] Generate documentation
- [] Publish on hex.pm
- [] Don't start if config is missing
- [] Email authentication method

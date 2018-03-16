# PasswordlessAuth

This library gives you the ability to verify a user's phone number by sending them a verification code, and verifying that the code they provide matches the code that was sent to their phone number.

See [Usage](#usage) for example usage.

It can be used as an authentication method on it's own, or as part of 2-factor or multi-factor authentication.

It sends text messages by using the [Twilio](https://www.twilio.com/) API via [ex_twilio](https://github.com/danielberkompas/ex_twilio).

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

```elixir
config :ex_twilio,
  account_sid: "TWILIO_ACCOUNT_SID",
  auth_token: "TWILIO_AUTH_TOKEN",
  workspace_sid: "TWILIO_WORKSPACE_SID" # optional
```

Set PasswordlessAuth config in your `config/config.exs` file:

```elixir
config :passwordless_auth,
  messaging_service_sid: "",
  garbage_collector_frequency: 30, # in seconds; optional (defaults to 30 if not provided)
  verification_code_ttl: 300 # in seconds, optional (defaults to 300 if not provided)
```

## Usage

A passwordless authentication flow could look like this:

### 1. Send a verification code to the user's phone number

User enters their phone number to request a verification code.

```elixir
PasswordlessAuth.create_and_send_verification_code("+447123456789")
```

### 2. Verify the code

User receives a text message with their verification code and enters it into the login form.

```elixir
PasswordlessAuth.verify_code("+447123456789", "123456")
```

Returns `true` or `false`.

Once a code has been verified, it should be removed so that it can't be used again:

```elixir
PasswordlessAuth.remove_code("+447123456789")
```

## TODO

- [x] Tests
- [ ] Add license
- [ ] Publish on hex.pm
- [ ] Generate documentation
- [ ] Don't start if config is missing
- [ ] Twilio options can be passed to `create_and_send_verification_sms` rather than requiring `messaging_service_sid` to be configured
- [ ] Email authentication method
- [ ] Improve description in README
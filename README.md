# PasswordlessAuth

This library enables you to implement a simple passwordless login or 2-factor / multi-factor authentication. It can also be used as part of a user registration process.

It works by sending a text message with a numeric code to the phone number provided by the user. You can then request the user to verify the code they received before it expires.

See [Usage](#usage) for example usage.

Text messages are sent with the [Twilio](https://www.twilio.com/) API via [ex_twilio](https://github.com/danielberkompas/ex_twilio).

## Installation

Add `:passwordless_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:passwordless_auth, "~> 0.1.0"}
  ]
end
```

## Configuration

PasswordlessAuth depends on [ExTwilio config](https://github.com/danielberkompas/ex_twilio) so you need to set ExTwilio config in your `config/config.exs` file:

```elixir
config :ex_twilio,
  account_sid: "TWILIO_ACCOUNT_SID",
  auth_token: "TWILIO_AUTH_TOKEN",
  workspace_sid: "TWILIO_WORKSPACE_SID" # optional
```

Optionally set PasswordlessAuth config in your `config/config.exs` file:

```elixir
config :passwordless_auth,
  garbage_collector_frequency: 30, # seconds; optional (defaults to 30 if not provided)
  verification_code_ttl: 300 # seconds, optional (defaults to 300 if not provided)
```

## Usage

A passwordless authentication flow could look like this:

### 1. Send a verification code to the user's phone number

User enters their phone number to request a verification code.

```elixir
PasswordlessAuth.create_and_send_verification_code(
  "+447123456789",
  messaging_service_sid: "abc123..."
)
```

### 2. Verify the code

User receives a text message with their verification code and enters it into the login form.

```elixir
PasswordlessAuth.verify_code(
  "+447123456789",
  "123456"
)
```

Returns `true` or `false`.

Once a code has been verified, it should be removed so that it can't be used again:

```elixir
PasswordlessAuth.remove_code("+447123456789")
```

### 3. Authenticate session / issue token

It's up to you to decide what to do once a user has verified their phone number.

You could match the phone number to a user account, then authenticate the user's session for that user account, or issue them a token with claims for that user account, which [Guardian](https://github.com/ueberauth/guardian) could help you with.

If there is no user account with that phone number, you could allow the user to register by requesting more information from them.

## TODO

- [x] Tests
- [x] Twilio options can be passed to `create_and_send_verification_sms` rather than requiring `messaging_service_sid` to be configured
- [x] Make verification code length configurable
- [x] Add license
- [x] Generate documentation
- [x] Publish on hex.pm
- [ ] Email authentication method

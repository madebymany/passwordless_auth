# PasswordlessAuth

PasswordlessAuth provides functionality that can be used in an authentication
or verification system, such as a passwordless or multi-factor authentication
flow, or for verifying a user's ownership of a phone number, email address
or any other identifying address.

- Generate verification codes
- Verify a user's attempt at entering a code
- Rate limit attempts
- Expire codes

This library doesn't deal with sending the codes to recipients. 

See [Usage](#usage) for example usage.

## Documentation

Documentation is available at [https://hexdocs.pm/passwordless_auth](https://hexdocs.pm/passwordless_auth)

## Installation

Add `:passwordless_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:passwordless_auth, "~> 0.3.0"}
  ]
end
```

## Configuration

The following PasswordlessAuth config can be set in your `config/config.exs` file:

```elixir
config :passwordless_auth,
  # How long codes are valid for
  verification_code_ttl: 300, # seconds; default: 300
  # Rate limiting: how many failed attempts are allowed before the timeout is applied
  num_attempts_before_timeout: 5, # default: 5
  # Rate limiting: how long to disallow attempts after the limit has been reached
  rate_limit_timeout_length: 60, # seconds; default: 60
  # How often to clear out expired codes
  garbage_collector_frequency: 30 # seconds; default: 30
```

## Usage

Here's an example where the code is sent to a recipient's phone number using ExTwilio.

### 1. Generate a verification code for the recipient

User enters their phone number to request a verification code.

```elixir
code = PasswordlessAuth.generate_code("+447123456789")
=> "123456"
```

### 2. Send the code to the recipient

This library doesn't deal with SMS or emails, so this bit is up to you.
```elixir
ExTwilio.Message.create(%{
  to: "+447123456789",
  body: "Your code is #{code}"
})
```

### 3. Verify the code

Recipient receives a text message with their verification code. They enter it into your system and you verify that it is correct.

```elixir
attempt_code = "123456" # The user's attempt at entering the correct verification code.
PasswordlessAuth.verify_code(
  "+447123456789",
  attempt_code
)
```

Returns `true` or `false`.

Once a code has been verified, you can remove it so that it can't be used again before it expires.

```elixir
PasswordlessAuth.remove_code("+447123456789")
```

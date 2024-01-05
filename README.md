# puma-acme

A [Puma](https://puma.io/) plugin for adding HTTPS support to a Puma server
with SSL certs via [ACME](https://www.rfc-editor.org/rfc/rfc8555.html).

To use, configure the server name(s), accept the TOS, and add a bind directive.
The plugin will handle ACME account creation, order handling, challenge
responses, and certificate provisioning. A
[HTTP-01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)
rack handler also allows non-SSL addresses to automatically answer challenges.

On first boot, the server will start without SSL and run the ACME workflow in a
background thread. When the workflow finishes, the server will gracefully
restart and bind to the SSL port.

If the configured cache contains an unexpired certificate that matches the
algorithm and server name(s), it will use the cert to bind a listener at server
boot.

Setting a renewal interval based on the remaining time as a duration or a
fraction will enable automatic renewal. See `acme_renew_at` for details.

Supports standalone and cluster mode, along with graceful & rolling restarts.

## Installation

`Gemfile`:

```ruby
gem 'puma-acme'
```

## Configuration

basic:

```ruby
# config/puma.rb

config.bind 'tcp://0.0.0.0:80'

plugin :acme

acme_server_name 'puma-acme.example.org'
acme_tos_agreed true

config.bind 'acme://0.0.0.0:443'
```

advanced:

```ruby
# config/puma.rb

# Account contact URL(s). For email, use the form 'mailto:user@domain.tld'.
# Recommended for account recovery and revocation.
acme_contact 'mailto:acme-user@exmaple.org'

# Specify server names (SAN extension).
acme_server_names 'puma-acme.example.org', 'www.puma-acme.example.org'

# Enable automatic renewal based on an amount of time or fraction of life
# remaining. For an amount of time, use Integer seconds, for example the value
# 2592000 will set renewal to 30 days before certificate expiry. For a fraction
# of life remaining, use a Float between 0 and 1, for example the value 0.75
# will set renewal at 75% of the way through the certificate lifetime.
acme_renew_at 0.75

# URL of ACME server's directory URL, defaults to LetsEncrypt.
acme_directory 'https://acme.example.org/directory'

# Accept the Terms of Service (TOS) of an ACME server with the server's
# directory URL as a string or true to accept any server's TOS.
acme_tos_agreed 'https://acme.example.org/directory'

# External Account Binding (EAB) token KID & secret HMAC key for the ACME
# server. See RFC 8555, Section 7.3.4 for details.
acme_eab_kid      ENV['ACME_KID']
acme_eab_hmac_key ENV['ACME_HMAC_KEY']

# Encryption key algorithm, either :ecdsa or :rsa, defaults to :ecdsa.
acme_algorithm :ecdsa

# Provision mode, either :background or :foreground, defaults to :background.
# Background mode provisions certificates in a background thread without
# blocking binding or request serving for non-acme listeners.
# Foreground mode blocks all binding listeners until a certificate
# provisions, compatible only with zero-challenge ACME flow.
acme_mode :background

# ActiveSupport::Cache::Store compatible cache to store account, order, and
# certificate data. Defaults to a local filesystem based cache.
acme_cache Rails.cache

# Path to the cache directory for the default cache, defaults to 'tmp/acme'.
acme_cache_dir 'tmp/acme'

# Time to wait in seconds before rechecking order status, defaults to 1 second.
acme_poll_interval 1

# Time to wait in seconds before checking for renewal, defaults to 1 hour.
acme_renew_interval 60 * 60
```

## Tested ACME Providers

* [Anchor](https://anchor.dev/)
* [Let's Encrypt](https://letsencrypt.org/)
* [ZeroSSL](https://zerossl.com/)

## License

puma-acme is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

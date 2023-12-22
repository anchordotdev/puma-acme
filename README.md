# puma-acme

A [Puma](https://puma.io/) plugin for for SSL certs via
[ACME](https://www.rfc-editor.org/rfc/rfc8555.html).

Easily add HTTPS support to a Puma server. To use, configure the server
name(s), accept the TOS, and add a bind directive. The plugin will handle ACME
account creation, order handling, challenge responses, and certificate
provisioning. A rack handler for
[HTTP-01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)
is added to the app so that the non-SSL address can automatically answer
challenges.

On first boot, the server will boot without the SSL listener, and run the ACME
order workflow in a background thread of the main process. When the workflow
finishes and the certificate is ready, the server performs a graceful restart
and binds to the SSL port.

If the configured cache contains an unexpired certificate that matches the
algorithm and server name(s), it will use the cert to bind a listener at server
boot.

Automatic renewals can be enabled by configuring a renewal interval based on
the remaining time as a duration or a fraction. See the `acme_renew_at`
directive for details.

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

# Specify multiple server names (SAN extension).
acme_server_names 'puma-acme.example.org', 'www.puma-acme.example.org'

# Enable automatic renewal based on an amount of time or fraction of life
# remaining. For an amount of time, use a number of seconds as an Integer, for
# example the value 2592000 will set renewal to 30 days before certificate
# expiration. Use a Float between 0 and 1 for fraction of life remaining, for
# example the value 0.75 will set renewal at %75 of the way through the
# certificate lifetime.
acme_renew_at 0.75

# URL of ACME server's directory URL, default is LetsEncrypt.
acme_directory 'https://acme.example.org/directory'

# Accept the Terms of Service (TOS) of an ACME server, the value can be either
# the server's directory URL as a string, or true to accept any server's TOS.
acme_tos_agreed 'https://acme.example.org/directory'

# External Account Binding (EAB) token KID & secret HMAC key for the ACME
# server. See RFC 8555, Section 7.3.4 for details.
acme_eab_kid      ENV['ACME_KID']
acme_eab_hmac_key ENV['ACME_HMAC_KEY']

# Encryption key algorithm, :ecdsa & :rsa are supported, :ecdsa is the default.
acme_algorithm :ecdsa

# Provision mode, :background and :foreground are supported, :background is the
# default. Background mode will provision certificates in a background thread
# without blocking binding or request serving for non-acme listeners.
# Foreground mode blocks all binding listeners until a certificate is
# provisioned, and is only compatable with zero-challenge ACME flow.
acme_mode :background 

# Store account, order, and certificate data in any ActiveSupport::Cache::Store
# compatable cache store. A local filesystem based cache in the default.
acme_cache Rails.cache

# Path to the cache directory for the default cache, 'tmp/acme' is the default.
acme_cache_dir 'tmp/acme'

# Time to wait in seconds before checking for an updated order status, 1 second
# is the default.
acme_poll_interval 1

# Time to wait in seconds before checking for automatic renewal, default is 1
# hour.
acme_renew_interval 60 * 60
```

## Tested ACME Providers

* [Anchor](https://anchor.dev/)
* [Let's Encrypt](https://letsencrypt.org/)
* [ZeroSSL](https://zerossl.com/)

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

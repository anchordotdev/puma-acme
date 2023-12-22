# frozen_string_literal: true

require_relative './test_helper'

class ConfigurationTest < Minitest::Test
  def test_minimal_config
    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_server_name 'acme.example.test'
      config.acme_tos_agreed  true

      config.bind 'tcp://127.0.0.1:8080'
      config.bind 'acme://127.0.0.1:4433'

      config.app { [200, {}, ['hello world']] }
    end

    options = configuration.load

    assert options

    assert_equal ['acme.example.test'], options[:acme_server_names]
    assert_equal true, options[:acme_tos_agreed]
    assert_equal ['tcp://127.0.0.1:8080', 'acme://127.0.0.1:4433'], options[:binds]

    assert options[:app]
  end

  def test_vanced_config
    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_contact 'mailto:acme-user@example.org'

      config.acme_server_names 'puma-acme.example.org', 'www.puma-acme.example.org'

      config.acme_renew_at 0.75

      config.acme_directory 'https://acme.example.org/directory'
      config.acme_tos_agreed 'https://acme.example.org/directory'

      config.acme_eab_kid 'F00F'
      config.acme_eab_hmac_key 'DEADBEEF'

      config.acme_algorithm :ecdsa

      config.acme_mode :background

      config.acme_cache Puma::Acme::DiskStore.new(Dir.mktmpdir)
      config.acme_cache_dir '/tmp/cache/dir'

      config.acme_poll_interval 1
      config.acme_renew_interval 60 * 60

      config.bind 'tcp://127.0.0.1:8080'
      config.bind 'acme://127.0.0.1:4433'

      config.app { [200, {}, ['hello world']] }
    end

    options = configuration.load

    assert options

    assert_equal 'mailto:acme-user@example.org', options[:acme_contact]
    assert_equal ['puma-acme.example.org', 'www.puma-acme.example.org'], options[:acme_server_names]
    assert_equal 0.75, options[:acme_renew_at]
    assert_equal 'https://acme.example.org/directory', options[:acme_directory]
    assert_equal 'https://acme.example.org/directory', options[:acme_tos_agreed]
    assert_equal 'F00F', options[:acme_eab_kid]
    assert_equal 'DEADBEEF', options[:acme_eab_hmac_key]
    assert_equal :ecdsa, options[:acme_algorithm]
    assert_equal :background, options[:acme_mode]
    assert_equal '/tmp/cache/dir', options[:acme_cache_dir]
    assert_equal 1, options[:acme_poll_interval]
    assert_equal 3600, options[:acme_renew_interval]
    assert_equal ['tcp://127.0.0.1:8080', 'acme://127.0.0.1:4433'], options[:binds]

    assert options[:acme_cache]
    assert options[:app]
  end
end

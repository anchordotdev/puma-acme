# frozen_string_literal: true

require_relative './test_helper'

class IntegrationTest < Minitest::Test
  def setup
    if ENV['INTEGRATION_TEST'] != name
      skip "set INTEGRATION_TEST=#{name} to run"
    end
  end

  def run
    WebMock.disable!

    VCR.turned_off { super }
  ensure
    WebMock.enable!
  end

  def test_default_provisioning
    if (missing_vars = %w[SERVER_NAME HTTP_PORT HTTPS_PORT].select { |var| ENV[var].nil? }).any?
      fail "missing required env var for integration test: #{missing_vars * ', '}"
    end

    server_name = "default.#{ENV.fetch('SERVER_NAME')}"
    http_port = ENV.fetch('HTTP_PORT')
    https_port = ENV.fetch('HTTPS_PORT')

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_server_name server_name
      config.acme_tos_agreed  true

      config.bind("tcp://0.0.0.0:#{http_port}")
      config.bind("acme://0.0.0.0:#{https_port}")

      config.workers 3

      config.app { [200, {}, ['hello world']] }
    end

    run_server(http_port, configuration) do
      response = HTTP.get("http://#{server_name}/")

      assert_equal response.body.to_s, 'hello world'

      loop do
        response = HTTP.get("https://#{server_name}/")

        assert_equal response.body.to_s, 'hello world'

        break
      rescue HTTP::ConnectionError
        sleep 1
      end
    end
  end

  def test_eab_based_provisioning
    if (missing_vars = %w[DIRECTORY EAB_KID EAB_HMAC_KEY HTTP_PORT HTTPS_PORT SERVER_NAME].select { |var| ENV[var].nil? }).any?
      fail "missing required env var for integration test: #{missing_vars * ', '}"
    end

    server_name = "eab.#{ENV.fetch('SERVER_NAME')}"
    http_port = ENV.fetch('HTTP_PORT')
    https_port = ENV.fetch('HTTPS_PORT')

    directory = ENV.fetch('DIRECTORY')
    eab_kid = ENV.fetch('EAB_KID')
    eab_hmac_key = ENV.fetch('EAB_HMAC_KEY')

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_directory    directory
      config.acme_eab_kid      eab_kid
      config.acme_eab_hmac_key eab_hmac_key

      config.acme_server_name server_name

      config.bind("tcp://0.0.0.0:#{http_port}")
      config.bind("acme://0.0.0.0:#{https_port}")

      config.app { [200, {}, ['hello world']] }
    end

    run_server(http_port, configuration) do |events|
      response = HTTP.get("http://#{server_name}/")

      assert_equal response.body.to_s, 'hello world'

      loop do
        response = HTTP.get("https://#{server_name}/")

        assert_equal response.body.to_s, 'hello world'

        break
      rescue HTTP::ConnectionError
        sleep 1
      end
    end
  end

  def test_foreground_provisioning
    if (missing_vars = %w[DIRECTORY SERVER_NAME].select { |var| ENV[var].nil? }).any?
      fail "missing required env var for integration test: #{missing_vars * ', '}"
    end

    server_name = ENV.fetch('SERVER_NAME')
    https_port = ENV.fetch('HTTPS_PORT', unused_port)

    directory = ENV.fetch('DIRECTORY')
    eab_kid = ENV.fetch('EAB_KID', nil)
    eab_hmac_key = ENV.fetch('EAB_HMAC_KEY', nil)

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_directory    directory
      config.acme_eab_kid      eab_kid      unless eab_kid.nil?
      config.acme_eab_hmac_key eab_hmac_key unless eab_hmac_key.nil?

      config.acme_server_name server_name
      config.acme_mode :foreground

      config.bind("acme://0.0.0.0:#{https_port}")

      config.app { [200, {}, ['hello world']] }
    end


    run_server(https_port, configuration) do |events|
      response = HTTP.get("https://#{server_name}:#{https_port}/")

      assert_equal response.body.to_s, 'hello world'
    end
  end

  def test_default_renewal
    if (missing_vars = %w[SERVER_NAME HTTP_PORT HTTPS_PORT].select { |var| ENV[var].nil? }).any?
      fail "missing required env var for integration test: #{missing_vars * ', '}"
    end

    server_name = "default.#{ENV.fetch('SERVER_NAME')}"
    http_port = ENV.fetch('HTTP_PORT')
    https_port = ENV.fetch('HTTPS_PORT')

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_server_name server_name
      config.acme_tos_agreed  true

      config.acme_renew_at       0.000001
      config.acme_renew_interval 5

      config.bind("tcp://0.0.0.0:#{http_port}")
      config.bind("acme://0.0.0.0:#{https_port}")

      config.app { [200, {}, ['hello world']] }
    end

    run_server(http_port, configuration) do |events|
      response = HTTP.get("http://#{server_name}/")

      assert_equal response.body.to_s, 'hello world'

      loop do
        response = HTTP.get("https://#{server_name}/")

        assert_equal response.body.to_s, 'hello world'

        events.on_restart do
          response = HTTP.get("https://#{server_name}/")

          assert_equal response.body.to_s, 'hello world'

          # TODO: assert the cert has changed

          return
        rescue HTTP::ConnectionError
          sleep 1
        end
      rescue HTTP::ConnectionError
        sleep 1
      end
    end
  end
end

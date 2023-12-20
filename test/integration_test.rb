# frozen_string_literal: true

require_relative './test_helper'

class IntegrationTest < Minitest::Test
  def test_certificate_provisioning

    if (missing_vars = %w[ACME_SERVER_NAME ACME_HTTP_PORT ACME_HTTPS_PORT].select { |var| ENV[var].nil? }).any?
      skip "missing required env var for integration test: #{missing_vars * ', '}"
    end

    server_name = ENV.fetch('ACME_SERVER_NAME')
    http_port = ENV.fetch('ACME_HTTP_PORT')
    https_port = ENV.fetch('ACME_HTTPS_PORT')

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_server_name server_name
      config.acme_tos_agreed  true

      config.bind("tcp://0.0.0.0:#{http_port}")
      config.bind("acme://0.0.0.0:#{https_port}")

      config.workers 3

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
end

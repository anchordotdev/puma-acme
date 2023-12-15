# frozen_string_literal: true

require_relative './test_helper'

class IntegrationTest < Minitest::Test
  def test_certificate_provisioning

    if (missing_vars = %w[ACME_SERVER_NAME].select { |var| ENV[var].nil? }).any?
      skip "missing required env var for integration test: #{missing_vars * ', '}"
    end

    port, ssl_port = unused_port

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_server_name ENV.fetch('ACME_SERVER_NAME')

      config.bind "tcp://127.0.0.1:#{port}"
      # config.bind "ssl+acme://127.0.0.1:#{ssl_port}"

      config.app { [200, {}, ['hello world']] }
    end

    run_server(port, configuration) do
      response = HTTP.get("http://127.0.0.1:#{port}/")

      assert_equal response.body.to_s, 'hello world'
    end
  end
end

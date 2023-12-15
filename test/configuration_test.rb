# frozen_string_literal: true

require_relative './test_helper'

class ConfigurationTest < Minitest::Test
  def test_minimal_config
    port = unused_port

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_server_name 'acme.example.test'

      config.bind "tcp://127.0.0.1:#{port}"
      config.app { [200, {}, ['hello world']] }
    end

    run_server(port, configuration) do
      response = HTTP.get("http://127.0.0.1:#{port}/")

      assert_equal response.body.to_s, 'hello world'
    end
  end
end

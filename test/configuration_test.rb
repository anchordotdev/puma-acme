# frozen_string_literal: true

require_relative './test_helper'

class ConfigurationTest < Minitest::Test
  def test_minimal_config
    port = unused_port

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_server_name 'acme.example.test'
      config.acme_tos_agreed  true

      config.bind "tcp://127.0.0.1:#{port}"
      config.app { [200, {}, ['hello world']] }
    end

    run_server(port, configuration) do
      response = HTTP.get("http://127.0.0.1:#{port}/")

      assert_equal response.body.to_s, 'hello world'
    end
  end

  def test_maximal_config
    port = unused_port

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.acme_server_name 'acme.example.test'
      config.acme_tos_agreed  true

      config.acme_eab_kid 'F00F'
      config.acme_eab_hmac_key 'DEADBEEF'

      config.acme_renew_in 7 * 24 * 60 * 60 # 7 days

      config.bind "tcp://127.0.0.1:#{port}"
      config.app { [200, {}, ['hello world']] }
    end

    run_server(port, configuration) do
      response = HTTP.get("http://127.0.0.1:#{port}/")

      assert_equal response.body.to_s, 'hello world'
    end
  end
end

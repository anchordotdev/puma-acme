# frozen_string_literal: true

require_relative './test_helper'

require 'http'
require 'puma/configuration'
require 'puma/events'

class ConfigurationTest < Minitest::Test
  def test_minimal_config
    port = unused_port

    configuration = Puma::Configuration.new do |config|
      config.plugin :acme

      config.bind "tcp://127.0.0.1:#{port}"
      config.app { [200, {}, ['hello world']] }
    end

    run_server(configuration) do
      response = HTTP.get("http://127.0.0.1:#{port}/")

      assert_equal response.body.to_s, 'hello world'
    end
  end

  def run_server(configuration)
    wait, ready = IO.pipe

    events = Puma::Events.new
    events.on_booted { ready.close }

    log_writer = Puma::LogWriter.strings

    launcher = Puma::Launcher.new(configuration, events:, log_writer:)

    Thread.new do
      Thread.current.abort_on_exception = true

      launcher.run
    end

    wait.sysread 0

    yield
  ensure
    launcher&.stop
  end

  def unused_port(host: '127.0.0.1')
    TCPServer.open(host, 0) { |server| server.connect_address.ip_port }
  end
end

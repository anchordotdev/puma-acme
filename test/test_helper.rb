# frozen_string_literal: true

require 'bundler/setup'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'puma-acme'

require 'HTTP'
require 'minitest/autorun'
require 'minitest/mock_expectations'
require 'puma/configuration'
require 'puma/events'
require 'securerandom'
require 'vcr'
require 'webmock'

module Minitest
  class Test
    def run_server(port, configuration)
      wait, ready = IO.pipe

      events = Puma::Events.new
      events.on_booted { ready.close }

      log_writer = Puma::LogWriter::DEFAULT

      launcher = Puma::Launcher.new(configuration, events: events, log_writer: log_writer)

      Thread.new do
        Thread.current.abort_on_exception = true

        launcher.run
      end

      wait.sysread 0

      wait_for(port)

      yield(events)
    ensure
      launcher&.stop

      ensure_closed(port)
    end

    def unused_port(host: '127.0.0.1')
      TCPServer.open(host, 0) { |server| server.connect_address.ip_port }
    end

    def wait_for(port, host: '127.0.0.1', timeout: 500)
      kaboom_at = Time.now.to_i + timeout

      loop do
        return TCPSocket.new(host, port, connect_timeout: timeout).close
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::EINVAL, SocketError
        raise if Time.now.to_i > kaboom_at
      end
    end

    def ensure_closed(port, host: '127.0.0.1', timeout: 15)
      kaboom_at = Time.now.to_i + timeout

      loop do
        TCPSocket.new(host, port, connect_timeout: timeout).close

        raise StandardError, 'timeout' if Time.now.to_i > kaboom_at
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::EINVAL, Errno::ECONNRESET, SocketError
        return
      end
    end

    def with_vcr(*extra_ids, &block)
      VCR.use_cassette([class_name, name, *extra_ids&.map(&:to_s)].join('-'), &block)
    end
  end
end

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = false
  c.cassette_library_dir = 'test/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :new_episodes
  }

  %w[Boulder-Requester Date Replay-Nonce].each do |header|
    c.filter_sensitive_data("<#{header}>") do |interaction|
      interaction.response.headers[header]&.first
    end
  end

  c.before_record do |interaction|
    if ip_addr = interaction.response.body[/"initialIp": "(\d{1,3}.){3}\d{1,3}"/]
      interaction.filter!(ip_addr, '"initialIp": "<IP>"')
    end

    if contact = interaction.response.body[/"mailto:[^"]+"/]
      interaction.filter!(contact, '"mailto:<EMAIL>"')
    end
  end
end

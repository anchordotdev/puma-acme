# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')

require 'puma-acme'

require 'http'
require 'minitest/autorun'
require 'puma/configuration'
require 'puma/events'

module Minitest
  class Test
    def run_server(port, configuration)
      wait, ready = IO.pipe

      events = Puma::Events.new
      events.on_booted { ready.close }

      log_writer = Puma::LogWriter::DEFAULT

      launcher = Puma::Launcher.new(configuration, events:, log_writer:)

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
  end
end

# frozen_string_literal: true

require 'puma'
require 'puma/plugin'

require_relative './puma-acme/dsl'
require_relative './puma-acme/manager'

module Puma
  class Plugin
    # This is a plugin for Puma that will automatically provision a SSL
    # certificate.
    class Acme
      Puma::Plugins.register('acme', self)

      class Error < StandardError; end

      DEFAULT_DIRECTORY_URL = 'https://acme-v02.api.letsencrypt.org/directory'

      def start(launcher)
        options = launcher.options.final_options

        directory_url = options[:acme_directory_url] || DEFAULT_DIRECTORY_URL

        server_names = options[:acme_server_names] || raise(Error, 'missing ACME server name(s)')

        @manager = Manager.new(
          directory_url:,
          server_names:,
        )
      end
    end
  end
end

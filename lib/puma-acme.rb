# frozen_string_literal: true

require 'fileutils'
require 'puma'
require 'puma/plugin'

module Puma
  # This is a plugin for Puma that will automatically provision a SSL
  # certificate.
  module Acme
    class Error < StandardError; end

    class Plugin < Puma::Plugin
      Plugins.register('acme', self)

      SSL_ACME_SCHEME = 'ssl+acme:'

      DEFAULT_DIRECTORY = 'https://acme-v02.api.letsencrypt.org/directory'
      DEFAULT_SSL_ACME_BIND = "#{SSL_ACME_SCHEME}//0.0.0.0:4433"

      def start(launcher)
        identifiers = launcher.options[:acme_server_names] || raise(Error, 'missing ACME server name(s)')
        algorithm   = launcher.options.fetch(:acme_algorithm, :ecdsa)

        contact    = launcher.options.fetch(:acme_contact, nil)
        directory  = launcher.options.fetch(:acme_directory, DEFAULT_DIRECTORY)
        tos_agreed = launcher.options.fetch(:acme_tos_agreed, false)

        cache = launcher.options[:acme_cache] || disk_store(launcher.options)

        @manager = Manager.new(
          cache:,
          contact:,
          directory:,
          tos_agreed:,
        )

        if cert = @manager.fetch_certificate(identifiers:, algorithm:)
          unless launcher.options.fetch(:binds).any? {|bind| bind.start_with?(SSL_ACME_SCHEME) }
            launcher.options.fetch(:binds) << DEFAULT_SSL_ACME_BIND
          end

          return bind_to(cert)
        end

        order = @manager.order(identifiers:)

        http_challenges = order.authorizations.map {|auth| auth.http }

        launcher.options[:app] = Middleware.new(
          launcher.options[:app],
          manager: @manager,
          challenges: http_challenges,
        )

        true
      end

      protected

      def disk_store(options)
        cache_dir = options[:cache_dir] || 'tmp/acme'

        FileUtils.mkdir_p(cache_dir)

        DiskStore.new(cache_dir)
      end
    end
  end
end

require_relative './puma-acme/disk_store'
require_relative './puma-acme/dsl'
require_relative './puma-acme/manager'
require_relative './puma-acme/middleware'
require_relative './puma-acme/version'

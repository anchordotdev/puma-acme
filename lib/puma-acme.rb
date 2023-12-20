# frozen_string_literal: true

require 'byebug'

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

        if eab_kid = launcher.options[:acme_eab_kid]
          eab = Eab.new(kid: eab_kid, hmac_key: launcher.options.fetch(:acme_eab_hmac_key))
        end

        store = launcher.options[:acme_cache] || disk_store(launcher.options)

        poll_interval = launcher.options.fetch(:acme_poll_interval, 1)

        @manager ||= Manager.new(
          store:,
          contact:,
          directory:,
          tos_agreed:,
          eab:,
        )

        if @acme_binds.nil?
          @acme_binds, binds = launcher.options[:binds].partition { |bind| bind.start_with?('acme://') }
          launcher.options[:binds] = binds
        end

        launcher.options[:app] = Middleware.new(
          launcher.options[:app],
          manager: @manager,
        )

        cert = @manager.cert(identifiers:, algorithm:)
        if cert.provisioned?
          launcher.log_writer.debug "Acme: cert already provisioned"
          bind_to(launcher, cert)
        else
          launcher.log_writer.debug "Acme: background provisioning cert"
          in_background { provision(launcher, cert, poll_interval:) }
        end

        # in_background { renew(launcher, identifiers:, algorithm:) }
      end

      protected

      def bind_to(launcher, cert)
        params = {
          'key_pem' => cert.key_pem,
          'cert_pem' => cert.cert_pem,
        }

        ctx = MiniSSL::ContextBuilder.new(params, launcher.log_writer).context

        new_servers = {}

        launcher.binder.before_parse_hook do
          @acme_binds.each do |str|
            uri = URI.parse(str)

            if fd = launcher.binder.inherited_fds.delete(str)
              io = launcher.binder.inherit_ssl_listener(fd, ctx)
              launcher.log_writer.log "* Inherited #{str}"
            elsif fd = launcher.binder.activated_sockets.delete([ :acme, uri.host, uri.port ])
              io = launcher.binder.inherit_ssl_listener(fd, ctx)
              launcher.log_writer.log "* Activated #{str}"
            else
              io = launcher.binder.add_ssl_listener(uri.host, uri.port, ctx)
            end

            cert.identifiers.each do |identifier|
              launcher.log_writer.log "* Listening on ssl://#{identifier.value}:#{uri.port}"
            end

            launcher.binder.listeners << [str, io]
          end
        end
      end

      def provision(launcher, cert, poll_interval:)
        unless @manager.account?
          launcher.log_writer.debug "Acme: creating account"

          @manager.account
        end

        if cert.order.nil?
          launcher.log_writer.debug "Acme: creating order"
          @manager.order!(cert)
        else
          @manager.reload!(cert)
        end

        loop do
          case cert.order.status.to_sym
          when :valid
            launcher.log_writer.debug "Acme: downloading cert & restarting puma server"

            @manager.download!(cert)

            launcher.restart

            return
          when :processing, :pending
            launcher.log_writer.debug "Acme: waiting on #{cert.order.status} order"

            sleep poll_interval

            @manager.reload!(cert)
          when :ready
            launcher.log_writer.debug "Acme: finalizing ready order"

            @manager.finalize!(cert)
          when :invalid
            launcher.log_writer.debug "Acme: invalid order, re-ordering"

            @manager.order!(cert)
          end
        end
      rescue StaleCert
        sleep poll_interval
        retry
      end

      def disk_store(options)
        cache_dir = options[:cache_dir] || 'tmp/acme'

        FileUtils.mkdir_p(cache_dir)

        DiskStore.new(cache_dir)
      end
    end
  end
end

require_relative './puma-acme/binder'
require_relative './puma-acme/disk_store'
require_relative './puma-acme/dsl'
require_relative './puma-acme/manager'
require_relative './puma-acme/middleware'
require_relative './puma-acme/structs'
require_relative './puma-acme/version'

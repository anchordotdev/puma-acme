# frozen_string_literal: true

module Puma
  module Acme
    class Plugin < Puma::Plugin
      Plugins.register('acme', self)

      def start(launcher)
        identifiers = launcher.options[:acme_server_names] || raise(Error, 'missing ACME server name(s)')
        algorithm   = launcher.options.fetch(:acme_algorithm, :ecdsa)

        contact    = launcher.options.fetch(:acme_contact, nil)
        directory  = launcher.options.fetch(:acme_directory, DEFAULT_DIRECTORY)
        tos_agreed = launcher.options.fetch(:acme_tos_agreed, false)

        if (eab_kid = launcher.options[:acme_eab_kid])
          eab = Eab.new(kid: eab_kid, hmac_key: launcher.options.fetch(:acme_eab_hmac_key))
        end

        store = launcher.options[:acme_cache] || disk_store(launcher.options)

        mode           = launcher.options.fetch(:acme_mode, :background)
        poll_interval  = launcher.options.fetch(:acme_poll_interval, 1)
        renew_at       = launcher.options.fetch(:acme_renew_at, nil)
        renew_interval = launcher.options.fetch(:acme_renew_interval, DEFAULT_RENEW_INTERVAL)

        @manager = Manager.new(
          store:,
          contact:,
          directory:,
          tos_agreed:,
          eab:
        )

        @acme_binds, binds = launcher.options[:binds].partition { |bind| bind.start_with?('acme://') }
        launcher.options[:binds] = binds

        launcher.options[:app] = Middleware.new(
          launcher.options[:app],
          manager: @manager
        )

        @log_writer = launcher.log_writer

        cert = @manager.cert(identifiers:, algorithm:)
        if cert.usable?
          @log_writer.debug 'Acme: cert already provisioned'

          bind_to(launcher, cert)

          if renew_at
            in_background do
              renew(cert, renew_at:, renew_interval:, poll_interval:)

              launcher.restart
            end
          end
        elsif mode == :background
          @log_writer.debug 'Acme: background provisioning cert'

          in_background do
            provision(cert, poll_interval:)

            @log_writer.debug 'Acme: restarting puma server'

            launcher.restart
          end
        elsif mode == :foreground
          @log_writer.debug 'Acme: provisioning cert'

          provision(cert, poll_interval:)
          bind_to(launcher, cert)

          if renew_at
            in_background do
              renew(cert, renew_at:, renew_interval:, poll_interval:)

              launcher.restart
            end
          end
        else
          raise UnknownMode, mode
        end
      end

      protected

      def bind_to(launcher, cert)
        params = {
          'key_pem' => cert.key_pem,
          'cert_pem' => cert.cert_pem
        }

        ctx = MiniSSL::ContextBuilder.new(params, @log_writer).context

        launcher.binder.before_parse_hook do
          @acme_binds.each do |str|
            uri = URI.parse(str)

            if (fd = launcher.binder.inherited_fds.delete(str))
              io = launcher.binder.inherit_ssl_listener(fd, ctx)
              @log_writer.log "* Inherited #{str}"
            elsif (fd = launcher.binder.activated_sockets.delete([:acme, uri.host, uri.port]))
              io = launcher.binder.inherit_ssl_listener(fd, ctx)
              @log_writer.log "* Activated #{str}"
            else
              io = launcher.binder.add_ssl_listener(uri.host, uri.port, ctx)
            end

            cert.identifiers.each do |identifier|
              @log_writer.log "* Listening on ssl://#{identifier.value}:#{uri.port}"
            end

            launcher.binder.listeners << [str, io]
          end
        end
      end

      def provision(cert, poll_interval:)
        unless @manager.account(create: false)
          @log_writer.debug 'Acme: creating account'

          @manager.account
        end

        if cert.order.nil?
          @log_writer.debug 'Acme: creating order'
          @manager.order!(cert)
        else
          @manager.reload!(cert)
        end

        loop do
          case cert.order.status.to_sym
          when :valid
            @log_writer.debug 'Acme: downloading cert'

            @manager.download!(cert)

            return
          when :processing, :pending
            @log_writer.debug "Acme: waiting on #{cert.order.status} order"

            sleep poll_interval

            @manager.reload!(cert)
          when :ready
            @log_writer.debug 'Acme: finalizing ready order'

            @manager.finalize!(cert)
          when :invalid
            @log_writer.debug 'Acme: invalid order, re-ordering'

            @manager.order!(cert)
          end
        end
      rescue StaleCert
        sleep poll_interval
        retry
      end

      def renew(cert, renew_at:, renew_interval:, poll_interval:)
        if cert.order.status.to_sym != :valid
          # finish provisioning aborted renewal
          return provision(cert, poll_interval:)
        end

        loop do
          sleep renew_interval

          next unless cert.renewable?(renew_at)

          @log_writer.debug 'Acme: creating renewal order'

          @manager.order!(cert)

          return provision(cert, poll_interval:)
        end
      rescue StaleCert
        sleep poll_interval
        retry
      end

      def disk_store(options)
        cache_dir = options[:acme_cache_dir] || 'tmp/acme'

        FileUtils.mkdir_p(cache_dir)

        DiskStore.new(cache_dir)
      end
    end
  end
end
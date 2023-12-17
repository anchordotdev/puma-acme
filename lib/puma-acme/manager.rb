# frozen_string_literal: true

require 'acme-client'

module Puma
  module Acme
    class Manager

      class UnknownAlgorithmError < Acme::Error; end

      attr_reader :contact, :directory, :tos_agreed

      def initialize(cache:, contact: nil, directory:, tos_agreed:)
        @cache = cache
        @contact = contact
        @directory = directory
        @tos_agreed = tos_agreed

        @client = acme_client(@contact || :default)
      end

      def fetch_certificate(identifiers:, algorithm:)
        return nil
      end

      def order(identifiers:, now: DateTime.now)
        key = [:order, *identifiers.sort]
        url = @cache.fetch(key) { new_order(identifiers:).url }

        order = @client.order(url:)
        if DateTime.parse(order.expires) <= now
          @cache.delete(key)
          return order(identifiers:, now:)
        end

        order
      end

      protected

      def acme_client(id)
        account_parts = @cache.fetch([:account, id]) { new_account }

        private_key = load_key(account_parts[:jwk], account_parts[:key])

        ::Acme::Client.new(
          kid: account_parts[:kid],
          private_key:,
          directory:,
        )
      end

      def new_account
        private_key = new_key(:ecdsa)

        client = ::Acme::Client.new(
          private_key:,
          directory:,
        )

        account = client.new_account(
          contact:,
          terms_of_service_agreed: [true, directory].include?(tos_agreed),
          # external_account_binding:
        )

        {
          jwk: client.jwk.to_h,
          kid: client.kid,
          key: private_key._dump(:unused),
        }
      end

      def new_order(identifiers:)
        @client.new_order(identifiers:)
      end

      def new_key(algorithm)
        case algorithm
        when :ecdsa then OpenSSL::PKey::EC.generate('prime256v1')
        when :rsa then OpenSSL::PKey::RSA.new(2048)
        else raise UnknownAlgorithmError, "unknown key algorithm '#{algorithm}'"
        end
      end

      def load_key(jwk, data)
        case jwk.slice(:kty, :crv)
        when {kty: 'RSA'}              then OpenSSL::PKey::RSA.new(data)
        when {kty: 'EC', crv: 'P-256'} then OpenSSL::PKey::EC.new(data)
        else raise UnknownAlgorithmError, "unknown key algorithm '#{jwk[:kty]}'"
        end
      end
    end
  end
end

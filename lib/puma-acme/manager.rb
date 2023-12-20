# frozen_string_literal: true

require 'acme-client'

module Puma
  module Acme
    class UnknownAlgorithmError < Acme::Error; end
    class StaleCert < Acme::Error; end

    class Manager

      CHALLENGE_TYPE = ::Acme::Client::Resources::Challenges::HTTP01::CHALLENGE_TYPE

      attr_reader :contact, :directory, :tos_agreed, :eab

      def initialize(store:, contact: nil, directory:, tos_agreed:, eab:)
        @store = store
        @contact = contact
        @directory = directory
        @tos_agreed = [true, directory].include?(tos_agreed)
        @eab = eab
      end

      def account?
        @store.read(Account.key(directory:, contact:, eab:))
      end

      def account
        @store.fetch(Account.key(directory:, contact:, eab:)) { create_account }
      end

      def cert(algorithm:, identifiers:)
        @store.fetch(Cert.key(algorithm:, identifiers:)) { Cert.new(algorithm:, identifiers:) }
      end

      def answer(type:, token:)
        @store.read(Answer.key(type:, token:))
      end

      def order!(cert)
        if @store.read(cert.key) != cert
          raise StaleCert
        end

        identifiers = cert.identifiers.map(&:value)
        acme_order = client.new_order(**cert.to_h.slice(:not_before, :not_after).merge(identifiers:))
        cert.order = Order.from(acme_order)

        # TODO: maybe move this to caller
        cert.order.authorizations.each do |authz|
          authz.challenges.each do |challenge|
            next unless challenge.type == CHALLENGE_TYPE

            validate!(challenge)
          end
        end

        @store.write(cert.key, cert)
      end

      def validate!(challenge)
        @store.write(challenge.answer.key, challenge.answer)

        acme_challenge = client.request_challenge_validation(url: challenge.url)
        acme_challenge
      end

      def finalize!(cert)
        if @store.read(cert.key) != cert
          raise StaleCert
        end

        identifiers = cert.identifiers.map(&:value)
        common_name = identifiers.first
        private_key = new_key(cert.algorithm)

        csr = ::Acme::Client::CertificateRequest.new(private_key:, subject: { common_name: })

        acme_order = client.order(url: cert.order.url)
        if acme_order.finalize(csr:)
          cert.order = Order.from(acme_order)
          cert.key_pem = private_key.to_pem

          @store.write(cert.key, cert)
        end
      end

      def download!(cert)
        if @store.read(cert.key) != cert
          raise StaleCert
        end

        acme_order = client.order(url: cert.order.url)

        cert.cert_pem = acme_order.certificate

        @store.write(cert.key, cert)
      end

      def reload!(cert)
        if @store.read(cert.key) != cert
          raise StaleCert
        end

        acme_order = client.order(url: cert.order.url)
        cert.order = Order.from(acme_order)

        @store.write(cert.key, cert)
      end

      protected

      def client
        @client ||= acme_client
      end

      def acme_client
        account = self.account

        ::Acme::Client.new(
          kid: account.kid,
          private_key: load_key(account.jwk, account.key_pem),
          directory:,
        )
      end

      def create_account
        private_key = new_key(:ecdsa)

        client = ::Acme::Client.new(
          private_key:,
          directory:,
        )

        acme_account = client.new_account(
          contact:,
          terms_of_service_agreed: tos_agreed,
          external_account_binding: eab&.to_h,
        )

        Account.new(acme_account.to_h.slice(:url, :status, :contact).merge({
          jwk: client.jwk.to_h,
          kid: client.kid,
          key_pem: private_key.to_pem,
          tos_agreed:,
        }))
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

# frozen_string_literal: true

module Puma
  module Acme

    Account = Struct.new(:directory, :url, :status, :contact, :tos_agreed, :eab, :jwk, :kid, :key_pem, keyword_init: true) do
      def self.key(directory:, contact: nil, eab: nil)
        new(directory:, contact:, eab:).key
      end

      def self.from(acme_account)
        new(acme_account.to_h.slice(*members))
      end

      def key
        [:account, directory, contact, eab&.key]
      end
    end

    Answer = Struct.new(:type, :token, :value, keyword_init: true) do
      def self.from(acme_challenge)
        new(
          type: acme_challenge.challenge_type,
          token: acme_challenge.token,
          value: acme_challenge.key_authorization,
        )
      end

      def self.key(type:, token:)
        new(type:, token:).key
      end

      def key
        [:answer, type, token]
      end
    end

    # https://datatracker.ietf.org/doc/html/rfc8555#section-7.1.4
    Authz = Struct.new(:url, :identifier, :status, :expires, :challenges, :wildcard, keyword_init: true) do
      def self.from(acme_authz)
        identifier = Identifier.from(acme_authz.identifier)
        challenges = acme_authz.challenges
          .reject {|c| c.is_a?(::Acme::Client::Resources::Challenges::Unsupported) }
          .map {|c| Challenge.from(c) }

        new(acme_authz.to_h.slice(*members).merge(challenges:, identifier:))
      end
    end

    Cert = Struct.new(:algorithm, :identifiers, :cert_pem, :key_pem, :order, keyword_init: true) do
      def self.key(algorithm:, identifiers:)
        new(algorithm:, identifiers:).key
      end

      def initialize(identifiers: nil, **kwargs)
        identifiers = identifiers&.map { |value| Identifier.parse(value) }

        super(identifiers:, **kwargs)
      end

      def key
        [:cert, algorithm, identifiers]
      end

      def provisioned?
        # TODO: check expiration

        !cert_pem.nil? && !key_pem.nil?
      end
    end

    # https://datatracker.ietf.org/doc/html/rfc8555#section-8
    Challenge = Struct.new(:url, :type, :token, :error, :answer, keyword_init: true) do
      def self.from(acme_challenge)
        new(acme_challenge.to_h.slice(*members).merge(type: acme_challenge.challenge_type, answer: Answer.from(acme_challenge)))
      end
    end

    Eab = Struct.new(:kid, :hmac_key, keyword_init: true) do
      def key
        [:eab, kid]
      end
    end

    Identifier = Struct.new(:type, :value, keyword_init: true) do
      def self.parse(value)
        # TODO: ip identifiers
        new(type: :dns, value:)
      end

      def self.from(acme_identifier)
        new(acme_identifier.to_h.slice(*members.map(&:to_s)))
      end
    end

    # https://datatracker.ietf.org/doc/html/rfc8555#section-7.1.3
    Order = Struct.new(:url, :status, :expires, :identifiers, :not_before, :not_after, :error, :authorizations, keyword_init: true) do
      def self.from(acme_order)
        identifiers = acme_order.identifiers.map {|i| Identifier.new(i) }
        authorizations = acme_order.authorizations.map {|a| Authz.from(a) }

        new(acme_order.to_h.slice(*members).merge(identifiers:, authorizations:))
      end
    end
  end
end

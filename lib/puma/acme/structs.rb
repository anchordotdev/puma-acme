# frozen_string_literal: true

module Puma
  module Acme
    # https://www.rfc-editor.org/rfc/rfc8555.html#section-7.1.2
    Account = Struct.new(:directory, :url, :status, :contact, :tos_agreed, :eab, :jwk, :kid, :key_pem,
                         keyword_init: true) do
      def self.key(directory:, contact: nil, eab: nil)
        new(directory: directory, contact: contact, eab: eab).key
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
          value: acme_challenge.key_authorization
        )
      end

      def self.key(type:, token:)
        new(type: type, token: token).key
      end

      def key
        [:answer, type, token]
      end
    end

    # https://www.rfc-editor.org/rfc/rfc8555.html#section-7.1.4
    Authz = Struct.new(:url, :identifier, :status, :expires, :challenges, :wildcard, keyword_init: true) do
      def self.from(acme_authz)
        identifier = Identifier.from(acme_authz.identifier)
        challenges = acme_authz.challenges
                               .reject { |c| c.is_a?(::Acme::Client::Resources::Challenges::Unsupported) }
                               .map { |c| Challenge.from(c) }

        new(acme_authz.to_h.slice(*members).merge(challenges: challenges, identifier: identifier))
      end
    end

    Cert = Struct.new(:algorithm, :identifiers, :cert_pem, :key_pem, :order, keyword_init: true) do
      def self.key(algorithm:, identifiers:)
        new(algorithm: algorithm, identifiers: identifiers).key
      end

      def initialize(identifiers: nil, **kwargs)
        identifiers = identifiers&.map { |value| Identifier.parse(value) }

        super(identifiers: identifiers, **kwargs)
      end

      def cert_pem=(pem)
        @x509 = nil

        self[:cert_pem] = pem
      end

      def key
        [:cert, algorithm, identifiers&.map(&:key)]
      end

      def names
        identifiers&.map(&:value)
      end

      def expired?(now: Time.now.utc)
        x509.not_after < now
      end

      def usable?(now: Time.now.utc)
        !cert_pem.nil? && !key_pem.nil? && !expired?(now: now)
      end

      def renewable?(renew_in, now: Time.now.utc)
        case renew_in
        when Float
          renew_at = x509.not_before + (x509.not_after - x509.not_before) * renew_in
        when Integer
          renew_at = x509.not_before + renew_in
        else
          raise UnknownRenewIn, renew_in
        end

        now >= renew_at
      end

      protected

      def x509
        @x509 ||= OpenSSL::X509::Certificate.new(cert_pem) if cert_pem
      end
    end

    # https://www.rfc-editor.org/rfc/rfc8555.html#section-8
    Challenge = Struct.new(:url, :type, :token, :error, :answer, keyword_init: true) do
      def self.from(acme_challenge)
        new(acme_challenge.to_h.slice(*members).merge(type: acme_challenge.challenge_type,
                                                      answer: Answer.from(acme_challenge)))
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
        new(type: :dns, value: value)
      end

      def self.from(acme_identifier)
        new(acme_identifier.to_h.slice(*members.map(&:to_s)))
      end

      def key
        [:identifier, type, value]
      end
    end

    # https://datatracker.ietf.org/doc/html/rfc8555#section-7.1.3
    Order = Struct.new(:url, :status, :expires, :identifiers, :not_before, :not_after, :error, :authorizations,
                       keyword_init: true) do
      def self.from(acme_order)
        identifiers = acme_order.identifiers.map { |i| Identifier.new(i) }
        authorizations = acme_order.authorizations.map { |a| Authz.from(a) }

        new(acme_order.to_h.slice(*members).merge(identifiers: identifiers, authorizations: authorizations))
      end

      def expired?(now: Time.now.utc)
        expires < now
      end
    end
  end
end

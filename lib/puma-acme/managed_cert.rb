# frozen_string_literal: true

module Puma
  module Acme

    CERT_MEMBERS = [
      :algorithm, :identifiers, :answers, :cert_pem, :key_pem, :order
    ]

    ManagedCert = Struct.new(*CERT_MEMBERS, keyword_init: true) do

      def self.build(algorithm:, identifiers:)
        new(
          algorithm:,
          identifiers:,
          state: :requested,
          answers: 0,
          key_pem: new_key(algorithm),
        )
      end

      def state
        case
        when cert_pem then :finished
        when answers > 0 then :answered
        when order then :ordered
        end
      end
    end
  end
end

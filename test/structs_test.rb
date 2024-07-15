# frozen_string_literal: true

require_relative './test_helper'

class CertsTest < Minitest::Test
  def test_changing_pem_changes_cert_properties
    key = R509::PrivateKey.new(type: 'RSA', bit_length: 2048)
    expired_at = Time.now.utc.to_i - 3600
    expired_pem = cert_pem(key, 'expired.test', not_before: expired_at - 3600, not_after: expired_at)

    cert = Puma::Acme::Cert.new(algorithm: :rsa, identifiers: %w[expired.test], cert_pem: expired_pem)
    assert cert.expired?


    unexpired_at = Time.now.utc.to_i
    unexpired_pem = cert_pem(key, 'unexpired.test', not_before: unexpired_at - 3600, not_after: unexpired_at + 3600)

    cert.cert_pem = unexpired_pem
    assert !cert.expired?
  end

  protected

  def cert_pem(key, common_name, not_before:, not_after:)
    csr = R509::CSR.new(
      subject: [['CN', common_name]],
      message_digest: 'SHA256',
      key: key
    )

    cert = R509::CertificateAuthority::Signer.selfsign(
      csr: csr,
      not_before: not_before,
      not_after: not_after
    )

    cert.to_pem
  end
end

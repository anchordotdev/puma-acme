# frozen_string_literal: true

require_relative './test_helper'

class ManagerTest < Minitest::Test
  include Puma::Acme

  def setup
    @tmp_dir = Dir.mktmpdir

    domain = ENV.fetch('DOMAIN', 'puma-acme.some-domain-that-does-not-exist.lol')
    contact = ENV.fetch('ACME_CONTACT', 'mailto:benburkert@anchor.dev')
    directory = ENV.fetch('ACME_DIRECTORY', 'https://acme-staging-v02.api.letsencrypt.org/directory')

    @server = URI.parse(directory).host

    if ENV['ACME_KID']
      eab = Puma::Acme::Eab.new(kid: ENV['ACME_KID'], hmac_key: ENV['ACME_HMAC_KEY'])
    end

    @manager = Manager.new(
      store: DiskStore.new(@tmp_dir),
      tos_agreed: true,
      contact:,
      directory:,
      eab:
    )

    @cert = @manager.cert!(algorithm: :ecdsa, identifiers: [domain])
  end

  def test_account_creation
    with_vcr(@server) do
      account = @manager.account!

      assert_equal 'valid', account.status
    end
  end

  def test_order_creation
    with_vcr(@server) do
      order = @manager.order!(@cert)

      assert_includes %w[pending ready], order.status
    end
  end

  def test_cert_finalization
    with_vcr(@server) do
      order = @manager.order!(@cert)

      skip unless order.status == 'ready'

      @manager.finalize!(@cert)

      assert_equal 'valid', @cert.order.status
    end
  end

  def test_cert_download
    with_vcr(@server) do
      order = @manager.order!(@cert)

      skip unless order.status == 'ready'

      @manager.finalize!(@cert)
      @manager.download!(@cert)

      assert @cert.cert_pem
    end
  end
end

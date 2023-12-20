# frozen_string_literal: true

require 'acme-client'
require 'fileutils'
require 'pstore'
require 'puma'
require 'puma/binder'
require 'puma/plugin'
require 'sinatra'

module Puma
  # This is a plugin for Puma that will automatically provision a SSL
  # certificate.
  module Acme
    class Error < StandardError; end
    class StaleCert < Error; end
    class UnknownAlgorithmError < Error; end
    class UnknownMode < Error; end

    CHALLENGE_TYPE = ::Acme::Client::Resources::Challenges::HTTP01::CHALLENGE_TYPE
    DEFAULT_DIRECTORY = 'https://acme-v02.api.letsencrypt.org/directory'
    DEFAULT_RENEW_INTERVAL = 60 * 60
  end
end

require_relative './acme/binder'
require_relative './acme/disk_store'
require_relative './acme/dsl'
require_relative './acme/manager'
require_relative './acme/middleware'
require_relative './acme/plugin'
require_relative './acme/structs'
require_relative './acme/version'

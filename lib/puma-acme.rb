# frozen_string_literal: true

require 'puma'
require 'puma/plugin'

module Puma
  class Plugin
    # This is a plugin for Puma that will automatically provision a SSL
    # certificate.
    class Acme
      Puma::Plugins.register('acme', self)

      def initialize(loader)
        # This is a Puma::PluginLoader
        @loader = loader
      end
    end
  end
end

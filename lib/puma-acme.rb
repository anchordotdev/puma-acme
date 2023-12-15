# frozen_string_literal: true

require 'puma'
require 'puma/plugin'

module Puma
  class Plugin
    # This is a plugin for Puma that will automatically provision a SSL
    # certificate.
    class Acme
      Puma::Plugins.register('acme', self)
    end
  end
end

# frozen_string_literal: true

module Puma
  class Plugin
    class Acme
      class Manager

        attr_reader :directory_url, :server_names

        def initialize(directory_url:, server_names:)
          @directory_url = directory_url
          @server_names = server_names
        end
      end
    end
  end
end

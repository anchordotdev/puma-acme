# frozen_string_literal: true

module Puma
  # Extend the ::Puma::DSL module with the configuration options we want
  class DSL
    def acme_directory_url(url = nil)
      @options[:acme_directory_url] = url if url
      @options[:acme_directory_url]
    end

    def acme_server_name(name)
      (@options[:acme_server_names] ||= []) << name
    end

    def acme_server_names(*names)
      (@options[:acme_server_names] ||= []).unshift(*names)
      @options[:acme_server_names]
    end
  end
end

# frozen_string_literal: true

module Puma
  # Extend the ::Puma::DSL module with the configuration options we want
  class DSL
    def acme_algorithm(algo = nil)
      @options[:acme_algorithm] = algo if algo
      @options[:acme_algorithm]
    end

    def acme_cache(cache = nil)
      @options[:acme_cache] = cache if cache
      @options[:acme_cache]
    end

    def acme_cache_dir(dir = nil)
      @options[:acme_cache_dir] = dir if dir
      @options[:acme_cache_dir]
    end

    def acme_contact(contact = nil)
      @options[:acme_contact] = contact if contact
      @options[:acme_contact]
    end

    def acme_directory(url = nil)
      @options[:acme_directory] = url if url
      @options[:acme_directory]
    end

    def acme_eab_kid(kid = nil)
      @options[:acme_eab_kid] = kid if kid
      @options[:acme_eab_kid]
    end

    def acme_eab_hmac_key(hmac_key = nil)
      @options[:acme_eab_hmac_key] = hmac_key if hmac_key
      @options[:acme_eab_hmac_key]
    end

    def acme_mode(mode = nil)
      @options[:acme_mode] = mode if mode
      @options[:acme_mode]
    end

    def acme_poll_interval(interval = nil)
      @options[:acme_poll_interval] = interval if interval
      @options[:acme_poll_interval]
    end

    def acme_renew_at(duration = nil)
      @options[:acme_renew_at] = duration if duration
      @options[:acme_renew_at]
    end

    def acme_renew_interval(duration = nil)
      @options[:acme_renew_interval] = duration if duration
      @options[:acme_renew_interval]
    end

    def acme_server_name(name)
      (@options[:acme_server_names] ||= []) << name
    end

    def acme_server_names(*names)
      (@options[:acme_server_names] ||= []).unshift(*names)
      @options[:acme_server_names]
    end

    def acme_tos_agreed(agreed)
      (@options[:acme_tos_agreed] = agreed) unless agreed.nil?
      @options[:acme_to_agreed]
    end
  end
end

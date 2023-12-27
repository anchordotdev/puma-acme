# frozen_string_literal: true

module Puma
  # Extend the ::Puma::Binder class to add hooks for acme binding support.
  class Binder
    def parse_with_before_hooks(*a, &b)
      @before_parse_hooks&.each(&:call)

      original_parse(*a, &b)
    end

    alias original_parse parse
    alias parse parse_with_before_hooks

    def before_parse_hook(&hook)
      (@before_parse_hooks ||= []) << hook
    end
  end
end

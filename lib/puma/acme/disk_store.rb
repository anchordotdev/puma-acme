# frozen_string_literal: true

module Puma
  module Acme
    # DiskStore is a simple key/value store that persists to disk using PStore.
    class DiskStore
      def initialize(dir)
        path = File.join(dir, 'puma-acme.pstore')
        @pstore = PStore.new(path, true)
      end

      def delete(key, _options = nil)
        @pstore.transaction do
          !!@pstore.delete(key)
        end
      end

      def fetch(key, _options = nil, &block)
        raise ArgumentError if block.nil?

        @pstore.transaction do
          @pstore[key] || (@pstore[key] = yield(key))
        end
      end

      def read(key, _options = nil)
        @pstore.transaction(true) do
          @pstore[key]
        end
      end

      def write(key, value, _options = nil)
        @pstore.transaction do
          @pstore[key] = value
          true
        end
      end
    end
  end
end

# frozen_string_literal: true

module Puma
  module Acme
    # ACME challenge response handler for HTTP-01 challenges.
    class Middleware
      def initialize(app, manager:)
        @app = app
        @manager = manager
      end

      def call(env)
        dup._call(env)
      end

      def _call(env)
        if (token = token(env)).nil?
          return @app.call(env)
        end

        if (answer = @manager.answer(type: CHALLENGE_TYPE, token: token)).nil?
          return @app.call(env)
        end

        [200, {'content-type' => 'text/plain;charset=utf-8'}, [answer.value]]
      end

      private

      def token(env)
        path = ::Rack::Request.new(env).path_info
        prefix = '/.well-known/acme-challenge/'
        path[prefix.size..-1] if path.start_with?(prefix)
      end
    end
  end
end

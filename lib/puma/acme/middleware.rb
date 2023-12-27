# frozen_string_literal: true

module Puma
  module Acme
    # ACME challenge response handler for HTTP-01 challenges.
    class Middleware < Sinatra::Base
      def initialize(app, manager:)
        @app = app
        @manager = manager

        super(app)
      end

      get '/.well-known/acme-challenge/:token' do
        if (token = params[:token]).nil?
          return @app.call(env)
        end

        if (answer = @manager.answer(type: CHALLENGE_TYPE, token: token)).nil?
          return @app.call(env)
        end

        content_type 'text/plain'
        answer.value
      end
    end
  end
end

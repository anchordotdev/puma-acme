# frozen_string_literal: true

require 'sinatra'

module Puma
  module Acme
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

        if (answer = @manager.answer(type: CHALLENGE_TYPE, token:)).nil?
          return @app.call(env)
        end

        content_type 'text/plain'
        answer.value
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../.././test_helper'
require "rack/test"

module Puma
  module Acme
    class MiddlewareTest < Minitest::Test
      include ::Rack::Test::Methods

      def test_it_returns_the_manager_answer_value_when_present
        get '/.well-known/acme-challenge/good-token'
        assert_equal '42', last_response.body
        assert_equal 'text/plain;charset=utf-8', last_response.headers['content-type']
      end

      def test_it_passes_through_if_manager_provides_no_answer
        get '/.well-known/acme-challenge/unknown-token'
        assert_equal 'request not handled by middleware', last_response.body
      end

      def test_it_passes_unrecognized_requests_through
        get '/'
        assert_equal 'request not handled by middleware', last_response.body

        get '/any-other/path'
        assert_equal 'request not handled by middleware', last_response.body
      end

      class App
        def call(env)
          [200, {}, ['request not handled by middleware']]
        end
      end

      class FakeManager
        class Answer
          def initialize(value)
            @value = value
          end
          attr_reader :value
        end

        def answer(type:, token:)
          Answer.new('42') if token == 'good-token'
        end
      end

      def app
        Puma::Acme::Middleware.new(
          App.new,
          manager: FakeManager.new
        )
      end
    end
  end
end

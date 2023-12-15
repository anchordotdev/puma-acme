# frozen_string_literal: true

require_relative './test_helper'

class PluginTest < Minitest::Test
  def test_registration
    assert_kind_of Class, Puma::Plugins.find('acme')
  end
end

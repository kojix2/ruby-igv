# frozen_string_literal: true

require_relative 'test_helper'
require 'colorize'
require 'igv'

class IGVTest < Test::Unit::TestCase
  def setup
    @igv = IGV.start
  end

  def test_echo
    assert_equal 'echo', @igv.echo
    assert_equal 'Hello!', @igv.echo('Hello!')
  end

  def teardown
    @igv.kill
    @igv.close
  end
end

# frozen_string_literal: true

require_relative 'test_helper'
require 'colorize'
require 'igv'

class IGVTest < Test::Unit::TestCase
  def setup
    @igv = case ENV['IGV_TEST_MODE']
           when 'external'
             IGV.open
           else
             IGV.start
           end
  end

  def test_echo
    assert_equal 'echo', @igv.echo
    assert_equal 'Hello!', @igv.echo('Hello!')
  end

  def teardown
    return unless @igv

    case ENV['IGV_TEST_MODE']
    when 'external'
      @igv.close
    else
      @igv.kill
      @igv.close
    end
  end
end

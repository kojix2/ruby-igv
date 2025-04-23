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
    @igv.set :SleepInterval, 1000
  end

  def test_igv
    assert_equal 'Hello!', @igv.echo('Hello!')
    assert_equal 'OK', @igv.genome(File.expand_path('fixtures/moo.fa', __dir__))
    assert_equal 'OK', @igv.load(File.expand_path('fixtures/moo.bam', __dir__))
    assert_equal 'OK', @igv.scroll_to_top
    assert_equal 'OK', @igv.snapshot_dir(File.expand_path('fixtures', __dir__))
    assert_equal 'OK', @igv.goto('chr1')
    assert_equal 'OK', @igv.snapshot
    assert_equal 'OK', @igv.goto('chr2')
    assert_equal 'OK', @igv.snapshot('test.png')
    assert_true File.exist?(File.expand_path('fixtures/test.png', __dir__))
  end

  def teardown
    return unless @igv

    case ENV['IGV_TEST_MODE']
    when 'external'
    else
      @igv.kill
    end
    @igv.close
  end
end

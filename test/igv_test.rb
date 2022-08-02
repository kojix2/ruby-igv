# frozen_string_literal: true

require_relative 'test_helper'
require 'colorize'
require 'igv'

class IGVTest < Test::Unit::TestCase
  def setup
    r, w = IO.pipe
    @pid_igv = spawn('igv', '-p', '60151', pgroup: true, out: w, err: w)
    Process.detach(@pid_igv)
    while (line = r.gets.chomp("\n"))
      puts line.colorize(:yellow)
      break if line.include? 'Listening on port 60151'
    end
    @igv = IGV.new
  end

  def test_echo
    assert_equal 'echo', @igv.echo
    assert_equal 'Hello!', @igv.echo('Hello!')
  end

  def teardown
    pgid = Process.getpgid(@pid_igv)
    Process.kill(:TERM, -pgid)
  end
end

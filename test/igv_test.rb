require_relative 'test_helper'
require 'colorize'
require 'igv'

class IGVTest < Test::Unit::TestCase
  def setup
    r, w = IO.pipe
    @pid_igv = spawn('igv -p 60151', out: w, err: w)
    Process.detach(@pid_igv)
    while line = r.gets
      puts line.colorize(:brown)
      break if line.include? 'Listening on port 60151'
    end
    @igv = IGV.new
  end

  def test_echo
    assert_equal 'echo', @igv.send('echo')
  end

  def teardown
    Process.kill(:TERM, @pid_igv)
  end
end

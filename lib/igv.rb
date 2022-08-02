# frozen_string_literal: true

require 'igv/version'
require 'socket'
require 'fileutils'

# The Integrative Genomics Viewer (IGV)
# https://software.broadinstitute.org/software/igv/
class IGV
  class Error < StandardError; end

  attr_reader :host, :port, :snapshot_dir, :history

  def initialize(host: '127.0.0.1', port: 60_151, snapshot_dir: Dir.pwd)
    @host = host
    @port = port
    @history = []
    connect
    set_snapshot_dir(snapshot_dir)
  end

  # def self.start
  # end

  def connect
    @socket&.close
    @socket = Socket.tcp(host, port)
  end

  # Show IGV batch commands in the browser.
  # https://github.com/igvteam/igv/wiki/Batch-commands

  def commands
    require 'launchy'
    Launchy.open('https://github.com/igvteam/igv/wiki/Batch-commands')
  end

  # Writes the value of "param" back to the response
  #
  # @param param [String] The parameter to echo.
  # @return [String] The value of "param". If param is not specified, "echo".

  def echo(param = nil)
    send "echo #{param}"
  end

  def go(position)
    send "goto #{position}"
  end
  alias goto go

  def genome(name_or_path)
    path = File.expand_path(name_or_path)
    if File.exist?(path)
      send "genome #{path}"
    else
      send "genome #{name_or_path}"
    end
  end

  def load(path_or_url)
    if URI.parse(path_or_url).scheme
      send "load #{path_or_url}"
    else
      send "load #{File.expand_path(path_or_url)}"
    end
  end

  def region(contig, start, end_)
    send ['region', contig, start, end_].join(' ')
  end

  def sort(option = 'base')
    unless %w[base position strand quality sample readGroup].include? option
      raise 'options is one of: base, position, strand, quality, sample, and readGroup.'
    end

    send "sort #{option}"
  end

  def expand(track = '')
    send "expand #{track}"
  end

  def collapse(track = '')
    send "collapse #{track}"
  end

  def clear
    send 'clear'
  end

  def exit
    send 'exit'
  end
  alias quit exit

  def send(cmd)
    cmd = cmd.to_str if cmd.respond_to? :to_str
    cmd = cmd.to_s if cmd.is_a? Symbol
    raise ArgumentError, 'cmd is not a string or a symbol' unless cmd.is_a? String

    @history << cmd
    @socket.puts(cmd.encode(Encoding::UTF_8))
    @socket.gets&.chomp("\n")
  end

  def snapshot_dir=(snapshot_dir)
    snapshot_dir = File.expand_path(snapshot_dir)
    return if snapshot_dir == @snaphot_dir

    FileUtils.mkdir_p(snapshot_dir)
    send "snapshotDirectory #{snapshot_dir}"
    @snapshot_dir = snapshot_dir
  end
  alias set_snapshot_dir snapshot_dir=

  def save(file_path = nil)
    if file_path
      # igv assumes the path is just a single filename, but
      # we can set the snapshot dir. then just use the filename.
      dir_path = File.dirname(file_path)
      set_snapshot_dir(File.expand_path(dir_path)) if dir_path != '.'
      send "snapshot #{File.basename(file_path)}"
    else
      send 'snapshot'
    end
  end
  alias snapshot save
end

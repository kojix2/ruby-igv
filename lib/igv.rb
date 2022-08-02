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
    send :echo, param
  end

  def goto(position)
    send :goto, position
  end
  alias go goto

  # Selects a genome by id, or loads a genome (or indexed fasta) from the supplied path.
  #
  # @param name_or_path [String] The genome to load

  def genome(name_or_path)
    path = File.expand_path(name_or_path)
    if File.exist?(path)
      send :genome, path
    else
      send :genome, name_or_path
    end
  end

  def load(path_or_url)
    if URI.parse(path_or_url).scheme
      send :load, path_or_url
    else
      send :load, File.expand_path(path_or_url)
    end
  end

  def region(contig, start, end_)
    send :region, contig, start, end_
  end

  def sort(option = 'base')
    vop = %w[base position strand quality sample readGroup]
    raise "options is one of: #{vop.join(', ')}" unless vop.include? option

    send :sort, option
  end

  def expand(track = nil)
    send :expand, track
  end

  def collapse(track = nil)
    send :collapse, track
  end

  def clear
    send :clear
  end

  def exit
    send :exit
  end
  alias quit exit

  def send(*cmds)
    cmd = \
      cmds
      .compact
      .map do |cmd|
        case cmd
        when String, Symbol                   then cmd.to_s
        when ->(c) { c.respond_to?(:to_str) } then cmd.to_str
        else raise ArgumentError, "#{cmd.inspect} is not a string"
        end.strip.encode(Encoding::UTF_8)
      end
      .join(' ')
    @history << cmd
    @socket.puts(cmd)
    @socket.gets&.chomp("\n")
  end

  def snapshot_dir=(dir_path, force: false)
    dir_path = File.expand_path(dir_path)
    return if !force && dir_path == @snapshot_dir

    FileUtils.mkdir_p(dir_path)
    send :snapshotDirectory, dir_path
    @snapshot_dir = dir_path
  end
  alias set_snapshot_dir snapshot_dir=

  def save(file_path = nil)
    return send(:snapshot) if file_path.nil?

    dir_path = File.dirname(file_path)
    filename = File.basename(file_path)
    snapshot_dir = dir_path
    send :snapshot, File.basename(filename)
  end
  alias snapshot save
end

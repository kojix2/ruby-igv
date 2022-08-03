# frozen_string_literal: true

require 'igv/version'
require 'socket'
require 'fileutils'

# The Integrative Genomics Viewer (IGV)
# https://software.broadinstitute.org/software/igv/
class IGV
  class Error < StandardError; end

  attr_reader :host, :port, :history

  def initialize(host: '127.0.0.1', port: 60_151, snapshot_dir: Dir.pwd)
    @host = host
    @port = port
    @snapshot_dir = File.expand_path(snapshot_dir)
    @history = []
  end

  def self.open(host: '127.0.0.1', port: 60_151, snapshot_dir: Dir.pwd)
    igv = new(host: host, port: port, snapshot_dir: snapshot_dir)
    igv.connect
    return igv unless block_given?

    begin
      yield igv
    ensure
      @socket&.close
    end
    igv
  end

  def self.start(port: 60_151, command: 'igv')
    r, w = IO.pipe
    pid_igv = spawn(command, '-p', port.to_s, pgroup: true, out: w, err: w)
    pgid_igv = Process.getpgid(pid_igv)
    Process.detach(pid_igv)
    puts "\e[33m"
    while (line = r.gets.chomp("\n"))
      puts line
      break if line.include? "Listening on port #{port}"
    end
    puts "\e[0m"
    igv = open(port: port)
    igv.instance_variable_set(:@pgid_igv, pgid_igv)
    igv
  end

  def kill
    if instance_variable_defined?(:@pgid_igv)
      warn \
        'This method kills the process with the group ID specified at startup. ' \
        'Please use exit or quit if possible.'
    else
      warn \
        'The kill method terminates only IGV commands invoked by the start method.' \
        'Otherwise, use exit or quit.'
      return
    end
    pgid = @pgid_igv
    Process.kill(:TERM, -pgid)
    close
  end

  def connect(host2 = @host, port2 = @port, connect_timeout: nil)
    @socket&.close
    @socket = Socket.tcp(host2, port2, connect_timeout: connect_timeout)
  end

  # Close the socket.
  # This method dose not exit IGV.

  def close
    @socket&.close
  end

  def closed?
    return true if @socket.nil?

    @socket.closed?
  end

  # Send batch commands to IGV.

  def send(*cmds)
    cmd = \
      cmds
      .compact
      .map do |cmd|
        case cmd
        when String, Symbol, Numeric          then cmd.to_s
        when ->(c) { c.respond_to?(:to_str) } then cmd.to_str
        else raise ArgumentError, "#{cmd.inspect} is not a string"
        end.strip.encode(Encoding::UTF_8)
      end
      .join(' ')
    @history << cmd
    @socket.puts(cmd)
    @socket.gets&.chomp("\n")
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

  # Loads a data or session file by specifying a full path to a local file or a URL.
  #
  # @param path_or_url [String] The path to a local file or a URL
  # @param index [String] The index of the file

  def load(path_or_url, index: nil)
    path_or_url = if URI.parse(path_or_url).scheme
                    path_or_url
                  else
                    File.expand_path(path_or_url)
                  end
    index = "index=#{index}" if index
    send :load, path_or_url, index
  end

  # Go to the specified location
  #
  # @param location [String] The location to go to.

  def goto(position)
    send :goto, position
  end
  alias go goto

  # Defines a region of interest bounded by the two loci
  #
  # @param chr [String] The chromosome of the region
  # @param start [Integer] The start position of the region
  # @param end_ [Integer] The end position of the region

  def region(chr, start, end_)
    send :region, chr, start, end_
  end

  def sort(option = 'base')
    vop = %w[base position strand quality sample readGroup]
    raise "options is one of: #{vop.join(', ')}" unless vop.include? option

    send :sort, option
  end

  # Expands the given track.
  #
  # @param track [String] The track to expand.
  #                       If not specified, expands all tracks.

  def expand(track = nil)
    send :expand, track
  end

  # Collapses a given track.
  #
  # @param track [String] The track to collapse.
  #                       If not specified, collapses all tracks.

  def collapse(track = nil)
    send :collapse, track
  end

  def clear
    send :clear
  end

  # Exit (close) the IGV application.

  def exit
    send :exit
    @socket.close
  end
  alias quit exit

  #	Sets the directory in which to write images.
  # Retruns the current snapshot directory if no argument is given.
  #
  # @param path [String] The path to the directory.

  def snapshot_dir(dir_path = nil)
    return @snapshot_dir if dir_path.nil?

    dir_path = File.expand_path(dir_path)
    return if dir_path == @snapshot_dir

    r = snapshot_dir_internal(dir_path)
    @snapshot_dir = dir_path
    r
  end

  private def snapshot_dir_internal(dir_path)
    dir_path = File.expand_path(dir_path)
    FileUtils.mkdir_p(dir_path)
    send :snapshotDirectory, dir_path
  end

  # Saves a snapshot of the IGV window to an image file.
  # If filename is omitted, writes a PNG file with a filename generated based on the locus.
  # If filename is specified, the filename extension determines the image file format,
  # which must be either .png or .svg.
  # @note In Ruby-IGV, it is possible to pass absolute or relative paths as well as file names;
  #       the Snapshot directory is set to Dir.pwd by default.
  #
  # @param file_path [String] The path to the image file.

  def snapshot(file_path = nil)
    return send(:snapshot) if file_path.nil?

    dir_path = File.dirname(file_path)
    filename = File.basename(file_path)
    if dir_path != @snapshot_dir
      snapshot_dir_internal(dir_path)
      r = send :snapshot, filename
      snapshot_dir_internal(@snapshot_dir)
      r
    else
      send :snapshot, filename
    end
  end

  # Temporarily set the preference named key to the specified value.
  #
  # @param key [String] The preference name
  # @param value [String] The preference value

  def preferences(key, value)
    send :preferences, key, value
  end

  # Show "preference.tab" in your browser.

  def show_preferences_table
    require 'launchy'
    Launchy.open('https://raw.githubusercontent.com/igvteam/igv/master/src/main/resources/org/broad/igv/prefs/preferences.tab')
  end

  # Save the current session.
  # It is recommended that a full path be used for filename. IGV release 2.11.1
  #
  # @param filename [String] The path to the session file

  def save_session(file_path)
    file_path = File.expand_path(file_path)
    send :saveSession, file_path
  end
end

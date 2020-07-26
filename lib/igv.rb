require 'igv/version'
require 'socket'
require 'fileutils'

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
    @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
    addr = Socket.sockaddr_in(port, host)
    @socket.connect(addr)
  end

  def go(position)
    send 'goto ' + position
  end
  alias goto go

  def genome(name_or_path)
    send 'genome ' + name_or_path
  end

  def load(path_or_url)
    send 'load ' + path_or_url
  end

  def region(contig, start, end_)
    send ['region', contig, start, end_].join(' ')
  end

  def sort(option = 'base')
    if %w[base position strand quality sample readGroup].include? option
      send 'sort ' + option
    else
      raise 'options is one of: base, position, strand, quality, sample, and readGroup.'
    end
  end

  def snapshot_dir=(snapshot_dir)
    snapshot_dir = File.expand_path(snapshot_dir)
    return if snapshot_dir == @snaphot_dir

    FileUtils.mkdir_p(snapshot_dir)
    send "snapshotDirectory #{snapshot_dir}"
    @snapshot_dir = snapshot_dir
  end
  alias set_snapshot_dir snapshot_dir=

  def expand(_track = '')
    send "expand #{track}"
  end

  def collapse(_track = '')
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
    @history << cmd
    @socket.puts(cmd.encode(Encoding::UTF_8))
    @socket.gets&.chomp("\n")
  end

  def save(file_path = nil)
    if file_path
      # igv assumes the path is just a single filename, but
      # we can set the snapshot dir. then just use the filename.
      dir_path = File.dirname(file_path)
      set_snapshot_dir(File.expand_path(dir_path)) if dir_path != '.'
      send 'snapshot ' + File.basename(file_path)
    else
      send 'snapshot'
    end
  end
  alias snapshot save
end

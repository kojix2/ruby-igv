# frozen_string_literal: true

require 'igv/version'
require 'uri'
require 'socket'
require 'fileutils'

# The Integrative Genomics Viewer (IGV) Ruby client.
# Provides a Ruby interface to control IGV via its batch command protocol.
#
# @see https://igv.org/doc/desktop/#UserGuide/tools/batch/#script-commands IGV Batch Script Documentation
class IGV
  class Error < StandardError; end

  attr_reader :host, :port, :history

  # Create IGV client object.
  #
  # @param host [String] Hostname or IP address of IGV server.
  # @param port [Integer] Port number of IGV server.
  # @param snapshot_dir [String] Directory path to save snapshots.
  # @return [IGV] IGV client object.
  def initialize(host: '127.0.0.1', port: 60_151, snapshot_dir: Dir.pwd)
    raise ArgumentError, 'IGV#initialize does not accept a block.' if block_given?

    @host = host
    @port = port
    @snapshot_dir = File.expand_path(snapshot_dir)
    @history = []
  end

  # Create IGV object and connect to IGV server.
  # This method accepts a block.
  #
  # @param host [String] Hostname or IP address of IGV server.
  # @param port [Integer] Port number of IGV server.
  # @param snapshot_dir [String] Directory path to save snapshots.
  # @yield [IGV] IGV client object.
  # @return [IGV] IGV client object.
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

  # Check if a port is open.
  # @param port [Integer] Port number.
  # @return [Boolean, nil] true if open, false if closed, nil if unknown.
  def self.port_open?(port)
    system("lsof -i:#{port}", out: '/dev/null')
  end
  private_class_method :port_open?

  # Launch IGV from Ruby script.
  #
  # @param port [Integer] Port number.
  # @param command [String] Command to launch IGV.
  # @param snapshot_dir [String] Directory path to save snapshots.
  # @return [IGV] IGV client object.
  # @note This will spawn a new IGV process and connect to it.
  def self.start(port: 60_151, command: 'igv', snapshot_dir: Dir.pwd)
    case port_open?(port)
    when nil   then warn "[ruby-igv] Cannot tell if port #{port} is open"
    when true  then raise("Port #{port} is already in use")
    when false then warn "[ruby-igv] Port #{port} is available"
    else raise "Unexpected return value from port_open?(#{port})"
    end
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
    igv = self.open(port: port, snapshot_dir: snapshot_dir)
    igv.instance_variable_set(:@pgid_igv, pgid_igv)
    igv
  end

  # Kill IGV process by process group id.
  #
  # @note Only works for IGV processes started by IGV.start.
  # @return [nil] Kills the IGV process if started by this client, otherwise does nothing.
  def kill
    if instance_variable_defined?(:@pgid_igv)
      warn '[ruby-igv] This method kills the process with the group ID specified at startup. Please use exit or quit if possible.'
    else
      warn '[ruby-igv] The kill method terminates only IGV commands invoked by the start method. Otherwise, use exit or quit.'
      return nil
    end
    pgid = @pgid_igv
    Process.kill(:TERM, -pgid)
    close
    nil
  end

  # Connect to IGV server.
  #
  # @param host2 [String] Hostname or IP address.
  # @param port2 [Integer] Port number.
  # @param connect_timeout [Integer, nil] Timeout in seconds.
  # @return [self] Returns self for method chaining.
  def connect(host2 = @host, port2 = @port, connect_timeout: nil)
    @socket&.close
    @socket = Socket.tcp(host2, port2, connect_timeout: connect_timeout)
    self
  end

  # Close the socket. This does not exit IGV.
  # @return [nil] Closes the socket and returns nil.
  def close
    @socket&.close
    nil
  end

  # Check if the socket is closed.
  # @return [Boolean]
  def closed?
    return true if @socket.nil?

    @socket.closed?
  end

  # Send batch commands to IGV.
  #
  # @param cmds [Array<String, Symbol, Numeric>] Batch commands.
  # @return [String] Response from IGV.
  # @example
  #   igv.send("goto", "chr1:1000-2000")
  def send(*cmds)
    cmd = \
      cmds
      .compact
      .map do |cm|
        case cm
        when String, Symbol, Numeric          then cm.to_s
        when ->(c) { c.respond_to?(:to_str) } then cm.to_str
        else raise ArgumentError, "#{cm.inspect} is not a string"
        end.strip.encode(Encoding::UTF_8)
      end
      .join(' ')
    @history << cmd
    @socket.puts(cmd)
    @socket.gets&.chomp("\n")
  end

  # Syntactic sugar for IGV commands that begin with set.
  #
  # @param cmd [String, Symbol] Batch command name (without "set" prefix).
  # @param params [Array<String, Symbol, Numeric>] Parameters for the command.
  # @return [String] Response from IGV.
  # @example
  #   igv.set :SleepInterval, 100
  #   igv.send "setSleepInterval", 100 # same as above
  def set(cmd, *params)
    cmd = "set#{cmd}"
    send(cmd, *params)
  end

  # Open IGV batch command documentation in the browser.
  def commands
    require 'launchy'
    Launchy.open('https://igv.org/doc/desktop/#UserGuide/tools/batch/#script-commands')
  end

  # Write the value of "param" back to the response.
  #
  # @note IGV Batch command: echo
  # @param param [String, nil] The parameter to echo.
  # @return [String] The value of "param". If param is not specified, "echo".
  # @example
  #   igv.echo("Hello!") #=> "Hello!"
  def echo(param = nil)
    send :echo, param
  end

  # Select a genome by id, or load a genome (or indexed fasta) from the supplied path.
  #
  # @note IGV Batch command: genome
  # @param name_or_path [String] Genome id (e.g. "hg19") or path to fasta/indexed genome.
  # @return [String] IGV response.
  # @example
  #   igv.genome("hg19")
  #   igv.genome("/path/to/genome.fa")
  def genome(name_or_path)
    path = File.expand_path(name_or_path)
    if File.exist?(path)
      send :genome, path
    else
      send :genome, name_or_path
    end
  end

  # Load a data or session file by specifying a full path to a local file or a URL.
  #
  # @note IGV Batch command: load
  # @param path_or_url [String] Path to a local file or a URL.
  # @param index [String, nil] Optional index file path.
  # @return [String] IGV response.
  # @example
  #   igv.load("http://example.com/data.bam")
  #   igv.load("/path/to/data.bam", index: "/path/to/data.bai")
  def load(path_or_url, index: nil)
    path_or_url = if URI.parse(path_or_url).scheme
                    path_or_url
                  else
                    File.expand_path(path_or_url)
                  end
    index = "index=#{index}" if index
    send :load, path_or_url, index
  rescue URI::InvalidURIError
    raise ArgumentError, "Invalid URI or file path: #{path_or_url}"
  end

  # Go to the specified location or list of loci.
  #
  # @note IGV Batch command: goto
  # @param position [String] Locus or list of loci (e.g. "chr1:1000-2000").
  # @return [String] IGV response.
  # @example
  #   igv.goto("chr1:1000-2000")
  def goto(position)
    send :goto, position
  end
  alias go goto

  # Define a region of interest bounded by the two loci.
  #
  # @note IGV Batch command: region
  # @param chr [String] Chromosome name.
  # @param start [Integer] Start position.
  # @param end_ [Integer] End position.
  # @return [String] IGV response.
  # @example
  #   igv.region("chr1", 100, 200)
  def region(chr, start, end_)
    send :region, chr, start, end_
  end

  # Sort alignment or segmented copy number tracks.
  #
  # @note IGV Batch command: sort
  # @param option [String] Sort option (e.g. "base", "position", "strand", "quality", "sample", "readGroup").
  # @return [String] IGV response.
  # @example
  #   igv.sort("position")
  def sort(option = 'base')
    vop = %w[base position strand quality sample readGroup]
    raise "options is one of: #{vop.join(', ')}" unless vop.include? option

    send :sort, option
  end

  # Expand a given track. If not specified, expands all tracks.
  #
  # @note IGV Batch command: expand
  # @param track [String, nil] Track name (optional).
  # @return [String] IGV response.
  # @example
  #   igv.expand
  #   igv.expand("track1")
  def expand(track = nil)
    send :expand, track
  end

  # Collapse a given track. If not specified, collapses all tracks.
  #
  # @note IGV Batch command: collapse
  # @param track [String, nil] Track name (optional).
  # @return [String] IGV response.
  # @example
  #   igv.collapse
  #   igv.collapse("track1")
  def collapse(track = nil)
    send :collapse, track
  end

  # Squish a given track. If not specified, squishes all annotation tracks.
  #
  # @note IGV Batch command: squish
  # @param track [String, nil] Track name (optional).
  # @return [String] IGV response.
  # @example
  #   igv.squish
  #   igv.squish("track1")
  def squish(track = nil)
    send :squish, track
  end

  # Set the display mode for an alignment track to "View as pairs".
  #
  # @note IGV Batch command: viewaspairs
  # @param track [String, nil] Track name (optional).
  # @return [String] IGV response.
  # @example
  #   igv.viewaspairs
  #   igv.viewaspairs("track1")
  def viewaspairs(track = nil)
    send :viewaspairs, track
  end

  # Create a new session. Unloads all tracks except the default genome annotations.
  #
  # @note IGV Batch command: new
  # @return [self] Returns self for method chaining.
  # @example
  #   igv.new
  def new
    send :new
    self
  end

  # Clear all loaded tracks and data.
  #
  # @note IGV Batch command: clear
  # @return [self] Returns self for method chaining.
  # @example
  #   igv.clear
  def clear
    send :clear
    self
  end

  # Exit (close) the IGV application and close the socket.
  #
  # @note IGV Batch command: exit
  # @return [nil] Exits IGV and closes the socket.
  # @example
  #   igv.exit
  def exit
    send :exit
    @socket.close
    nil
  end
  alias quit exit

  # Set or get the directory in which to write images (snapshots).
  #
  # @note IGV Batch command: snapshotDirectory
  # @param dir_path [String, nil] Directory path. If nil, returns current snapshot directory.
  # @return [String] IGV response or current directory.
  # @example
  #   igv.snapshot_dir("/tmp/snapshots")
  #   igv.snapshot_dir #=> "/tmp/snapshots"
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
    warn "[ruby-igv] Directory #{dir_path} does not exist. Creating it." unless File.exist?(dir_path)
    FileUtils.mkdir_p(dir_path)
    send :snapshotDirectory, dir_path
  end

  # Save a snapshot of the IGV window to an image file.
  #
  # @note IGV Batch command: snapshot
  # @param file_name [String, nil] Name of the image file. If nil, uses the current locus.
  #   If filename is omitted, writes a PNG file with a filename generated based on the locus.
  #   If filename is specified, the filename extension determines the image file format, which must be either .png or .svg.
  #   Passing a path might work, but is not recommended.
  # @example
  #   igv.snapshot("region.png")
  def snapshot(file_name = nil)
    return send(:snapshot) if file_name.nil?
    dir_path = File.dirname(file_name)

    # file_name is a file name
    return send(:snapshot, file_name) if dir_path == "."

    # file_name is a path
    file_path = file_name
    warn "[ruby-igv] snapshot: Passing a path is not recommended. "

    if File.absolute_path?(file_path)
      dir_path = File.expand_path(dir_path)
    else
      dir_path = File.expand_path(File.join(@snapshot_dir, dir_path))
    end

    filename = File.basename(file_path)
    
    # Only change directory if needed
    if dir_path == @snapshot_dir
      send(:snapshot, filename)
    else
      # Temporarily change snapshot directory
      original_dir = @snapshot_dir
      snapshot_dir_internal(dir_path)
      result = send(:snapshot, filename)
      snapshot_dir_internal(original_dir)
      result
    end
  end

  # Temporarily set the preference named key to the specified value.
  #
  # @note IGV Batch command: preference
  # @param key [String] Preference key.
  # @param value [String] Preference value.
  # @return [String] IGV response.
  # @see https://raw.githubusercontent.com/igvteam/igv/master/src/main/resources/org/broad/igv/prefs/preferences.tab
  # @example
  #   igv.preferences("SAM.READ_GROUP_COLOR", "sample")
  def preferences(key, value)
    send :preferences, key, value
  end

  # Show "preference.tab" in your browser.
  def show_preferences_table
    require 'launchy'
    Launchy.open('https://raw.githubusercontent.com/igvteam/igv/master/src/main/resources/org/broad/igv/prefs/preferences.tab')
  end

  # Save the current session.
  #
  # @note IGV Batch command: saveSession
  # @param file_path [String] Path to the session file.
  # @return [String] IGV response.
  # @example
  #   igv.save_session("session.xml")
  def save_session(file_path)
    file_path = File.expand_path(file_path)
    send :saveSession, file_path
  end

  # Set the track "altColor", used for negative values in a wig track or negative strand features.
  #
  # @note IGV Batch command: setAltColor
  # @param color [String] Color string (e.g. "255,0,0" or "FF0000").
  # @param track [String] Track name.
  # @return [String] IGV response.
  # @example
  #   igv.set_alt_color("255,0,0", "track1")
  def set_alt_color(color, track)
    send :setAltColor, color, track
  end

  # Set the track color.
  #
  # @note IGV Batch command: setColor
  # @param color [String] Color string (e.g. "255,0,0" or "FF0000").
  # @param track [String] Track name.
  # @return [String] IGV response.
  # @example
  #   igv.set_color("FF0000", "track1")
  def set_color(color, track)
    send :setColor, color, track
  end

  # Set the data range (scale) for all numeric tracks, or a specific track.
  #
  # @note IGV Batch command: setDataRange
  # @param range [String] Range string (e.g. "0,100" or "auto").
  # @param track [String] Track name.
  # @return [String] IGV response.
  # @example
  #   igv.set_data_range("0,100", "track1")
  def set_data_range(range, track)
    send :setDataRange, range, track
  end

  # Set the data scale to log (true) or linear (false).
  #
  # @note IGV Batch command: setLogScale
  # @param bool [Boolean] true for log scale, false for linear.
  # @param track [String] Track name (optional).
  # @return [String] IGV response.
  # @example
  #   igv.set_log_scale(true, "track1")
  def set_log_scale(bool, track)
    bool = 'true' if bool == true
    bool = 'false' if bool == false
    send :setLogScale, bool, track
  end

  # Set the sequence strand to positive (+) or negative (-).
  #
  # @note IGV Batch command: setSequenceStrand
  # @param strand [String] "+" or "-".
  # @return [String] IGV response.
  # @example
  #   igv.set_sequence_strand("+")
  def set_sequence_strand(strand)
    send :setSequenceStrand, strand
  end

  # Show or hide the 3-frame translation rows of the sequence track.
  #
  # @note IGV Batch command: setSequenceShowTranslation
  # @param bool [Boolean] true to show, false to hide.
  # @return [String] IGV response.
  # @example
  #   igv.set_sequence_show_translation(true)
  def set_sequence_show_translation(bool)
    bool = 'true' if bool == true
    bool = 'false' if bool == false
    send :setSequenceShowTranslation, bool
  end

  # Set a delay (sleep) time in milliseconds between successive commands.
  #
  # @note IGV Batch command: setSleepInterval
  # @param ms [Integer] Milliseconds to sleep.
  # @return [String] IGV response.
  # @example
  #   igv.set_sleep_interval(200)
  def set_sleep_interval(ms)
    send :setSleepInterval, ms
  end

  # Set the specified track's height in integer units.
  #
  # @note IGV Batch command: setTrackHeight
  # @param height [Integer] Height in pixels.
  # @param track [String] Track name.
  # @return [String] IGV response.
  # @example
  #   igv.set_track_height(50, "track1")
  def set_track_height(height, track)
    send :setTrackHeight, height, track
  end

  # Set the number of vertical pixels (height) of each panel to include in image.
  #
  # @note IGV Batch command: maxPanelHeight
  # @param height [Integer] Height in pixels.
  # @return [String] IGV response.
  # @example
  #   igv.max_panel_height(2000)
  def max_panel_height(height)
    send :maxPanelHeight, height
  end

  # Set the "color by" option for alignment tracks.
  #
  # @note IGV Batch command: colorBy
  # @param option [String] Color by option (e.g. "SAMPLE", "READ_GROUP", "TAG", ...).
  # @param tag [String, nil] Tag name (required for option "TAG").
  # @return [String] IGV response.
  # @example
  #   igv.color_by("SAMPLE")
  #   igv.color_by("TAG", "NM")
  def color_by(option, tag = nil)
    send :colorBy, option, tag
  end

  # Group alignments by the specified option.
  #
  # @note IGV Batch command: group
  # @param option [String] Group option (e.g. "SAMPLE", "READ_GROUP", "TAG", ...).
  # @param tag [String, nil] Tag name or position (required for option "TAG").
  # @return [String] IGV response.
  # @example
  #   igv.group("SAMPLE")
  #   igv.group("TAG", "NM")
  def group(option, tag = nil)
    send :group, option, tag
  end

  # Overlay a list of tracks.
  #
  # @note IGV Batch command: overlay
  # @param overlaid_track [String] The track to overlay.
  # @param tracks [Array<String>] List of tracks to overlay.
  # @return [String] IGV response.
  # @example
  #   igv.overlay("track1", "track2", "track3")
  def overlay(overlaid_track, *tracks)
    send :overlay, overlaid_track, *tracks
  end

  # Scroll all panels to the top of the view.
  #
  # @note IGV Batch command: scrollToTop
  # @return [String] IGV response.
  # @example
  #   igv.scroll_to_top
  def scroll_to_top
    send :scrollToTop
  end

  # Separate an overlaid track into its constituitive tracks.
  #
  # @note IGV Batch command: separate
  # @param overlaid_track_name [String] The name of the overlaid track to separate.
  # @return [String] IGV response.
  # @example
  #   igv.separate("track1")
  def separate(overlaid_track_name)
    send :separate, overlaid_track_name
  end

  # Set an access token to be used in an Authorization header for all requests to host.
  #
  # @note IGV Batch command: setAccessToken
  # @param token [String] The access token.
  # @param host [String, nil] The host to use the token for (optional).
  # @return [String] IGV response.
  # @example
  #   igv.set_access_token("mytoken", "example.com")
  def set_access_token(token, host = nil)
    send :setAccessToken, token, host
  end

  # Clears all access tokens.
  #
  # @note IGV Batch command: clearAccessTokens
  # @return [String] IGV response.
  # @example
  #   igv.clear_access_tokens
  def clear_access_tokens
    send :clearAccessTokens
  end
end

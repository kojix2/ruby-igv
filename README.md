# ruby-igv

[![Gem Version](https://badge.fury.io/rb/ruby-igv.svg)](https://badge.fury.io/rb/ruby-igv)
[![Docs Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://rubydoc.info/gems/ruby-igv)
[![Docs Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://kojix2.github.io/ruby-igv)
[![The MIT License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE.txt)
[![DOI](https://zenodo.org/badge/281373245.svg)](https://zenodo.org/badge/latestdoi/281373245)

Ruby-IGV is a simple tool for controlling the Integrated Genomics Viewer (IGV) from the Ruby language. It provides an automated way to load files, specify genome locations, and take and save screenshots using IGV.

## Installation

<img src="https://user-images.githubusercontent.com/5798442/182540876-c3ca2906-7d05-4c93-9107-ce4135ae9765.png" width="300" align="right">

Requirement : 

* [Ruby](https://github.com/ruby/ruby)
* [IGV (Integrative Genomics Viewer)](http://software.broadinstitute.org/software/igv/)
  * [Enable IGV to listen on the port](https://software.broadinstitute.org/software/igv/Preferences#Advanced)
  * View > Preference > Advanced > Enable port ☑

```ruby
gem install ruby-igv
```

## Quickstart

<img src="https://user-images.githubusercontent.com/5798442/182623864-a9fa59aa-abb9-4cb1-8311-2b3479b7414e.png" width="300" align="right">

```ruby
require 'igv'

igv = IGV.start # This launch IGV

igv.set      :SleepInterval, 200 # give a time interval
igv.genome   'hg19'
igv.load     'http://hgdownload.cse.ucsc.edu/goldenPath/' \
             'hg19/encodeDCC/wgEncodeUwRepliSeq/' \
             'wgEncodeUwRepliSeqK562G1AlnRep1.bam'
igv.go       'chr18:78016233-78016640'
igv.snapshot 'region.png'
```

## Usage

### IGV batch commands

The commonly used commands in IGV are summarized in the official [list of batch commands](https://github.com/igvteam/igv/wiki/Batch-commands). (but even this does not seem to be all of them). You can also call the `commands` method from Ruby to open a browser and view the list.

```ruby
igv.commands # Show the IGV command reference in your browser
```

### docs

See [yard docs](https://rubydoc.info/gems/ruby-igv/IGV). Commonly used IGV batch commands can be called from Ruby methods of the same name. However, not all IGV batch commands are implemented in Ruby. Use the `send` method described below.

### send

Commands that are not implemented can be sent using the send method.

```ruby
igv.send("maxPanelHeight", 10)
```

To avoid unexpected behavior, ruby-igv does not use the `method_missing` mechanism.

### Launch IGV

Launch IGV from Ruby script.

```ruby
igv = IGV.start # launch IGV app using spawn
```

You can specify the port.

```ruby
igv = IGV.start(port: 60152)
```

If you start IGV in this way, you can force IGV to terminate by calling the kill method.

```ruby
igv.kill
```

### Open socket connection to IGV

If IGV is already running, use `new` or `open`.

new

```ruby
igv = IGV.new   # create an IGV object. Then you will type `igv.connect`
igv = IGV.new(host: "127.0.0.1", port: 60151, snapshot_dir: "~/igv_snapshot")
igv.connect # To start a connection, call connect explicitly.
igv.close
```

open

```ruby
igv = IGV.open  # create an IGV object and connect it to an already activated IGV.
igv.close
IGV.open(host: "127.0.0.1", port: 60151, snapshot_dir: "~/igv_snapshot") do |igv|
  # do something
end # The socket is automatically closed.
```

### Close IGV

The behavior of the following methods is different.

```ruby
igv.close       # close the socket connection
igv.exit        # send exit command to IGV then close the socket connection
igv.quit        # alias method to exit
igv.kill        # kill group pid created with IGV.start
```

## Contributing

* [Report bugs](https://github.com/kojix2/ruby-igv/issues)
* Fix bugs and submit [pull requests](https://github.com/kojix2/ruby-igv/pulls)
* Write, clarify, or fix documentation
* Suggest or add new features

```
Do you need commit rights to this repository?
Do you want to get admin rights and take over the project?
If so, please feel free to contact me @kojix2.
```

## Acknowledgement
This gem is strongly inspired by a Python script developed by Brent Pedersen.
* [brentp/bio-playground/igv](https://github.com/brentp/bio-playground).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

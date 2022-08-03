# ruby-igv

[![Gem Version](https://badge.fury.io/rb/ruby-igv.svg)](https://badge.fury.io/rb/ruby-igv)
[![Docs Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://rubydoc.info/gems/ruby-igv)
[![The MIT License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE.txt)
[![DOI](https://zenodo.org/badge/281373245.svg)](https://zenodo.org/badge/latestdoi/281373245)


<img src="https://user-images.githubusercontent.com/5798442/182540876-c3ca2906-7d05-4c93-9107-ce4135ae9765.png" align="right">

## Installation

Requirement : 

* [Ruby](https://github.com/ruby/ruby)
* [IGV (Integrative Genomics Viewer)](http://software.broadinstitute.org/software/igv/)
  * [Enable IGV to listen on the port](https://software.broadinstitute.org/software/igv/Preferences#Advanced)
  * View > Preference > Advanced > Enable port ☑

```ruby
gem install ruby-igv
```

## Quickstart



```ruby
require 'igv'

igv = IGV.start # This launch IGV
igv.genome   'hg19'
igv.load     'http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/' \
             'wgEncodeUwRepliSeq/wgEncodeUwRepliSeqK562G1AlnRep1.bam'
igv.go       'chr18:78,016,233-78,016,640'
igv.snapshot 'region.png'
igv.exit
```

## Usage

See [the list of Batch commands](https://github.com/igvteam/igv/wiki/Batch-commands).

```ruby
igv.commands # Show the IGV command reference in your browser
```

### Launch IGV

Launch IGV from Ruby scripot.

```ruby
igv = IGV.start # launch IGV app using spawn
```

### Open socket connection to IGV

```ruby
igv = IGV.new   # create an IGV object. Then you will type `igv.connect`
igv = IGV.open  # create an IGV object and connect it to an already activated IGV.
```

### Close IGV

The behavior of the following methods is different.

```ruby
igv.close       # close the socket connection
igv.exit        # send exit command to IGV
igv.quit        # alias method to exit
igv.kill        # kill group pid created with IGV.start
```

## Contributing

* [Report bugs](https://github.com/kojix2/ruby-igv/issues)
* Fix bugs and submit [pull requests](https://github.com/kojix2/ruby-igv/pulls)
* Write, clarify, or fix documentation
* Suggest or add new features

```
Do you need commit rights to my repository?
Do you want to get admin rights and take over the project?
If so, please feel free to contact me @kojix2.
```

## Acknowledgement
This gem is strongly inspired by a Python script developed by Brent Pedersen.
* [brentp/bio-playground/igv](https://github.com/brentp/bio-playground).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

# Ruby-IGV

[![Gem Version](https://badge.fury.io/rb/ruby-igv.svg)](https://badge.fury.io/rb/ruby-igv)
[![Docs Latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://rubydoc.info/gems/ruby-igv)
[![The MIT License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE.txt)
[![DOI](https://zenodo.org/badge/281373245.svg)](https://zenodo.org/badge/latestdoi/281373245)

Controlling [Integrative Genomics Viewer (IGV)](http://software.broadinstitute.org/software/igv/) with the [Ruby](https://github.com/ruby/ruby) language.

## Installation

```ruby
gem install ruby-igv
```

## Usage

```ruby
igv = IGV.new
igv.genome 'hg19'
igv.load   'http://hgdownload.cse.ucsc.edu/goldenPath/hg19/encodeDCC/wgEncodeUwRepliSeq/wgEncodeUwRepliSeqK562G1AlnRep1.bam'
igv.go     'chr18:78,016,233-78,016,640'
igv.save   '/tmp/r/region.svg'
igv.save   '/tmp/r/region.png'
igv.snapshot_dir = '/tmp/r2/'
igv.save   'region.jpg'  # save to /tmp/r2/region.png
igv.send   'echo'        # whatever you want
```

* [Controlling IGV through a Port](https://software.broadinstitute.org/software/igv/PortCommands)

## Contributing

* [Report bugs](https://github.com/kojix2/ruby-igv/issues)
* Fix bugs and submit [pull requests](https://github.com/kojix2/ruby-igv/pulls)
* Write, clarify, or fix documentation
* Suggest or add new features

## Acknowledgement
This gem is strongly inspired by a Python script developed by Brent Pedersen.
* [brentp/bio-playground/igv](https://github.com/brentp/bio-playground).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

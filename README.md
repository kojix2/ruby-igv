# Ruby-IGV

Using Integrative Genomics Viewer (IGV) with the Ruby language.

Based on [brentp/bio-playground/igv](https://github.com/brentp/bio-playground).

## Installation

```ruby
gem install ruby-igv
```

## Usage

```ruby
igv = IGV.new
igv.gnome 'hg19'
igv.load 'http://www.broadinstitute.org/igvdata/1KG/pilot2Bams/NA12878.SLX.bam'
igv.go 'chr1:45,600-45,800'
igv.save '/tmp/r/region.svg'
igv.save '/tmp/r/region.png'
igv.send 'echo' #whatever
```

## Contributing

* [Report bugs](https://github.com/kojix2/ruby-igv/issues)
* Fix bugs and submit [pull requests](https://github.com/kojix2/ruby-igv/pulls)
* Write, clarify, or fix documentation
* Suggest or add new features

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

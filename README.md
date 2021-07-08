<div align="left">
  <img src="https://user-images.githubusercontent.com/5798442/124944058-fbfe9f00-e047-11eb-82d2-489a03ca193b.png" width="200" height="200">
  <a href="https://rubygems.org/gems/ruby-igv/"><img alt="Gem Version" src="https://badge.fury.io/rb/ruby-igv.svg"></a>
  <a href="https://rubydoc.info/gems/ruby-igv/"><img alt="Docs Stable" src="https://img.shields.io/badge/docs-stable-blue.svg"></a>
  <a href="LICENSE.txt"><img alt="The MIT License" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <a href="https://zenodo.org/badge/latestdoi/281373245"><img alt="DOI" src="https://zenodo.org/badge/281373245.svg"></a>
</div>



## Installation

Requirement: [IGV (Integrative Genomics Viewer)](http://software.broadinstitute.org/software/igv/) and [Ruby](https://github.com/ruby/ruby).

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

See [Controlling IGV through a Port](https://github.com/igvteam/igv/wiki/Batch-commands).

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

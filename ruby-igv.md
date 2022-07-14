---
title: 'Ruby-IGV: A simple IGV wrapper for Ruby'
author:
  - 'kojix2'
date: 7 Jan 2022
bibliography: ruby-igv.bib
header-includes:
  - \usepackage[margin=1in]{geometry}
---

# Summary

Ruby-IGV is a simple tool for controlling the Integrated Genomics Viewer (IGV) from the Ruby language. It provides an automated way to load files, specify genome locations, and take and save screenshots using IGV.

Code : [https://github.com/kojix2/ruby-igv](https://github.com/kojix2/ruby-igv)

# Statement of need

IGV [@robinsonIntegrativeGenomicsViewer2011] is a widely used genome browser that can visualize various genomic data, such as SAM/BAM format, which are biological sequence alignment format, and VCF/BCF files, which are variant call formats. 

In biology, it is common to visualize, explore, and validate the obtained genomic data. Researchers launch IGV, select the reference genome, open the genome file, and place the given data in each column. Then, they specify the position on the genome they want to observe and display it. Sometimes screenshots are taken and saved to files. These steps are repeated many times and need to be controlled by programming.

Ruby is an object-oriented general-purpose programming language. Although there are tools to control IGV from Python [@pedersen2021], there has been no package to control IGV from Ruby. Ruby-IGV creates a socket connection with IGV and controls IGV with commands. IGV can listen for HTTP requests on a certain port and receive commands to control it. This allows Ruby-IGV to control IGV.

## Examples

Setup:

```ruby
require 'igv'

igv = IGV.new
```

Load a reference genome:

```ruby
igv.genome 'hg19'
```

Load a bam file:

```ruby
igv.load 'hoge.bam'
```

Go to the specified location:

```ruby
igv.go 'chr18:78,016,233-78,016,640'
```

Save a screenshot:

```ruby
igv.save   '/tmp/r/region.svg'
```

# Reference

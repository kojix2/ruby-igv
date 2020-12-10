# frozen_string_literal: true

require_relative 'lib/igv/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby-igv'
  spec.version       = IGV::VERSION
  spec.authors       = ['kojix2']
  spec.email         = ['2xijok@gmail.com']

  spec.summary       = 'Control IGV (Integrative Genomics Viewer) with Ruby.'
  spec.description   = 'Control IGV (Integrative Genomics Viewer) with Ruby.'
  spec.homepage      = 'https://github.com/kojix2/ruby-igv'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.4'

  spec.files         = Dir['*.{md,txt}', '{lib}/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'colorize'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'test-unit'
end

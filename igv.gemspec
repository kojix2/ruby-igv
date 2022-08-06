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

  spec.required_ruby_version = '>= 2.6'

  spec.files         = Dir['*.{md,txt}', '{lib}/**/*']
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'launchy'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'colorize'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'test-unit'
end

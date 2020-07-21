require_relative 'lib/igv/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby-igv'
  spec.version       = IGV::VERSION
  spec.authors       = ['kojix2']
  spec.email         = ['2xijok@gmail.com']

  spec.summary       = 'Operate IGV (Integrative Genomics Viewer) from Ruby.'
  spec.description   = 'Operate IGV (Integrative Genomics Viewer) from Ruby.'
  spec.homepage      = 'https://github.com/kojix2/ruby-igv'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.files         = Dir['*.{md,txt}', '{lib}/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end

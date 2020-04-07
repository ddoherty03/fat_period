# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fat_period/version'

Gem::Specification.new do |spec|
  spec.name          = 'fat_period'
  spec.version       = FatPeriod::VERSION
  spec.authors       = ['Daniel E. Doherty']
  spec.email         = ['ded-law@ddoherty.net']

  spec.summary       = %q{Implements a Period class as a Range of Dates.}
  spec.homepage      = 'https://github.com/ddoherty03/fat_period'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  # Don't install any executables.
  # spec.bindir = 'bin'
  # spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-byebug'

  spec.add_runtime_dependency 'fat_core', '>= 4.8.3'
end

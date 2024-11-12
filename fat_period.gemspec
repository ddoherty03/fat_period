# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fat_period/version'

Gem::Specification.new do |spec|
  spec.name          = 'fat_period'
  spec.version       = FatPeriod::VERSION
  spec.authors       = ['Daniel E. Doherty']
  spec.email         = ['ded@ddoherty.net']

  spec.summary       = 'Implements a Period class as a Range of Dates.'
  spec.homepage      = 'https://github.com/ddoherty03/fat_period'

  spec.files = %x(git ls-files -z).split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  # Don't install any executables.
  # spec.bindir = 'bin'
  # spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'fat_core', '>= 5.4'
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbetl/version'

Gem::Specification.new do |spec|
  spec.name          = "rbetl"
  spec.version       = Rbetl::VERSION
  spec.authors       = ["Larry Murdock"]
  spec.email         = ["catfish.murdock@gmail.com"]
  spec.summary       = %q{rbetl processes text lines from various sources and to various outputs}
  spec.description   = %q{rbetl is three nodes where the output node pulls from the processor which pulls from the input. }
  spec.homepage      = ""
  spec.license       = "apache"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency 'rake', "~> 10.0"
  spec.add_development_dependency 'rdoc', '~> 4.1', '>=4.1.2'
  spec.add_development_dependency 'aruba', '~> 0.6', '>=0.6.1'
  spec.add_dependency('methadone', '~> 1.8', '>=1.8.0')
  spec.add_development_dependency('rspec', '~> 2.99')
end

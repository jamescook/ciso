# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'ciso/version'

Gem::Specification.new do |s|
  s.name        = 'ciso'
  s.version     = CISO::VERSION
  s.licenses    = ['MIT']
  s.authors     = ["James Cook"]
  s.email       = ["jcook.rubyist@gmail.com"]
  s.homepage    = "https://github.com/jamescook/ciso"
  s.summary     = %q{Compress/decompress PSP ISO files}
  s.description = %q{CISO allows you to compress and/or decompression images for use in Sony PSP}

  s.required_ruby_version     = '>= 1.8.7'
  s.required_rubygems_version = '>= 1.3.6'

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'pry', '~> 0.10.1'

  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }

  s.executables   = %w(ciso_compress ciso_decompress)
  s.require_paths = ["lib"]
end

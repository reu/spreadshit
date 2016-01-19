# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "spreadshit/version"

Gem::Specification.new do |spec|
  spec.name          = "spreadshit"
  spec.version       = Spreadshit::VERSION
  spec.authors       = ["Rodrigo Navarro"]
  spec.email         = ["rnavarro@rnavarro.com.br"]

  spec.summary       = %q{Simple spreadsheet implementation}
  spec.description   = %q{Simple spreadsheet implementation}
  spec.homepage      = "https://github.com/reu/spreadshit"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "treetop", "~> 1.6"
  spec.add_dependency "curses"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end

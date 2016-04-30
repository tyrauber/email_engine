# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "email_engine/version"

Gem::Specification.new do |spec|
  spec.name          = "email_engine"
  spec.version       = EmailEngine::VERSION
  spec.authors       = ["Ty Rauber"]
  spec.email         = ["tyrauber@mac.com"]
  spec.summary       = "Send and track emails at scale with Rails, Redis and Amazon SES"
  spec.description   = "Send and track emails at scale with Rails, Redis and Amazon SES"
  spec.homepage      = "https://github.com/tyrauber/email_engine"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rails"
  spec.add_runtime_dependency "addressable"
  spec.add_runtime_dependency "nokogiri"
  spec.add_runtime_dependency "safely_block"
  spec.add_runtime_dependency "redis"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "combustion"
  spec.add_development_dependency "sqlite3"
end

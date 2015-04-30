# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "rspec_junit_formatter"
  s.version     = "0.2.1"
  s.platform    = Gem::Platform::RUBY
  s.author      = "Samuel Cochran"
  s.email       = "sj26@sj26.com"
  s.homepage    = "http://github.com/sj26/rspec_junit_formatter"
  s.summary     = "RSpec JUnit XML formatter"
  s.description = "RSpec results that Hudson can read."
  s.license     = "MIT"

  s.required_rubygems_version = ">= 1.3.6"

  # https://github.com/rspec/rspec-core/commit/f06254c00770387e3a8a2efbdbc973035c217f6a
  s.add_dependency "rspec-core", ">= 2", "< 4", "!= 2.12.0"
  s.add_dependency "builder", "< 4"

  s.add_development_dependency "nokogiri", "~> 1.6"

  s.files        = Dir["lib/**/*", "README.md", "LICENSE"]
  s.require_path = "lib"
end

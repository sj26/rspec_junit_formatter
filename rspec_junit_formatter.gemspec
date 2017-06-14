# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "rspec_junit_formatter"
  s.version     = "0.3.0.pre4"
  s.platform    = Gem::Platform::RUBY
  s.author      = "Samuel Cochran"
  s.email       = "sj26@sj26.com"
  s.homepage    = "http://github.com/sj26/rspec_junit_formatter"
  s.summary     = "RSpec JUnit XML formatter"
  s.description = "RSpec results that your continuous integration service can read."
  s.license     = "MIT"

  s.required_ruby_version = ">= 2.0.0"
  s.required_rubygems_version = ">= 2.0.0"

  # https://github.com/rspec/rspec-core/commit/f06254c00770387e3a8a2efbdbc973035c217f6a
  s.add_dependency "rspec-core", ">= 2", "< 4", "!= 2.12.0"

  s.add_development_dependency "nokogiri", "~> 1.6"

  s.files        = Dir["lib/**/*", "README.md", "LICENSE"]
  s.require_path = "lib"
end

# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "rspec_junit_formatter"
  s.version     = "0.1.6"
  s.platform    = Gem::Platform::RUBY
  s.author      = "Samuel Cochran"
  s.email       = "sj26@sj26.com"
  s.homepage    = "http://github.com/sj26/rspec_junit_formatter"
  s.summary     = "RSpec JUnit XML formatter"
  s.description = "RSpec results that Hudson can read."

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "rspec", "~> 3.0"
  s.add_dependency "builder"

  s.add_development_dependency "nokogiri"

  s.files        = Dir["lib/**/*"] + %w[README.md LICENSE]
  s.require_path = "lib"
end

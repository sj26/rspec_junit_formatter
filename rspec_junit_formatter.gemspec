# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "rspec_junit_formatter"
  s.version     = "0.7.0"
  s.platform    = Gem::Platform::RUBY
  s.author      = "Samuel Cochran"
  s.email       = "sj26@sj26.com"
  s.homepage    = "https://github.com/sj26/rspec_junit_formatter"
  s.summary     = "RSpec JUnit XML formatter"
  s.description = "RSpec results that your continuous integration service can read."
  s.license     = "MIT"

  # 3.1 is the oldest Ruby line still receiving any attention upstream at the
  # time of this release; everything older is EOL. See CHANGELOG for details.
  s.required_ruby_version = ">= 3.1.0"
  s.required_rubygems_version = ">= 3.0.0"

  s.metadata = {
    "changelog_uri" => "https://github.com/sj26/rspec_junit_formatter/blob/HEAD/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  # RSpec 2 support was dropped in v0.7.0: rspec-core 2.x is unmaintained
  # (last released 2013) and does not run on currently supported Rubies.
  s.add_dependency "rspec-core", ">= 3.0", "< 4"

  # Only nokogiri belongs here rather than in the Gemfile: the Appraisal-
  # generated gemfiles under gemfiles/ each pull in just "gemspec path: .."
  # plus a pinned rspec version, so it's the only way to make it available
  # to the spec suite when running against those older rspec versions too.
  # rubocop:disable-next Gemspec/DevelopmentDependencies
  s.add_development_dependency "nokogiri", "~> 1.18"

  s.files        = Dir["lib/**/*", "README.md", "LICENSE"]
  s.require_path = "lib"
end

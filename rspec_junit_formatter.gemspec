Gem::Specification.new do |s|
  s.name        = "rspec_junit_formatter"
  s.version     = "0.8.0"
  s.platform    = Gem::Platform::RUBY
  s.author      = "Samuel Cochran"
  s.email       = "sj26@sj26.com"
  s.homepage    = "https://github.com/sj26/rspec_junit_formatter"
  s.summary     = "RSpec JUnit XML formatter"
  s.description = "RSpec results that your continuous integration service can read."
  s.license     = "MIT"

  s.required_ruby_version = ">= 3.3.0"
  s.required_rubygems_version = ">= 2.0.0"

  s.metadata = {
    'changelog_uri' => 'https://github.com/sj26/rspec_junit_formatter/blob/HEAD/CHANGELOG.md',
  }

  s.add_dependency "rspec-core", ">= 3.13", "< 4"

  s.add_development_dependency "bundler"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "nokogiri", "~> 1.8", ">= 1.8.2"
  s.add_development_dependency "rake"
  s.add_development_dependency "coderay"

  s.files        = Dir["lib/**/*", "README.md", "LICENSE"]
  s.require_path = "lib"
end

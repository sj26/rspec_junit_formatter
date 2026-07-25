# frozen_string_literal: true

# NOTE: rspec-core < 3.8 cannot run on Ruby 4.0+ at all: its .rspec option
# file parser calls the legacy 3-positional-argument ERB.new signature,
# which Ruby removed. This is an upstream rspec-core limitation (fixed in
# rspec-core 3.8.0, which added a RUBY_VERSION guard), not something this
# gem can work around, so only rspec-core >= 3.8 is exercised here. The
# gemspec's runtime dependency remains "rspec-core >= 3.0" since those older
# releases are still fine on older Rubies.
appraise "rspec-3-8" do
  gem "rspec", "~> 3.8.0"
end

appraise "rspec-3-9" do
  gem "rspec", "~> 3.9.0"
end

appraise "rspec-3-10" do
  gem "rspec", "~> 3.10.0"
end

appraise "rspec-3-11" do
  gem "rspec", "~> 3.11.0"
end

appraise "rspec-3-12" do
  gem "rspec", "~> 3.12.0"
end

appraise "rspec-3-13" do
  gem "rspec", "~> 3.13.0"
end

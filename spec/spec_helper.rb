# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start do
    skip "/spec/"
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
  end
end

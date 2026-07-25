# frozen_string_literal: true

require "bundler/gem_tasks"
require "appraisal"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task default: :appraisal if !ENV["APPRAISAL_INITIALIZED"] && !ENV["CI"]

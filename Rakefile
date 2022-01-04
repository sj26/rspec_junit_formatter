require "bundler/gem_tasks"
require "appraisal"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["CI"]
  task :default => :appraisal
end

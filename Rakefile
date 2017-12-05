require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "Run specs against all support rspec versions"
task "spec:all" do
  fail unless (Dir["gemfiles/Gemfile.*"] - Dir["gemfiles/Gemfile.*.lock"]).all? do |gemfile|
    Bundler.with_clean_env do
      system({"BUNDLE_GEMFILE" => gemfile}, "bundle", "exec", "rake", "spec")
    end
  end
end

task :default => :spec

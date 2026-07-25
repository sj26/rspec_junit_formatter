# frozen_string_literal: true

RSpec.configure do |config|
  # register around filter that captures stderr and stdout
  config.around do |example|
    $stdout = StringIO.new
    $stderr = StringIO.new

    example.run

    example.metadata[:stdout] = $stdout.string
    example.metadata[:stderr] = $stderr.string

    $stdout = STDOUT
    $stderr = STDERR
  end
end

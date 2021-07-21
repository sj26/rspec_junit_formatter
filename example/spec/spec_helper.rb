RSpec.configure do |config|
  if ENV["JUNIT_FORMATTER_FILE_PATH_PREFIX"]
    config.junit_formatter_file_path_prefix = ENV["JUNIT_FORMATTER_FILE_PATH_PREFIX"]
  end

  # register around filter that captures stderr and stdout
  config.around(:each) do |example|
    $stdout = StringIO.new
    $stderr = StringIO.new

    example.run

    example.metadata[:stdout] = $stdout.string
    example.metadata[:stderr] = $stderr.string

    $stdout = STDOUT
    $stderr = STDERR
  end
end

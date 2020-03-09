RSpec.configure do |config|
  # register around filter that captures stderr and stdout
  config.around(:each) do |example|
    $stdout = StringIO.new
    $stderr = StringIO.new

    example.run

    example.metadata[:stdout] = $stdout.string
    example.metadata[:stderr] = $stderr.string

    # register screenshots if failing test attached to it
    if example.metadata[:has_screenshots]
      example.metadata[:screenshot] = {
        html: "tmp/some/path.html",
        image: "tmp/some/path.png"
      }
    end

    $stdout = STDOUT
    $stderr = STDERR
  end
end

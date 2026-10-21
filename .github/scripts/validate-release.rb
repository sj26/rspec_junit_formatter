require "digest"
require "fileutils"
require "rubygems/package"
require "tmpdir"

spec = Gem::Specification.load("rspec_junit_formatter.gemspec")
abort "Unexpected gem name" unless spec.name == "rspec_junit_formatter"
version = spec.version.to_s
abort "Only stable X.Y.Z releases are supported" unless version.match?(/\A\d+\.\d+\.\d+\z/)
tag = ENV["RELEASE_TAG"]
abort "Tag and gem version differ" if tag && !tag.empty? && tag != "v#{version}"
abort "Actions releases must not embed signing certificates" unless spec.cert_chain.empty?
abort "Actions releases must not use a signing key" if spec.signing_key

FileUtils.mkdir_p("pkg")
file = File.expand_path("pkg/#{spec.full_name}.gem")
system("gem", "build", "rspec_junit_formatter.gemspec", "--output", file, exception: true)
package = Gem::Package.new(file)
package.verify
abort "Unexpected package metadata" unless package.spec.full_name == spec.full_name
abort "Signed package" unless package.spec.cert_chain.empty?
File.open(file, "rb") do |io|
  Gem::Package::TarReader.new(io) do |tar|
    abort "Embedded gem signature" if tar.any? { |entry| entry.full_name.end_with?(".sig") }
  end
end

# A fresh install outside the checkout catches omitted files and accidental
# reliance on Bundler's path source. Exercise both successful and failing output.
Dir.mktmpdir("installed-release-") do |dir|
  env = { "GEM_HOME" => "#{dir}/gems", "GEM_PATH" => "#{dir}/gems", "RUBYOPT" => nil,
          "BUNDLE_GEMFILE" => nil }
  system(env, "gem", "install", file, "--no-document", exception: true)
  system(env, "gem", "install", "rspec", "--version", "~> 3.13.0", "--no-document", exception: true)
  File.write("#{dir}/release_spec.rb", <<~RUBY)
    RSpec.describe "installed gem" do
      it("passes") { expect(2 + 2).to eq(4) }
      it("fails with XML characters") { expect("<actual>").to eq("&expected") }
      xit("is pending") {}
    end
  RUBY
  system(env, "#{dir}/gems/bin/rspec", "release_spec.rb", "--require", "rspec_junit_formatter",
         "--format", "RspecJunitFormatter", "--out", "result.xml", chdir: dir)
  abort "Expected one failing example" unless $?.exitstatus == 1
  # REXML is not bundled with every Ruby; use Python's standard XML parser.
  system("python3", "-c", <<~PYTHON, "#{dir}/result.xml", exception: true)
    import sys, xml.etree.ElementTree as ET
    suite = ET.parse(sys.argv[1]).getroot()
    assert suite.attrib['tests'] == '3', suite.attrib
    assert suite.attrib['failures'] == '1', suite.attrib
    assert suite.attrib['skipped'] == '1', suite.attrib
    assert len(suite.findall('testcase')) == 3
    failure = suite.find('testcase/failure')
    assert '<actual>' in failure.text and '&expected' in failure.text, failure.text
  PYTHON
end

digest = Digest::SHA256.file(file).hexdigest
puts "Validated #{File.basename(file)} SHA-256 #{digest}"
if ENV["GITHUB_OUTPUT"]
  File.open(ENV.fetch("GITHUB_OUTPUT"), "a") do |output|
    output.puts "version=#{version}", "sha256=#{digest}"
  end
end

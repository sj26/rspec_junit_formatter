# frozen_string_literal: true

require "nokogiri"
require "stringio"
require "rspec/core/sandbox"
require "rspec_junit_formatter"

# These specs drive RSpecJUnitFormatter directly, in-process, instead of
# shelling out to a real `rspec` process (see rspec_junit_formatter_spec.rb
# for that black-box, "does the released gem actually work" acceptance
# test). Running in-process means test coverage tools can see what
# actually executes, and lets us reach past the happy path into formatter
# internals -- forced color, malformed durations, older-RSpec fallbacks --
# that are impractical to trigger through the command-line interface.
RSpec.describe RSpecJUnitFormatter do
  # Runs a small example suite through the real RSpec::Core::Reporter /
  # formatter notification pipeline inside an RSpec::Core::Sandbox (an
  # isolated RSpec::Core::World + Configuration bundled with rspec-core
  # itself), so the formatter is exercised exactly as RSpec drives it.
  def run(seed: nil, forced_color_mode: nil)
    output = StringIO.new

    RSpec::Core::Sandbox.sandboxed do |config|
      config.output_stream = StringIO.new
      config.error_stream = StringIO.new
      # Force color on so failure diffs contain real ANSI escape codes,
      # exercising strip_diff_colors the same way --force-color does for
      # the acceptance spec.
      config.color_mode = :on
      config.force(color_mode: forced_color_mode) if forced_color_mode
      config.seed = seed if seed
      config.add_formatter(described_class, output)

      RSpec.shared_examples "shared examples" do
        context "when included via a shared example group" do
          it("succeeds") { expect(true).to be(true) }
          it("also fails") { expect(false).to be(true) }
        end
      end

      group = RSpec.describe("some example specs") do
        it("succeeds") { expect(true).to be(true) }
        it("fails") { expect(false).to be(true) }
        it("raises") { raise ArgumentError, "some error" }
        it("is pending") { skip "demonstrates a pending example" }
        it("shows diffs cleanly") { expect({ a: "b", c: "d" }).to eql({ a: 2, c: 4 }) }
        it("replaces naughty \0 and \e characters, \x01 and \uFFFF too") { expect("\0\0\0").to eql("emergency services") }
        it("escapes controlling \u{7f} characters") { expect("\u{7f}").to eql("pacman om nom nom") }
        it("can include unicodes \u{1f601}") { expect("\u{1f680}").to eql("\u{1f525}") }
        it(%(escapes <html tags='correctly' and="such &amp; such">)) { expect("<p>This is important</p>").to eql("<p>This is <strong>very</strong> important</p>") }

        it_behaves_like "shared examples"
        it("can capture stdout and stderr", stderr: "Bar\n", stdout: "Test\n") { expect(true).to be(true) }
      end

      config.reporter.report(group.examples.size) { |reporter| group.run(reporter) }
    end

    output.string
  end

  let(:xml) { run }
  let(:doc) { Nokogiri::XML::Document.parse(xml) }
  let(:testsuite) { doc.at_xpath("/testsuite") }
  let(:testcases) { doc.xpath("/testsuite/testcase") }

  it "describes the whole run" do
    expect(testsuite["tests"]).to eql("12")
    expect(testsuite["skipped"]).to eql("1")
    expect(testsuite["failures"]).to eql("8")
    expect(testsuite["errors"]).to eql("0")
    expect(testsuite["hostname"]).not_to be_empty
    expect(Time.parse(testsuite["timestamp"])).to be_within(60).of(Time.now)
    expect(testsuite["time"].to_f).to be > 0

    expect(testcases.size).to be(12)
    testcases.each do |testcase|
      expect(testcase["classname"]).to eql(testcases.first["classname"])
      expect(testcase["name"]).not_to be_empty
      expect(testcase["time"].to_f).to be > 0
    end

    successful = doc.xpath("/testsuite/testcase[not(failure) and not(skipped)]")
    expect(successful.size).to be(3)

    pending = doc.xpath("/testsuite/testcase[skipped]")
    expect(pending.size).to be(1)
    expect(pending.first.element_children.first.name).to eql("skipped")

    failed = doc.xpath("/testsuite/testcase[failure]")
    expect(failed.size).to be(8)
    failed.each do |testcase|
      failure = testcase.element_children.first
      expect(failure.name).to eql("failure")
      expect(failure["message"]).not_to be_empty
      expect(failure.text.strip).not_to be_empty
      expect(failure.text.strip).not_to match(/\\e\[(?:\d+;?)+m/)
      expect(failure.text.strip).not_to match(/\e\[(?:\d+;?)+m/)
    end

    expect(doc.xpath("//testcase[contains(@name, 'naughty')]").first["name"]).to eql("some example specs replaces naughty \\0 and \\e characters, \\x01 and \\uFFFF too")
    expect(doc.xpath("//testcase[contains(@name, 'controlling')]").first["name"]).to eql("some example specs escapes controlling \u{7f} characters")
    expect(doc.xpath("//testcase[contains(@name, 'unicodes')]").first["name"]).to eql("some example specs can include unicodes \u{1f601}")
    expect(doc.xpath("//testcase[contains(@name, 'html')]").first["name"]).to eql(%(some example specs escapes <html tags='correctly' and="such &amp; such">))

    expect(doc.xpath("//testcase/system-out").text).to eql("Test\n")
    expect(doc.xpath("//testcase/system-err").text).to eql("Bar\n")

    shared = doc.xpath("//testcase[contains(@name, 'shared example')]")
    expect(shared.size).to be(2)
    shared.each { |testcase| expect(testcase["classname"]).to eql(testcases.first["classname"]) }

    failed_shared = doc.xpath("//testcase[contains(@name, 'shared example')][failure]")
    expect(failed_shared.size).to be(1)
    expect(failed_shared.first.text).to include("Shared Example Group")
    expect(failed_shared.first.text).to include("formatter_spec.rb")
  end

  context "when $TEST_ENV_NUMBER is set" do
    around do |example|
      ENV["TEST_ENV_NUMBER"] = "42"
      example.run
    ensure
      ENV.delete("TEST_ENV_NUMBER")
    end

    it "includes $TEST_ENV_NUMBER in the testsuite name" do
      expect(testsuite["name"]).to eql("rspec42")
    end
  end

  it "reports the configured seed as a property" do
    doc = Nokogiri::XML::Document.parse(run(seed: 12_345))
    property = doc.at_xpath("/testsuite/properties/property[@name='seed']")
    expect(property["value"]).to eql("12345")
  end

  it "still turns off color when it was forced on via the command line" do
    doc = Nokogiri::XML::Document.parse(run(forced_color_mode: :on))
    failure = doc.at_xpath("//testcase[failure]/failure")
    expect(failure.text).not_to match(/\e\[(?:\d+;?)+m/)
  end

  describe "#escape (private)" do
    let(:formatter) { described_class.new(StringIO.new) }

    it "replaces illegal low-codepoint characters with a Ruby-like backslash escape" do
      expect(formatter.send(:escape, "\0")).to eql("\\0")
      expect(formatter.send(:escape, "\a\b\f\v\e")).to eql("\\a\\b\\f\\v\\e")
      expect(formatter.send(:escape, "\x01")).to eql("\\x01")
    end

    it "replaces illegal high-codepoint characters with a Ruby-like unicode escape" do
      expect(formatter.send(:escape, "\uFFFF")).to eql("\\uFFFF")
    end

    it "replaces discouraged XML-reserved characters with entities" do
      expect(formatter.send(:escape, %(<>&"'))).to eql("&lt;&gt;&amp;&quot;&apos;")
    end

    it "replaces other discouraged characters with a generic hex entity" do
      expect(formatter.send(:escape, "\u{7f}")).to eql("&#x7f;")
    end
  end

  describe "#error_count (private)" do
    it "falls back to 0 for summary notifications without errors_outside_of_examples_count (rspec-core < 3.6)" do
      formatter = described_class.new(StringIO.new)
      formatter.instance_variable_set(:@summary_notification, Object.new)
      expect(formatter.send(:error_count)).to eq(0)
    end
  end

  describe "#xml_dump_example (private)" do
    it "omits the time attribute when an example has no duration" do
      fake_execution_result = Struct.new(:run_time).new(nil)
      fake_example = Struct.new(:execution_result, :metadata, :full_description).new(
        fake_execution_result,
        { example_group: { file_path: "./spec/fake_spec.rb", parent_example_group: nil } },
        "a fake example with no recorded duration"
      )
      fake_notification = Struct.new(:example).new(fake_example)

      formatter = described_class.new(StringIO.new)
      formatter.send(:xml_dump_example, fake_notification)

      expect(formatter.output.string).not_to match(/\btime="/)
      expect(formatter.output.string).to include(%(classname="spec.fake_spec"))
    end
  end
end

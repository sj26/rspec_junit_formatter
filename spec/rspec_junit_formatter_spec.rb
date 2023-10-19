require "pty"
require "stringio"
require "nokogiri"
require "rspec_junit_formatter"

describe RspecJunitFormatter do
  TMP_DIR = File.expand_path("../../tmp", __FILE__)
  EXAMPLE_DIR = File.expand_path("../../example", __FILE__)

  before(:all) { ENV.delete("TEST_ENV_NUMBER") } # Make sure this doesn't exist by default

  let(:formatter_output_path) { File.join(TMP_DIR, "junit.xml") }
  let(:formatter_output) { output; File.read(formatter_output_path) }

  let(:formatter_arguments) { ["--format", "RspecJunitFormatter", "--out", formatter_output_path] }
  let(:extra_arguments) { [] }

  let(:color_opt) do
    RSpec.configuration.respond_to?(:color_mode=) ? "--force-color" : "--color"
  end

  def safe_pty(command, **pty_options)
    output = StringIO.new

    PTY.spawn(*command, **pty_options) do |r, w, pid|
      begin
        r.each_line { |line| output.puts(line) }
      rescue Errno::EIO
        # Command closed output, or exited
      ensure
        Process.wait pid
      end
    end

    output.string
  end

  def execute_example_spec
    command = ["bundle", "exec", "rspec", *formatter_arguments, color_opt, *extra_arguments]

    safe_pty(command, chdir: EXAMPLE_DIR)
  end

  let(:output) { execute_example_spec }

  let(:doc) { Nokogiri::XML::Document.parse(formatter_output) }

  let(:testsuite) { doc.xpath("/testsuite").first }
  let(:testcases) { doc.xpath("/testsuite/testcase") }
  let(:successful_testcases) { doc.xpath("/testsuite/testcase[not(failure) and not(skipped)]") }
  let(:pending_testcases) { doc.xpath("/testsuite/testcase[skipped]") }
  let(:failed_testcases) { doc.xpath("/testsuite/testcase[failure]") }
  let(:shared_testcases) { doc.xpath("/testsuite/testcase[contains(@name, 'shared example')]") }
  let(:failed_shared_testcases) { doc.xpath("/testsuite/testcase[contains(@name, 'shared example')][failure]") }

  # Combined into a single example so we don't have to re-run the example rspec
  # process over and over. (We need to change the parameters in later specs so
  # we can't use before(:all).)
  #
  it "correctly describes the test results", aggregate_failures: true do
    # it has a testsuite

    expect(testsuite).not_to be(nil)

    expect(testsuite["name"]).to eql("rspec")
    expect(testsuite["tests"]).to eql("12")
    expect(testsuite["skipped"]).to eql("1")
    expect(testsuite["failures"]).to eql("8")
    expect(testsuite["errors"]).to eql("0")
    expect(Time.parse(testsuite["timestamp"])).to be_within(60).of(Time.now)
    expect(testsuite["time"].to_f).to be > 0
    expect(testsuite["hostname"]).not_to be_empty

    # it has some test cases

    expect(testcases.size).to eql(12)

    testcases.each do |testcase|
      expect(testcase["classname"]).to eql("spec.example_spec")
      expect(testcase["name"]).not_to be_empty
      expect(testcase["time"].to_f).to be > 0
    end

    # it has successful test cases

    expect(successful_testcases.size).to eql(3)

    successful_testcases.each do |testcase|
      expect(testcase).not_to be(nil)
      # test results that capture stdout / stderr are not 'empty'
      unless (testcase["name"]) =~ /capture stdout and stderr/
        expect(testcase.children).to be_empty
      end
    end

    # it has pending test cases

    expect(pending_testcases.size).to eql(1)

    pending_testcases.each do |testcase|
      expect(testcase.element_children.size).to eql(1)
      child = testcase.element_children.first
      expect(child.name).to eql("skipped")
      expect(child.attributes).to be_empty
      expect(child.text).to be_empty
    end

    # it has failed test cases

    expect(failed_testcases.size).to eql(8)

    failed_testcases.each do |testcase|
      expect(testcase).not_to be(nil)
      expect(testcase.element_children.size).to eql(1)

      child = testcase.element_children.first
      expect(child.name).to eql("failure")
      expect(child["message"]).not_to be_empty
      expect(child.text.strip).not_to be_empty
      expect(child.text.strip).not_to match(/\\e\[(?:\d+;?)+m/)
    end

    # it has shared test cases which list both the inclusion and included files

    expect(shared_testcases.size).to eql(2)
    shared_testcases.each do |testcase|
      # shared examples should be groups with their including files
      expect(testcase["classname"]).to eql("spec.example_spec")
    end

    expect(failed_shared_testcases.size).to eql(1)
    failed_shared_testcases.each do |testcase|
      expect(testcase.text).to include("example_spec.rb")
      expect(testcase.text).to include("shared_examples.rb")
    end

    # it cleans up diffs

    diff_testcase_failure = doc.xpath("//testcase[contains(@name, 'diffs')]/failure").first
    expect(diff_testcase_failure[:message]).not_to match(/\e | \\e/x)
    expect(diff_testcase_failure.text).not_to match(/\e | \\e/x)

    # it correctly replaces illegal characters

    expect(doc.xpath("//testcase[contains(@name, 'naughty')]").first[:name]).to eql("some example specs replaces naughty \\0 and \\e characters, \\x01 and \\uFFFF too, and ??invalid??")

    # it correctly escapes discouraged characters

    expect(doc.xpath("//testcase[contains(@name, 'controlling')]").first[:name]).to eql("some example specs escapes controlling \u{7f} characters")

    # it correctly escapes emoji characters

    expect(doc.xpath("//testcase[contains(@name, 'unicodes')]").first[:name]).to eql("some example specs can include unicodes \u{1f601}")

    # it correctly escapes reserved xml characters

    expect(doc.xpath("//testcase[contains(@name, 'html')]").first[:name]).to eql(%{some example specs escapes <html tags='correctly' and="such &amp; such">})

    # it correctly captures stdout / stderr output
    expect(doc.xpath("//testcase/system-out").text).to eql("Test\n")
    expect(doc.xpath("//testcase/system-err").text).to eql("Bar\n")
  end

  context "when $TEST_ENV_NUMBER is set" do
    around do |example|
      begin
        ENV["TEST_ENV_NUMBER"] = "42"
        example.call
      ensure
        ENV.delete("TEST_ENV_NUMBER")
      end
    end

    it "includes $TEST_ENV_NUMBER in the testsuite name" do
      expect(testsuite["name"]).to eql("rspec42")
    end
  end

  context "with a known rspec seed" do
    let(:extra_arguments) { ["--seed", "12345"] }

    let(:seed_property) { doc.xpath("/testsuite/properties/property[@name='seed']").first }

    it "has a property with seed info" do
      expect(seed_property["name"]).to eql("seed")
      expect(seed_property["value"]).to eql("12345")
    end
  end
end

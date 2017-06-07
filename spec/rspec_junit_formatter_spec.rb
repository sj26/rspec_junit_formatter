require "nokogiri"

require "rspec_junit_formatter"

describe RspecJunitFormatter do
  EXAMPLE_DIR = File.expand_path("../../example", __FILE__)

  before(:all) { ENV.delete("TEST_ENV_NUMBER") } # Make sure this doesn't exist by default
  let(:extra_arguments) { [] }
  subject(:output) { IO.popen(["bundle", "exec", "rspec", "--format", "RspecJunitFormatter", *extra_arguments], chdir: EXAMPLE_DIR, &:read) }

  let(:doc) { Nokogiri::XML::Document.parse(output) }

  let(:testsuite) { doc.xpath("/testsuite").first }
  let(:testcases) { doc.xpath("/testsuite/testcase") }
  let(:successful_testcases) { doc.xpath("/testsuite/testcase[count(*)=0]") }
  let(:pending_testcases) { doc.xpath("/testsuite/testcase[skipped]") }
  let(:failed_testcases) { doc.xpath("/testsuite/testcase[failure]") }

  # Combined into a single example so we don't have to re-run the example rspec
  # process over and over. (We need to change the parameters in later specs so
  # we can't use before(:all).)
  #
  it "correctly describes the test results", aggregate_failures: true do
    # it has a testsuite

    expect(testsuite).not_to be(nil)

    expect(testsuite["name"]).to eql("rspec")
    expect(testsuite["tests"]).to eql("7")
    expect(testsuite["failures"]).to eql("5")
    expect(testsuite["errors"]).to eql("0")
    expect(Time.parse(testsuite["timestamp"])).to be_within(60).of(Time.now)
    expect(testsuite["time"].to_f).to be > 0

    # it has some test cases

    expect(testcases.size).to eql(7)

    testcases.each do |testcase|
      expect(testcase["classname"]).not_to be_empty
      expect(testcase["name"]).not_to be_empty
      expect(testcase["time"].to_f).to be > 0
    end

    # it has a successful test case

    expect(successful_testcases.size).to eql(1)

    testcase = successful_testcases.first
    expect(testcase).not_to be(nil)
    expect(testcase.children).to be_empty

    # it has a pending test case

    expect(pending_testcases.size).to eql(1)

    testcase = pending_testcases.first
    expect(testcase).not_to be(nil)
    expect(testcase.element_children.size).to eql(1)

    child = testcase.element_children.first
    expect(child.name).to eql("skipped")
    expect(child.attributes).to be_empty
    expect(child.text).to be_empty

    # it has some failed test cases

    expect(failed_testcases.size).to eql(5)

    failed_testcases.each do |testcase|
      expect(testcase).not_to be(nil)
      expect(testcase.element_children.size).to eql(1)

      child = testcase.element_children.first
      expect(child.name).to eql("failure")
      expect(child["message"]).not_to be_empty
      expect(child.text.strip).not_to be_empty
    end

    # it correctly escapes invalid xml characters

    expect(output).to include("escapes naughty &#0; characters")

    # it correctly escapes reserved xml characters

    expect(output).to include("escapes &lt;html tags=&apos;correctly&apos; and=&quot;such &amp;amp; such&quot;&gt;")
  end

  context "when $TEST_ENV_NUMBER is set" do
    around do |example|
      begin
        ENV["TEST_ENV_NUMBER"] = "2"
        example.call
      ensure
        ENV.delete("TEST_ENV_NUMBER")
      end
    end

    it "includes $TEST_ENV_NUMBER in the testsuite name" do
      expect(testsuite["name"]).to eql("rspec2")
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

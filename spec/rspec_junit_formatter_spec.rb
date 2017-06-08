require "nokogiri"

require "rspec_junit_formatter"

describe RspecJunitFormatter do
  EXAMPLE_DIR = File.expand_path("../../example", __FILE__)

  let(:output_path) { File.join(EXAMPLE_DIR, "tmp/rspec.xml") }
  let(:output_xml) { IO.read(output_path) }
  let(:output_doc) { Nokogiri::XML::Document.parse(output_xml) }

  let(:root) { output_doc.xpath("/testsuite").first }
  let(:seed_comment) { output_doc.xpath("/testsuite/properties/property").first }
  let(:testcases) { output_doc.xpath("/testsuite/testcase") }
  let(:successful_testcases) { output_doc.xpath("/testsuite/testcase[count(*)=0]") }
  let(:pending_testcases) { output_doc.xpath("/testsuite/testcase[skipped]") }
  let(:failed_testcases) { output_doc.xpath("/testsuite/testcase[failure]") }
  let(:shared_example_testcases) { output_doc.xpath("/testsuite/testcase[contains(@name, 'shared example')]") }

  before(:all) do
    Dir.chdir EXAMPLE_DIR do
      ENV['TEST_ENV_NUMBER'] = '2'
      system "bundle", "exec", "rspec"
    end
  end

  it "has a root testsuite" do
    expect(root).not_to be_nil

    expect(root.name).to eq "testsuite"

    expect(root["name"]).to eq "rspec2"
    expect(root["tests"]).to eq "5"
    expect(root["failures"]).to eq "2"
    expect(root["errors"]).to eq "0"
    expect(Time.parse(root["timestamp"])).to be_within(60).of(Time.now)
    expect(root["time"].to_f).to be > 0
  end

  it "has some test cases" do
    expect(testcases.size).to eq 5

    testcases.each do |testcase|
      expect(testcase["classname"]).not_to be_empty
      expect(testcase["name"]).not_to be_empty
      expect(testcase["time"].to_f).to be > 0
    end
  end

  it "has some successful test cases" do
    expect(successful_testcases.size).to be 2

    successful_testcases.each do |testcase|
      expect(testcase).not_to be_nil
      expect(testcase.children).to be_empty
    end
  end

  it "has a pending test case" do
    expect(pending_testcases.size).to be 1

    testcase = pending_testcases.first
    expect(testcase).not_to be_nil
    expect(testcase.element_children.size).to eq 1

    child = testcase.element_children.first
    expect(child.name).to eq "skipped"
    expect(child.attributes).to be_empty
    expect(child.text).to be_empty
  end

  it "has some failed test cases" do
    expect(failed_testcases.size).to be 2

    failed_testcases.each do |testcase|
      expect(testcase).not_to be_nil
      expect(testcase.element_children.size).to eq 1

      child = testcase.element_children.first
      expect(child.name).to eq "failure"
      expect(child["message"]).not_to be_empty
      expect(child.text.strip).not_to be_empty
    end
  end

  context "shared examples" do
    it "attributes the example to the top level example group" do
      expect(shared_example_testcases.size).to be 1

      testcase = shared_example_testcases.first
      expect(testcase["file"]).to match /spec\/example_spec\.rb/
    end
  end

  it "has a comment with seed info" do
    expect(seed_comment['name']).to eq 'seed'
    expect(seed_comment['value']).to match /\d+/
  end
end

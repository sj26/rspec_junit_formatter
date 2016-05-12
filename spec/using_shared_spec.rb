require "nokogiri"

require "rspec_junit_formatter"

describe "Shared spec" do
  EXAMPLE_WITH_SHARED_DIR = File.expand_path("../../example_with_shared", __FILE__)

  let(:output_path) { File.join(EXAMPLE_WITH_SHARED_DIR , "tmp/rspec.xml") }
  let(:output_xml) { IO.read(output_path) }
  let(:output_doc) { Nokogiri::XML::Document.parse(output_xml) }

  let(:root) { output_doc.xpath("/testsuite").first }
  let(:testcases) { output_doc.xpath("/testsuite/testcase") }
  let(:failed_testcases) { output_doc.xpath("/testsuite/testcase[failure]") }


  before(:all) do
    Dir.chdir EXAMPLE_WITH_SHARED_DIR  do
      system "bundle", "exec", "rspec", "spec/shared_including_spec.rb"
    end
  end

  it "failed test case includes reference to failure line and original including line when supported" do
    expect(failed_testcases.size).to be 1 # otherwise, we have to find the specific one in multiple, potentially random
    failure_element = failed_testcases.first.element_children.first
    expect(failure_element.text).to include("spec/shared.rb:5")
    if Gem::Version.new(RSpec::Core::Version::STRING) >= Gem::Version.new("3.2")
      expect(failure_element.text).to include("spec/shared_including_spec.rb:7")
    end
  end

end

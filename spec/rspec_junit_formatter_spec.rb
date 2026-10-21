require "pty"
require "stringio"
require "nokogiri"
require "rspec_junit_formatter"

describe RspecJunitFormatter do
  TMP_DIR = File.expand_path("../../tmp", __FILE__)
  EXAMPLE_DIR = File.expand_path("../../example", __FILE__)

  # Isolate the subprocess from worker labels inherited from the test runner's CI.
  let(:worker_environment) do
    %w[TEST_ENV_NUMBER GITLAB_CI CI_NODE_INDEX CIRCLE_NODE_INDEX
       SEMAPHORE_JOB_INDEX SEMAPHORE_CURRENT_THREAD BUILDKITE_PARALLEL_JOB
       SNAP_WORKER_INDEX BITBUCKET_PARALLEL_STEP].each_with_object({}) do |name, env|
      env[name] = nil
    end
  end
  let(:extra_environment) { {} }

  let(:formatter_output_path) { File.join(TMP_DIR, "junit.xml") }
  let(:formatter_output) { output; File.read(formatter_output_path) }

  let(:formatter_arguments) { ["--format", "RspecJunitFormatter", "--out", formatter_output_path] }
  let(:extra_arguments) { [] }

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
    command = [worker_environment.merge(extra_environment), "bundle", "exec", "rspec", *formatter_arguments, "--force-color", *extra_arguments]

    safe_pty(command, chdir: EXAMPLE_DIR)
  end

  let(:output) { execute_example_spec }

  let(:doc) { Nokogiri::XML::Document.parse(formatter_output) { |config| config.strict } }

  let(:testsuite) { doc.xpath("/testsuite").first }
  let(:testcases) { doc.xpath("/testsuite/testcase") }
  let(:successful_testcases) { doc.xpath("/testsuite/testcase[not(failure) and not(skipped)]") }
  let(:pending_testcases) { doc.xpath("/testsuite/testcase[skipped]") }
  let(:failed_testcases) { doc.xpath("/testsuite/testcase[failure]") }
  let(:shared_testcases) { doc.xpath("/testsuite/testcase[contains(@name, 'shared example')]") }
  let(:failed_shared_testcases) { doc.xpath("/testsuite/testcase[contains(@name, 'shared example')][failure]") }
  let(:failed_multiple_testcases) { doc.xpath("/testsuite/testcase[contains(@name, 'multiple')][failure]") }

  # Combined into a single example so we don't have to re-run the example rspec
  # process over and over. (We need to change the parameters in later specs so
  # we can't use before(:all).)
  #
  it "correctly describes the test results", aggregate_failures: true do
    # it has a testsuite

    expect(testsuite).not_to be(nil)

    expect(testsuite["name"]).to eql("rspec")
    expect(testsuite["tests"]).to eql("19")
    expect(testsuite["skipped"]).to eql("1")
    expect(testsuite["failures"]).to eql("15")
    expect(testsuite["errors"]).to eql("0")
    expect(Time.parse(testsuite["timestamp"])).to be_within(60).of(Time.now)
    expect(testsuite["time"].to_f).to be > 0
    expect(testsuite["hostname"]).not_to be_empty

    # it has some test cases

    expect(testcases.size).to eql(19)

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

    expect(failed_testcases.size).to eql(15)

    failed_testcases.each do |testcase|
      expect(testcase).not_to be(nil)
      expect(testcase.element_children.size).to eql(1)

      child = testcase.element_children.first
      expect(child.name).to eql("failure")
      expect(child["message"]).not_to be_empty
      expect(child.text.strip).not_to be_empty
      expect(child.text).not_to match(/ $/)
    end

    # it transcodes exception messages before stripping diff colors, preserving
    # legitimate ANSI codes and illegal XML characters as visible escapes

    {
      "invalid UTF-8" => "before\uFFFDafter\\0\\e[31mred\\e[0m",
      "binary" => "before\uFFFDafter",
      "ISO-8859-1" => "café",
      "UTF-16LE" => "café",
    }.each do |encoding, message|
      failure = doc.at_xpath("//testcase[contains(@name, 'reports #{encoding} exception messages')]/failure")
      expect(failure["type"]).to eql("RuntimeError")
      expect(failure["message"]).to eql(message)
      # RSpec replaces invalid bytes with '?' before supplying message_lines.
      expect(failure.text).to include(message.gsub("\uFFFD", "?"))
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

    # it has detail for an aggregate_failures example
    expect(failed_multiple_testcases.size).to eql(1)
    failed_multiple_testcases.each do |testcase|
      expect(testcase.text).to include("foo")
      expect(testcase.text).to include("bar")
    end

    whitespace_failure = doc.xpath("//testcase[contains(@name, 'raises a message with trailing spaces')]/failure").first
    expect(whitespace_failure.text).to match(/^ +first  value\n\n +second\n/)

    aggregate_whitespace_failure = doc.xpath("//testcase[contains(@name, 'aggregate messages with trailing spaces')]/failure").first
    expect(aggregate_whitespace_failure.text).to include("foo\n", "first\n")
    expect(aggregate_whitespace_failure.text).to include("bar\n", "second")

    # it cleans up diffs

    diff_testcase_failure = doc.xpath("//testcase[contains(@name, 'diffs')]/failure").first
    expect(diff_testcase_failure[:message]).not_to match(/\e | \\e/x)
    expect(diff_testcase_failure.text).not_to match(/\e | \\e/x)

    # it correctly replaces illegal characters

    expect(doc.xpath("//testcase[contains(@name, 'naughty')]").first[:name]).to eql("some example specs replaces naughty \\0 and \\e characters, \\x01 and \\uFFFF too, and \uFFFD")

    # it correctly escapes discouraged characters

    expect(doc.xpath("//testcase[contains(@name, 'controlling')]").first[:name]).to eql("some example specs escapes controlling \u{7f} characters")

    # it correctly escapes emoji characters

    expect(doc.xpath("//testcase[contains(@name, 'unicodes')]").first[:name]).to eql("some example specs can include unicodes \u{1f601}")

    # it correctly escapes reserved xml characters

    expect(doc.xpath("//testcase[contains(@name, 'html')]").first[:name]).to eql(%{some example specs escapes <html tags='correctly' and="such &amp; such">})

    # it correctly captures stdout / stderr output
    expect(doc.xpath("//testcase/system-out").text).to eql("Test \uFFFD\\0\\e\n")
    expect(doc.xpath("//testcase/system-err").text).to eql("Bar é\n")
  end

  context "with parallel worker labels" do
    {
      "CI_NODE_INDEX" => ["1", "rspec1", "8", "rspec8"],
      "CIRCLE_NODE_INDEX" => ["0", "rspec0", "3", "rspec3"],
      "SEMAPHORE_JOB_INDEX" => ["1", "rspec1", "6", "rspec6"],
      "BUILDKITE_PARALLEL_JOB" => ["0", "rspec0", "2", "rspec2"],
      "BITBUCKET_PARALLEL_STEP" => ["0", "rspec0", "9", "rspec9"],
    }.each do |variable, values|
      values.each_slice(2) do |value, name|
        context "with #{variable}=#{value}" do
          let(:extra_environment) { {variable => value} }

          it "uses the native index in the XML suite name" do
            expect(testsuite["name"]).to eql(name)
          end
        end
      end
    end

    context "on GitLab" do
      let(:extra_environment) { {"GITLAB_CI" => "true", "CI_NODE_INDEX" => "1"} }

      it "does not convert the first job's label into a zero-based shard index" do
        expect(testsuite["name"]).to eql("rspec1")
      end
    end

    context "with multiple CI labels" do
      let(:worker_environment) do
        super().merge(
          "CI_NODE_INDEX" => "8", "CIRCLE_NODE_INDEX" => "3",
          "SEMAPHORE_JOB_INDEX" => "6", "BUILDKITE_PARALLEL_JOB" => "2",
          "BITBUCKET_PARALLEL_STEP" => "9"
        )
      end

      [
        [{}, "rspec8"],
        [{"CI_NODE_INDEX" => ""}, "rspec3"],
        [{"CI_NODE_INDEX" => nil, "CIRCLE_NODE_INDEX" => ""}, "rspec6"],
        [{"CI_NODE_INDEX" => "", "CIRCLE_NODE_INDEX" => nil, "SEMAPHORE_JOB_INDEX" => ""}, "rspec2"],
        [{"CI_NODE_INDEX" => nil, "CIRCLE_NODE_INDEX" => "", "SEMAPHORE_JOB_INDEX" => nil, "BUILDKITE_PARALLEL_JOB" => ""}, "rspec9"],
        [{"CI_NODE_INDEX" => "0"}, "rspec0"],
        [{"TEST_ENV_NUMBER" => "42"}, "rspec42"],
        [{"TEST_ENV_NUMBER" => ""}, "rspec"],
        [{"TEST_ENV_NUMBER" => "0"}, "rspec0"],
        [{"TEST_ENV_NUMBER" => "node-8-worker-2<&\""}, "rspecnode-8-worker-2<&\""],
      ].each do |environment, name|
        context "with overrides #{environment.inspect}" do
          let(:extra_environment) { environment }

          it "honors the documented precedence and preserves explicit overrides" do
            expect(testsuite["name"]).to eql(name)
          end
        end
      end
    end

    context "with empty CI labels and obsolete providers" do
      let(:extra_environment) do
        {
          "CI_NODE_INDEX" => "", "CIRCLE_NODE_INDEX" => "",
          "SEMAPHORE_JOB_INDEX" => "", "BUILDKITE_PARALLEL_JOB" => "",
          "BITBUCKET_PARALLEL_STEP" => "",
          "SEMAPHORE_CURRENT_THREAD" => "4", "SNAP_WORKER_INDEX" => "7"
        }
      end

      it "keeps the unsuffixed name rather than inventing a worker index" do
        expect(testsuite["name"]).to eql("rspec")
      end
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

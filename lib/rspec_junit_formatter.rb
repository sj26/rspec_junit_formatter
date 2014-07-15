require "time"

require "builder"
require "rspec"

require "rspec/core/formatters/base_formatter"

# Dumps rspec results as a JUnit XML file.
# Based on XML schema: http://windyroad.org/dl/Open%20Source/JUnit.xsd
class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  # rspec 2 and 3 implements are in separate files.

private

  def xml
    @xml ||= Builder::XmlMarkup.new target: output, indent: 2
  end

  def xml_dump
    xml.instruct!
    xml.testsuites do
      xml.testsuite name: "rspec", tests: example_count, failures: failure_count, errors: 0, time: "%.6f" % duration, timestamp: started.iso8601 do
        xml.properties
        xml_dump_suites
      end
    end
  end

  def xml_dump_suites
    current_suite = nil
    current_examples = []
    examples.each do |example|
      current_suite ||= suite_name example
      if current_suite != suite_name(example)
        xml_dump_suite(current_examples, current_suite)

        current_examples = []
        current_suite = suite_name example

      end
      current_examples << example
    end
    xml_dump_suite(current_examples, current_suite)

  end

  def xml_dump_suite suite_examples, suite
    return unless (suite_examples.length > 0)
    xml.testsuite name: suite, tests: suite_examples.length do
        xml_dump_examples suite_examples
    end
  end

  def xml_dump_examples suite_examples
    suite_examples.each do |example|
      send :"xml_dump_#{result_of(example)}", example
    end
  end


  def xml_dump_passed(example)
    xml_dump_example(example)
  end

  def xml_dump_pending(example)
    xml_dump_example(example) do
      xml.skipped
    end
  end

  def xml_dump_failed(example)
    exception = exception_for(example)
    backtrace = formatted_backtrace_for(example)

    xml_dump_example(example) do
      xml.failure message: exception.to_s, type: exception.class.name do
        xml.cdata! "#{exception.message}\n#{backtrace.join "\n"}"
      end
    end
  end

  def xml_dump_example(example, &block)
    xml.testcase classname: classname_for(example), name: description_for(example), time: "%.6f" % duration_for(example), &block
  end
end

RspecJunitFormatter = RSpecJUnitFormatter

if RSpec::Version::STRING.start_with? "3."
  require "rspec_junit_formatter/rspec3"
else RSpec::Version::STRING.start_with? "2."
  require "rspec_junit_formatter/rspec2"
end

require "time"

require "builder"
require "rspec"

require "rspec/core/formatters/base_formatter"

# Dumps rspec results as a JUnit XML file.
# Based on XML schema: http://windyroad.org/dl/Open%20Source/JUnit.xsd
class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  attr_reader :started

  # rspec 2 and 3 implements are in separate files.

private

  def xml
    @xml ||= Builder::XmlMarkup.new :target => output, :indent => 2
  end

  def xml_dump
    xml.instruct!
    xml.testsuite :name => "rspec", :tests => example_count, :failures => failure_count, :errors => 0, :time => "%.6f" % duration, :timestamp => started.iso8601 do
      xml.properties
      examples.each do |example|
        send :"xml_dump_#{example.execution_result[:status]}", example
      end
    end
  end

  def xml_dump_passed(example)
    xml_dump_example example
  end

  def xml_dump_pending(example)
    xml_dump_example example do
      xml.skipped
    end
  end

  def xml_dump_failed(example)
    exception = example.execution_result[:exception]
    backtrace = format_backtrace exception.backtrace, example

    xml_dump_example example do
      xml.failure :message => exception.to_s, :type => exception.class.name do
        xml.cdata! "#{exception.message}\n#{backtrace.join "\n"}"
      end
    end
  end

  def xml_dump_example(example, &block)
    xml.testcase :classname => example_classname(example), :name => example.full_description, :time => "%.6f" % example.execution_result[:run_time], &block
  end

  def example_classname(example)
    example.file_path.sub(%r{\.[^/]*\Z}, "").gsub("/", ".").gsub(%r{\A\.+|\.+\Z}, "")
  end
end

RspecJunitFormatter = RSpecJUnitFormatter

if RSpec::Version::STRING.start_with? "2."
  require "rspec_junit_formatter/rspec2"
end

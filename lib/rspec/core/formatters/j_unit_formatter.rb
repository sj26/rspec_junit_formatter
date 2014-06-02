require 'time'

# Dumps rspec results as a JUnit XML file.
# Based on XML schema: http://windyroad.org/dl/Open%20Source/JUnit.xsd
class RSpec::Core::Formatters::JUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self,
    :start, :example_passed, :example_pending, :example_failed, :dump_summary,
    :close

  def xml
    @xml ||= Builder::XmlMarkup.new :target => output, :indent => 2
  end

  def initialize(output)
    super
    @example_notifications = []
  end

  def start(notification)
    @start = Time.now
    super
  end

  def example_passed(notification)
    @example_notifications << notification
  end

  def example_pending(notification)
    @example_notifications << notification
  end

  def example_failed(notification)
    @example_notifications << notification
  end

  def dump_summary(summary)
    xml.instruct!
    xml.testsuite :tests => summary.example_count, :failures => summary.failure_count, :errors => 0, :time => '%.6f' % summary.duration, :timestamp => @start.iso8601 do
      xml.properties
      @example_notifications.each do |notification|
        send :"dump_summary_example_#{notification.example.execution_result[:status]}", notification
      end
    end
  end

  def xml_example example, &block
    xml.testcase :classname => example_classname(example), :name => example.full_description, :time => '%.6f' % example.execution_result[:run_time], &block
  end

  def dump_summary_example_passed(notification)
    xml_example notification.example
  end

  def dump_summary_example_pending(notification)
    xml_example notification.example do
      xml.skipped
    end
  end

  def dump_summary_example_failed(notification)
    exception = notification.exception
    backtrace = notification.formatted_backtrace

    xml_example notification.example do
      xml.failure :message => exception.to_s, :type => exception.class.name do
        xml.cdata! "#{exception.message}\n#{backtrace.join "\n"}"
      end
    end
  end

  def example_classname example
    example.file_path.sub(%r{\.[^/]*\Z}, "").gsub("/", ".").gsub(%r{\A\.+|\.+\Z}, "")
  end
end

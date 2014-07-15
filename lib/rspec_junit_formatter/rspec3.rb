class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self,
    :start,
    :stop,
    :dump_summary

  def start(notification)
    @start_notification = notification
    @started = Time.now
    super
  end

  def stop(notification)
    @examples_notification = notification
  end

  def dump_summary(notification)
    @summary_notification = notification
    xml_dump
  end

private

  attr_reader :started

  def suite_name notification
    notification.example.full_description.gsub(notification.example.description, "").strip
  end

  def example_count
    @summary_notification.examples.count
  end

  def failure_count
    @summary_notification.failed_examples.count
  end

  def duration
    @summary_notification.duration
  end

  def examples
    @examples_notification.notifications
  end

  def result_of(notification)
    notification.example.execution_result.status
  end

  def classname_for(notification)
    notification.example.file_path.sub(%r{\.[^/]*\Z}, "").gsub("/", ".").gsub(%r{\A\.+|\.+\Z}, "")
  end

  def duration_for(notification)
    notification.example.execution_result.run_time
  end

  def description_for(notification)
    notification.example.description
  end

  def exception_for(notification)
    notification.example.execution_result.exception
  end

  def formatted_backtrace_for(notification)
    backtrace = notification.formatted_backtrace
  end
end
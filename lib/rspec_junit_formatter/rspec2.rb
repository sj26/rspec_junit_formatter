class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  attr_reader :started

  def start(example_count)
    @started = Time.now
    super
  end

  def dump_summary(duration, example_count, failure_count, pending_count)
    super
    xml_dump
  end

private

  def suite_name example
    example.full_description.gsub(example.description, "").strip
  end

  def result_of(example)
    example.execution_result[:status]
  end

  def classname_for(example)
    example.file_path.sub(%r{\.[^/.]+\Z}, "").gsub("/", ".").gsub(/\A\.+|\.+\Z/, "")
  end

  def duration_for(example)
    example.execution_result[:run_time]
  end

  def description_for(example)
    example.description
  end

  def exception_for(example)
    example.execution_result[:exception]
  end

  def formatted_backtrace_for(example)
    format_backtrace exception_for(example).backtrace, example
  end
end

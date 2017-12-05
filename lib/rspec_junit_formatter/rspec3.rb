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
    without_color { xml_dump }
  end

private

  attr_reader :started

  def example_count
    @summary_notification.example_count
  end

  def pending_count
    @summary_notification.pending_count
  end

  def failure_count
    @summary_notification.failure_count
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

  def example_group_file_path_for(notification)
    metadata = notification.example.metadata[:example_group]
    while parent_metadata = metadata[:parent_example_group]
      metadata = parent_metadata
    end
    metadata[:file_path]
  end

  def classname_for(notification)
    fp = example_group_file_path_for(notification)
    fp.sub(%r{\.[^/]*\Z}, "").gsub("/", ".").gsub(%r{\A\.+|\.+\Z}, "")
  end

  def duration_for(notification)
    notification.example.execution_result.run_time
  end

  def description_for(notification)
    notification.example.full_description
  end

  def failure_type_for(example)
    exception_for(example).class.name
  end

  def failure_message_for(example)
    strip_diff_colors(exception_for(example).to_s)
  end

  def failure_for(notification)
    strip_diff_colors(notification.message_lines.join("\n")) << "\n" << notification.formatted_backtrace.join("\n")
  end

  def exception_for(notification)
    notification.example.execution_result.exception
  end

  STRIP_DIFF_COLORS_BLOCK_REGEXP = /^ ( [ ]* ) Diff: \e\[0m (?: \n \1 \e\[0m .* )* /x
  STRIP_DIFF_COLORS_CODES_REGEXP = /\e\[\d+m/

  def strip_diff_colors(string)
    # XXX: RSpec diffs are appended to the message lines fairly early and will
    # contain ANSI escape codes for colorizing terminal output if the global
    # rspec configuration is turned on, regardless of which notification lines
    # we ask for. We need to strip the codes from the diff part of the message
    # for XML output here.
    #
    # We also only want to target the diff hunks because the failure message
    # itself might legitimately contain ansi escape codes.
    #
    string.sub(STRIP_DIFF_COLORS_BLOCK_REGEXP) { |match| match.gsub(STRIP_DIFF_COLORS_CODES_REGEXP, "".freeze) }
  end

  # Completely gross hack for forcing off colorising
  def __without_color
    unset = Object.new
    force = RSpec.configuration.send(:value_for, WITHOUT_COLOR_KEY) { unset }
    if unset.equal?(force)
      previous = RSpec.configuration.send(WITHOUT_COLOR_KEY)
      RSpec.configuration.send(:"#{WITHOUT_COLOR_KEY}=", WITHOUT_COLOR_VALUE)
    else
      RSpec.configuration.force({WITHOUT_COLOR_KEY => WITHOUT_COLOR_VALUE})
    end
    yield
  ensure
    if unset.equal?(force)
      RSpec.configuration.send(:"#{WITHOUT_COLOR_KEY}=", previous)
    else
      RSpec.configuration.force({WITHOUT_COLOR_KEY => force})
    end
  end
  if RSpec.configuration.respond_to?(:color_mode=)
    WITHOUT_COLOR_KEY = :color_mode
    WITHOUT_COLOR_VALUE = :off
    alias_method :without_color, :__without_color
  elsif RSpec.configuration.respond_to?(:color=)
    WITHOUT_COLOR_KEY = :color
    WITHOUT_COLOR_VALUE = false
    alias_method :without_color, :__without_color
  else
    warn 'rspec_junit_formatter cannot prevent colorising due to an unexpected RSpec.configuration format'
    def without_color; yield; end
  end
end

# rspec-core 3.0.x forgot to mark this as a module function which causes:
#
#   NoMethodError: undefined method `wrap' for RSpec::Core::Notifications::NullColorizer:Class
#     .../rspec-core-3.0.4/lib/rspec/core/notifications.rb:229:in `add_shared_group_line'
#     .../rspec-core-3.0.4/lib/rspec/core/notifications.rb:157:in `message_lines'
#
if defined?(RSpec::Core::Notifications::NullColorizer) && RSpec::Core::Notifications::NullColorizer.is_a?(Class) && !RSpec::Core::Notifications::NullColorizer.respond_to?(:wrap)
  RSpec::Core::Notifications::NullColorizer.class_eval do
    def self.wrap(*args)
      new.wrap(*args)
    end
  end
end

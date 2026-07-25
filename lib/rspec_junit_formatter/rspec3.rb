# frozen_string_literal: true

# Reopens the class documented in lib/rspec_junit_formatter.rb to add the
# RSpec 3 formatter notification API glue.
class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  # Subscribe to the RSpec 3 formatter notifications this class needs. RSpec
  # only calls the methods listed here; anything else defined below is an
  # internal helper.
  RSpec::Core::Formatters.register self,
                                   :start,
                                   :stop,
                                   :dump_summary

  # @api public
  # Called once, before any examples run. Records the start time (used for
  # both the total duration and the report's timestamp attribute).
  # @param notification [RSpec::Core::Notifications::StartNotification]
  def start(notification)
    @start_notification = notification
    @started = Time.now
    super
  end

  # @api public
  # Called once, after all examples have run, with every example's result.
  # @param notification [RSpec::Core::Notifications::ExamplesNotification]
  def stop(notification)
    @examples_notification = notification
  end

  # @api public
  # Called once, after {#stop}, with the run's aggregate statistics. This
  # is where the XML report is actually written to {#output}.
  # @param notification [RSpec::Core::Notifications::SummaryNotification]
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

  def error_count
    # Introduced in rspec 3.6
    if @summary_notification.respond_to?(:errors_outside_of_examples_count)
      @summary_notification.errors_outside_of_examples_count
    else
      0
    end
  end

  def result_of(notification)
    notification.example.execution_result.status
  end

  # Walks up nested example groups (including shared example groups pulled
  # in via `it_behaves_like`) to the outermost, top-level group, so
  # classname_for reports one classname per spec file rather than one per
  # nested context.
  def example_group_file_path_for(notification)
    metadata = notification.example.metadata[:example_group]
    while (parent_metadata = metadata[:parent_example_group])
      metadata = parent_metadata
    end
    metadata[:file_path]
  end

  def classname_for(notification)
    fp = example_group_file_path_for(notification)
    fp.sub(%r{\.[^/]*\Z}, "").gsub("/", ".").gsub(/\A\.+|\.+\Z/, "")
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

  # rspec makes it really difficult to swap in configuration temporarily due to
  # the way it cascades defaults, command line arguments, and user
  # configuration. This method makes sure configuration gets swapped in
  # correctly, but also that the original state is definitely restored.
  def swap_rspec_configuration(key, value)
    unset = Object.new
    force = RSpec.configuration.send(:value_for, key) { unset }
    if unset.equal?(force)
      previous = RSpec.configuration.send(key)
      RSpec.configuration.send(:"#{key}=", value)
    else
      RSpec.configuration.force({ key => value })
    end
    yield
  ensure
    if unset.equal?(force)
      RSpec.configuration.send(:"#{key}=", previous)
    else
      RSpec.configuration.force({ key => force })
    end
  end

  # Forces off colorising for the duration of a block, so that ANSI escape
  # codes never leak into the XML output.
  def without_color(&)
    swap_rspec_configuration(:color_mode, :off, &)
  end

  def stdout_for(example_notification)
    example_notification.example.metadata[:stdout]
  end

  def stderr_for(example_notification)
    example_notification.example.metadata[:stderr]
  end
end

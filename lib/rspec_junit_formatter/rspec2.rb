class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  def start(example_count)
    @started = Time.now
    super
  end

  def dump_summary(duration, example_count, failure_count, pending_count)
    super
    xml_dump
  end
end

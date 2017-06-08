require "time"

require "rspec/core"
require "rspec/core/formatters/base_formatter"

# Dumps rspec results as a JUnit XML file.
# Based on XML schema: http://windyroad.org/dl/Open%20Source/JUnit.xsd
class RSpecJUnitFormatter < RSpec::Core::Formatters::BaseFormatter
  # rspec 2 and 3 implements are in separate files.

private

  def xml_dump
    output << %{<?xml version="1.0" encoding="UTF-8"?>\n}
    output << %{<testsuite}
    output << %{ name="rspec#{escape(ENV["TEST_ENV_NUMBER"].to_s)}"}
    output << %{ tests="#{example_count}"}
    output << %{ failures="#{failure_count}"}
    output << %{ errors="0"}
    output << %{ time="#{escape("%.6f" % duration)}"}
    output << %{ timestamp="#{escape(started.iso8601)}"}
    output << %{>\n}
    output << %{<properties>\n}
    output << %{<property}
    output << %{ name="seed"}
    output << %{ value="#{escape(RSpec.configuration.seed.to_s)}"}
    output << %{/>\n}
    output << %{</properties>\n}
    xml_dump_examples
    output << %{</testsuite>\n}
  end

  def xml_dump_examples
    examples.each do |example|
      send :"xml_dump_#{result_of(example)}", example
    end
  end

  def xml_dump_passed(example)
    xml_dump_example(example)
  end

  def xml_dump_pending(example)
    xml_dump_example(example) do
      output << %{<skipped/>}
    end
  end

  def xml_dump_failed(example)
    exception = exception_for(example)

    xml_dump_example(example) do
      output << %{<failure}
      output << %{ message="#{escape(exception.to_s)}"}
      output << %{ type="#{escape(exception.class.name)}"}
      output << %{>}
      output << escape(failure_for(example))
      output << %{</failure>}
    end
  end

  def xml_dump_example(example)
    output << %{<testcase}
    output << %{ classname="#{escape(classname_for(example))}"}
    output << %{ name="#{escape(description_for(example))}"}
    output << %{ file="#{escape(example_group_file_path_for(example))}"}
    output << %{ time="#{escape("%.6f" % duration_for(example))}"}
    output << %{>}
    yield if block_given?
    output << %{</testcase>\n}
  end

  # Based on valid characters allowed in XML unescaped, with restricted and
  # discouraged characters removed
  #
  # See https://www.w3.org/TR/xml/#dt-chardata
  ESCAPE_REGEXP = Regexp.new(
    "[^" <<
    "\u{9}" << # => \t
    "\u{a}" << # =>\n
    "\u{d}" << # => \r
    "\u{20}-\u{21}" <<
    # "\u{22}" << # => "
    "\u{23}-\u{25}" <<
    # "\u{26}" << # => &
    # "\u{27}" << # => '
    "\u{28}-\u{3b}" <<
    # "\u{3c}" << # => <
    "\u{3d}" <<
    # "\u{3e}" << # => >
    "\u{3f}-\u{7e}" <<
    # "\u{7f}-\u{84}" << # discouraged control characters
    "\u{85}" <<
    # "\u{86}-\u{9f}" << # discouraged control characters
    "\u{a0}-\u{d7ff}" <<
    "\u{e000}-\u{ffcf}" <<
    # "\u{ffd0}-\u{fdef}" <<
    "\u{fdf0}-\u{fffd}" <<
    # things get murky from here, just escape anything with a higher codepoint
    # "\u{10000}-\u{10ffff}" <<
    "]"
  )

  # Translate well-known entities, or use generic unicode hex entity
  ESCAPE_ENTITY = Hash.new { |_, c| "&#x#{c.ord.to_s(16)};".freeze }.update(
    ?" => "&quot;".freeze,
    ?& => "&amp;".freeze,
    ?' => "&apos;".freeze,
    ?< => "&lt;".freeze,
    ?> => "&gt;".freeze,
  ).freeze

  def escape(text)
    # Make sure it's utf-8 (this will throw errors for bad output, but that
    # seems okay) and replace invalid xml characters with entities
    text.to_s.encode(Encoding::UTF_8).gsub(ESCAPE_REGEXP, ESCAPE_ENTITY)
  end
end

RspecJunitFormatter = RSpecJUnitFormatter

if RSpec::Core::Version::STRING.start_with? "2."
  require "rspec_junit_formatter/rspec2"
else
  require "rspec_junit_formatter/rspec3"
end

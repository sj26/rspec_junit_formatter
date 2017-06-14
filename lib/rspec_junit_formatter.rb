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

  # Inversion of character range from https://www.w3.org/TR/xml/#charsets
  ILLEGAL_REGEXP = Regexp.new(
    "[^" <<
    "\u{9}" << # => \t
    "\u{a}" << # =>\n
    "\u{d}" << # => \r
    "\u{20}-\u{d7ff}" <<
    "\u{28}-\u{3b}" <<
    "\u{3d}" <<
    "\u{e000}-\u{fffd}" <<
    "\u{10000}-\u{10ffff}" <<
    "]"
  )

  # Discouraged characters from https://www.w3.org/TR/xml/#charsets
  # Plus special characters with well-known entity replacements
  ESCAPE_REGEXP = Regexp.new(
    "[" <<
    "\u{22}" << # => "
    "\u{26}" << # => &
    "\u{27}" << # => '
    "\u{3c}" << # => <
    "\u{3e}" << # => >
    "\u{7f}-\u{84}" <<
    "\u{86}-\u{9f}" <<
    "\u{fdd0}-\u{fdef}" <<
    "\u{1fffe}-\u{1ffff}" <<
    "\u{2fffe}-\u{2ffff}" <<
    "\u{3fffe}-\u{3ffff}" <<
    "\u{4fffe}-\u{4ffff}" <<
    "\u{5fffe}-\u{5ffff}" <<
    "\u{6fffe}-\u{6ffff}" <<
    "\u{7fffe}-\u{7ffff}" <<
    "\u{8fffe}-\u{8ffff}" <<
    "\u{9fffe}-\u{9ffff}" <<
    "\u{afffe}-\u{affff}" <<
    "\u{bfffe}-\u{bffff}" <<
    "\u{cfffe}-\u{cffff}" <<
    "\u{dfffe}-\u{dffff}" <<
    "\u{efffe}-\u{effff}" <<
    "\u{ffffe}-\u{fffff}" <<
    "\u{10fffe}-\u{10ffff}" <<
    "]"
  )

  # Translate well-known entities, or use generic unicode hex entity
  ESCAPE_REPLACEMENTS = Hash.new { |_, c| "&#x#{c.ord.to_s(16)};".freeze }.update(
    ?" => "&quot;".freeze,
    ?& => "&amp;".freeze,
    ?' => "&apos;".freeze,
    ?< => "&lt;".freeze,
    ?> => "&gt;".freeze,
  ).freeze

  def escape(text)
    # Make sure it's utf-8, omit illegal characters, and replace special and discouraged characters with entities
    text.to_s.encode(Encoding::UTF_8).gsub(ILLEGAL_REGEXP, "").gsub(ESCAPE_REGEXP, ESCAPE_REPLACEMENTS)
  end
end

RspecJunitFormatter = RSpecJUnitFormatter

if RSpec::Core::Version::STRING.start_with? "2."
  require "rspec_junit_formatter/rspec2"
else
  require "rspec_junit_formatter/rspec3"
end

# CHANGELOG

## v0.4.0 (2018-05-26)

* Add support for including STDOUT and STDERR from tests in the JUnit output (see ["Capturing output"](https://github.com/sj26/rspec_junit_formatter#capturing-output) in the readme for details)
* When RSpec includes a diff in its output, strip out ANSI escape codes used to color it for shell display
* Use [Appraisal](https://github.com/thoughtbot/appraisal) to test the gem against multiple versions of RSpec
* Run gem tests against Ruby 2.5

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog] and this project adheres to [Semantic Versioning].

  [Keep a Changelog]: http://keepachangelog.com/en/1.0.0/
  [Semantic Versioning]: http://semver.org/spec/v2.0.0.html

## [Unreleased]

## [0.4.1] - 2018-05-26
### Fixed
- Diff ANSI stripping now works for codes with multiple tags, too

## [0.4.0] - 2018-05-26
### Added
- Add support for including STDOUT and STDERR from tests in the JUnit output (see ["Capturing output"] in the readme for details)
### Fixed
- When RSpec includes a diff in its output, strip out ANSI escape codes used to color it for shell display

  ["Capturing output"]: https://github.com/sj26/rspec_junit_formatter#capturing-output

  [Unreleased]: https://github.com/sj26/rspec_junit_formatter/compare/v0.4.0...main
  [0.4.1]: https://github.com/sj26/rspec_junit_formatter/compare/v0.4.0...v0.4.1
  [0.4.0]: https://github.com/sj26/rspec_junit_formatter/compare/v0.3.0...v0.4.0

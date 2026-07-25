# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog] and this project adheres to [Semantic Versioning].

  [Keep a Changelog]: http://keepachangelog.com/en/1.0.0/
  [Semantic Versioning]: http://semver.org/spec/v2.0.0.html

## [Unreleased]

  [Unreleased]: https://github.com/sj26/rspec_junit_formatter/compare/v0.7.0...main

## [v0.7.0]
### Changed
- Dropped support for RSpec 2 (unmaintained since 2013, and unable to run on
  currently supported Rubies); `rspec-core` dependency is now `>= 3.0, < 4`
- Raised `required_ruby_version` to `>= 3.1`
- CI, and the Appraisal-generated gemfiles, now only cover rspec-core >= 3.8:
  earlier 3.x releases call a form of `ERB.new` that Ruby has since removed,
  so they cannot run on Ruby 4.0+ regardless of anything in this gem
- Modernized development dependencies (nokogiri, rake, rubocop, simplecov)
### Added
- Ruby 4.0 to the CI matrix, with a `.ruby-version` pinned to 4.0.6
- RuboCop-enforced style, and a SimpleCov-enforced 100% test coverage floor
- A `bundler-audit` CI job
### Fixed
- A latent bug in the test suite where a relative `BUNDLE_GEMFILE` (as set by
  the Appraisal-driven CI matrix) resolved against the wrong working
  directory in the subprocess used to run the example spec

  [v0.7.0]: https://github.com/sj26/rspec_junit_formatter/compare/v0.6.0...v0.7.0

## [v0.6.0]
### Changed
- Restrict to Ruby 2.3+
### Fixed
- Fix handling of nil durations

  [v0.6.0]: https://github.com/sj26/rspec_junit_formatter/compare/v0.5.1...v0.6.0

## [v0.5.1] - 2022-01-06
### Fixed
- Fixed compatibility with older rubies

  [v0.5.1]: https://github.com/sj26/rspec_junit_formatter/compare/v0.5.0...v0.5.1

## [v0.5.0] - 2022-01-04
### Added
- Added support to read outside error count returned from XML formatter (#86)
### Changed
- Moved to GitHub Actions for CI
- Test on current Ruby and RSpec versions

  [v0.5.0]: https://github.com/sj26/rspec_junit_formatter/compare/v0.4.1...v0.5.0

## [v0.4.1] - 2018-05-26
### Fixed
- Diff ANSI stripping now works for codes with multiple tags, too

  [v0.4.1]: https://github.com/sj26/rspec_junit_formatter/compare/v0.4.0...v0.4.1

## [v0.4.0] - 2018-05-26
### Added
- Add support for including STDOUT and STDERR from tests in the JUnit output (see ["Capturing output"] in the readme for details)
### Fixed
- When RSpec includes a diff in its output, strip out ANSI escape codes used to color it for shell display

  [v0.4.0]: https://github.com/sj26/rspec_junit_formatter/compare/v0.3.0...v0.4.0
  ["Capturing output"]: https://github.com/sj26/rspec_junit_formatter#capturing-output

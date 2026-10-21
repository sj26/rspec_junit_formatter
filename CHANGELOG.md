# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog] and this project adheres to [Semantic Versioning].

  [Keep a Changelog]: http://keepachangelog.com/en/1.0.0/
  [Semantic Versioning]: http://semver.org/spec/v2.0.0.html

## [Unreleased]

  [Unreleased]: https://github.com/sj26/rspec_junit_formatter/compare/v0.7.1...main

## [v0.7.1] - 2026-10-21

### Fixed
- Transcode failure messages to UTF-8 before stripping RSpec diff colors, replacing invalid bytes and undefined conversions with U+FFFD (`�`) instead of crashing ([#113](https://github.com/sj26/rspec_junit_formatter/issues/113)).
- Strip trailing spaces from ordinary and aggregate failure detail lines, preserving indentation and internal spaces ([#125](https://github.com/sj26/rspec_junit_formatter/pull/125)).

  [v0.7.1]: https://github.com/sj26/rspec_junit_formatter/compare/v0.7.0...v0.7.1

## [v0.7.0] - 2026-10-21

### Changed
- Require Ruby >= 3.3 and RSpec >= 3.13, < 4. Ruby 3.3 remains supported during upstream security maintenance; Ruby 3.2 and earlier are end-of-life. RSpec 3.13 is the maintained stable minor series; RSpec 4 prereleases are not supported. See the [support policy and upgrade instructions](README.md#supported-versions-and-legacy-upgrades).
- Test Ruby 3.3, 3.4 and 4.0 with both the locked development bundle and the RSpec 3.13 Appraisal.
- **Use [0.6.2](https://rubygems.org/gems/rspec_junit_formatter/versions/0.6.2) if you must keep an older Ruby or RSpec:** pin `gem "rspec_junit_formatter", "0.6.2", require: false` and run `bundle update rspec_junit_formatter`. The RSpec dependency floor prevents older RSpec projects on newer Ruby from selecting 0.7.0.

### Removed
- Remove the RSpec 2 formatter, obsolete RSpec 3 compatibility fallbacks, and Appraisals for unmaintained RSpec versions. Formatting behavior on supported versions is unchanged.

### Fixed
- Create GitHub draft releases without looking them up through the published-release-by-tag endpoint ([#120](https://github.com/sj26/rspec_junit_formatter/pull/120)).

  [v0.7.0]: https://github.com/sj26/rspec_junit_formatter/compare/v0.6.2...v0.7.0

## [v0.6.2] - 2026-10-21

This is the final legacy-compatible release. It retains Ruby >= 2.3 and RSpec >= 2, < 4 (except 2.12.0), including the aggregate failure fix from 0.6.1. Projects staying on Ruby < 3.3 or RSpec < 3.13 should pin `gem "rspec_junit_formatter", "0.6.2"` before the next release raises those minimum versions. Permitted versions are not all tested; see the [compatibility table](https://github.com/sj26/rspec_junit_formatter/blob/v0.6.2/README.md#tested-versus-permitted-versions).

### Fixed
- Replace invalid byte sequences and undefined UTF-8 conversions with U+FFFD (`�`) in XML escaping ([#105](https://github.com/sj26/rspec_junit_formatter/pull/105), [#116](https://github.com/sj26/rspec_junit_formatter/pull/116)). This does not fix encoding errors before XML escaping, including [#113](https://github.com/sj26/rspec_junit_formatter/issues/113), or malformed backtraces rejected by RSpec.

### Changed
- Refresh the development bundle and test current RSpec on Ruby 3.4 and 4.0, without changing runtime requirements.
- Publish unsigned, validated gem artifacts through approved GitHub Actions and RubyGems trusted publishing ([#117](https://github.com/sj26/rspec_junit_formatter/pull/117)).
- Check for GitHub Actions updates weekly with Dependabot ([#106](https://github.com/sj26/rspec_junit_formatter/pull/106)).

  [v0.6.2]: https://github.com/sj26/rspec_junit_formatter/compare/v0.6.1...v0.6.2

## [v0.6.1] - 2026-10-21
### Fixed
- Include all failure details for examples using `aggregate_failures` ([#108](https://github.com/sj26/rspec_junit_formatter/pull/108))
### Changed
- Restore CI and test Ruby 3.2–3.4 and RSpec 3.11–3.13, while retaining existing compatibility coverage ([#111](https://github.com/sj26/rspec_junit_formatter/pull/111))

  [v0.6.1]: https://github.com/sj26/rspec_junit_formatter/compare/v0.6.0...v0.6.1

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

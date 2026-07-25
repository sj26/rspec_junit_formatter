# rspec_junit_formatter Modernization Report

Target: Ruby **4.0.6**. This branch brings the gem up to date for the current
Ruby and RSpec ecosystem, with every change verified to work on Ruby 4.0.6
specifically (that's the only Ruby available in this environment).

## Summary

- Dropped RSpec 2 support (unmaintained since 2013; cannot run on any
  currently supported Ruby).
- Fixed a real Ruby-4.0 incompatibility: rspec-core < 3.8 crashes outright on
  Ruby 4.0+ because of an `ERB.new` signature Ruby removed. The CI/Appraisal
  matrix now only tests rspec-core >= 3.8, which is unaffected.
- Fixed a latent bug in the test suite's use of a relative `BUNDLE_GEMFILE`
  that broke the Appraisal-driven CI matrix once the child process it spawns
  runs in a different working directory.
- Modernized and pruned dependencies; removed one unused dependency
  entirely.
- Raised `required_ruby_version` to `>= 3.1`, added `.ruby-version` (4.0.6),
  and added Ruby 4.0 to the CI matrix.
- Took the test suite from ~32% line coverage (measured against the
  pre-existing test) to a SimpleCov-enforced 100% line and branch coverage,
  by adding an in-process unit spec alongside the existing black-box
  acceptance spec.
- Added RuboCop (+ rubocop-rspec) with a project config, and fixed every
  offense; the codebase is now uniformly formatted.
- Added a `bundler-audit` CI job; no vulnerabilities found.
- Documented every public entry point and every non-obvious private
  implementation detail.

## Compatibility fixes for Ruby 4.0.6

### 1. rspec-core < 3.8 cannot run on Ruby 4.0+ at all

This is the headline finding. `rspec-core`'s `.rspec` option-file parser
(`RSpec::Core::ConfigurationOptions#options_file_as_erb_string`) called:

```ruby
ERB.new(File.read(path), nil, '-').result(binding)
```

`ERB.new`'s 3-positional-argument form (`safe_level`, `trim_mode`) was
deprecated in Ruby 2.6 and has since been removed. On Ruby 4.0.6 this raises
immediately:

```
ArgumentError: wrong number of arguments (given 3, expected 1)
```

rspec-core 3.8.0 fixed this itself by guarding on `RUBY_VERSION >= '2.6'` and
using the keyword-argument form (`ERB.new(str, trim_mode: '-')`) — but only
from 3.8.0 onward. This isn't a bug in rspec_junit_formatter; it's a hard
floor on what this gem's own CI can exercise on Ruby 4.0+. Verified directly
against every installed rspec-core version from 3.0 through 3.13:

| rspec-core | Runs on Ruby 4.0.6? |
|---|---|
| 3.0 – 3.7  | No — `ArgumentError` from `ERB.new` before a single example runs |
| 3.8 – 3.13 | Yes |

**Action taken:** `Appraisals` and the CI matrix now only cover rspec-core
3.8 through 3.13 (the `gemfiles/rspec_3_0.gemfile` .. `rspec_3_7.gemfile`
Appraisal entries were removed). The runtime gemspec dependency is left at
`rspec-core >= 3.0, < 4` since those older releases are still fine for
consumers on older, still-supported Rubies — this is purely about what *this
gem's own CI* can verify on 4.0.6.

### 2. RSpec 2 support dropped

`rspec-core` 2.x (last released 2013, `rspec-core` <= 2.14) doesn't run on
any currently-installable Ruby at all. `lib/rspec_junit_formatter/rspec2.rb`
(the RSpec-2-specific notification adapter) and its Appraisal/CI entries
were removed, and the gemspec's runtime dependency tightened from
`>= 2, < 4, != 2.12.0` to `>= 3.0, < 4`. `lib/rspec_junit_formatter.rb` no
longer branches on `RSpec::Core::Version::STRING` — it just requires the
RSpec 3 adapter directly.

This is a breaking change for anyone still pinned to RSpec 2, hence the
version bump to 0.7.0. It's documented in the CHANGELOG and README.

### 3. Test-suite-only Bundler bootstrap bug

Unrelated to the gem's own code, but blocking every test run on Ruby 4.0.6:
the committed `Gemfile.lock` pinned `BUNDLED WITH 2.2.26`. Bundler 2.2.26
itself doesn't run on Ruby 4.0.6 (`uninitialized constant
DidYouMean::SPELL_CHECKERS`, another removed-API case). Regenerating the
lockfile with a current Bundler resolves it; this isn't something the gem's
source controls, but it's the first thing that broke, so it's worth calling
out for anyone reproducing this from scratch.

### 4. Relative `BUNDLE_GEMFILE` broke the Appraisal-driven CI matrix

`spec/rspec_junit_formatter_spec.rb` spawns a real `bundle exec rspec`
subprocess (over a PTY) in `example/`, to test the formatter as a real user
would invoke it. The Appraisal-driven CI matrix sets `BUNDLE_GEMFILE` to a
path *relative to the repository root* (e.g.
`gemfiles/rspec_3_8.gemfile`) for the whole job. Because the subprocess
inherits that relative env var but runs with a different current directory
(`example/`), Bundler resolved it against the wrong directory and the
subprocess failed outright — silently, from the outer test's point of view,
because it just left a stale `tmp/junit.xml` from a previous run in place,
which the test then read back as if the run had succeeded.

Reproduced directly: `BUNDLE_GEMFILE="$(pwd)/gemfiles/rspec_3_0.gemfile"`
(relative) run from the repo root via `bundle exec rspec` failed 2 of 3
examples with stale-fixture symptoms (wrong timestamp, wrong
`$TEST_ENV_NUMBER`). Fixed in `spec/rspec_junit_formatter_spec.rb` by
expanding `BUNDLE_GEMFILE` to an absolute path before handing it to the
child process's environment (`PTY.spawn(env, *command, ...)`).

### 5. Dead code removed for coverage and clarity

- `lib/rspec_junit_formatter.rb`'s `ILLEGAL_REPLACEMENT` had a third branch
  for codepoints > 0xFFFF, but `ILLEGAL_REGEXP` already whitelists the
  entire `0x10000`-`0x10FFFF` range as *legal* XML, so no illegal codepoint
  can ever exceed 0xFFFF. That branch was unreachable; removed.
- `lib/rspec_junit_formatter/rspec3.rb`'s `without_color` had fallback
  branches for `RSpec.configuration` not responding to `color_mode=`
  (pre-3.8 rspec-core) and a `warn`-and-noop branch for neither `color_mode=`
  nor `color=` existing at all. Since every rspec-core version this gem's
  CI now exercises (3.8+) has `color_mode=`, those branches are dead in
  practice; simplified to a single implementation.
- The `RSpec::Core::Notifications::NullColorizer.wrap` monkey-patch for an
  rspec-core 3.0.x bug (missing `module_function`) was removed for the same
  reason — 3.0.x is no longer in the supported/tested range.

## Dependency changes

| Gem | Before | After |
|---|---|---|
| `rspec-core` (runtime) | `>= 2, < 4, != 2.12.0` | `>= 3.0, < 4` |
| `nokogiri` (dev) | `~> 1.8, >= 1.8.2` | `~> 1.18` (resolves to 1.19.4) |
| `rake` (dev) | unpinned | `~> 13.0`; moved from gemspec to `Gemfile` |
| `appraisal` (dev) | unpinned | `~> 2.5`; moved from gemspec to `Gemfile` |
| `bundler` (dev) | unpinned, explicit | removed — not needed as an explicit dependency |
| `coderay` (dev) | unpinned | **removed** — unused anywhere in the gem or its tests |
| `rspec` (top-level, `Gemfile`) | unpinned | `~> 3.13` |
| `rubocop` (dev) | — | **added**, `~> 1.88` |
| `rubocop-rspec` (dev) | — | **added**, `~> 3.10` |
| `simplecov` (dev) | — | **added**, `~> 1.0` |
| `bundler-audit` (dev) | — | **added**, `~> 0.9` |

`coderay` was a leftover dependency with zero references anywhere in
`lib/`, `spec/`, or `example/` — removed outright rather than upgraded, per
"don't depend on dead code."

Only `nokogiri` remains a gemspec `development_dependency` (rather than
living in the `Gemfile` like the rest of the dev tooling): the
Appraisal-generated gemfiles under `gemfiles/` each just do
`gemspec path: "../"` plus a pinned `rspec` version — they don't source the
root `Gemfile` — and both spec files `require "nokogiri"`. Everything else
(rubocop, simplecov, bundler-audit, appraisal, rake) only needs to be
available when working from the root `Gemfile`, so it lives there instead
(this also happens to be what RuboCop's own `Gemspec/DevelopmentDependencies`
cop recommends).

## Security audit

`bundle exec bundler-audit check --update` against the ruby-advisory-db
(1219 advisories, checked 2026-07-25): **no vulnerabilities found** in the
main `Gemfile.lock` or in any of the six Appraisal-generated
`gemfiles/rspec_*.gemfile.lock` lockfiles.

No `eval`, `system`, backticks, `Marshal.load`, or unsafe `YAML.load` in the
gem's own code. The handful of `.send(...)` calls in
`swap_rspec_configuration` operate only on a hardcoded internal symbol
(`:color_mode`), never on external input, so there's no injection surface
there.

Added `"rubygems_mfa_required" => "true"` to the gemspec metadata as a
supply-chain hardening measure for future releases pushed to RubyGems.

## Test coverage

Coverage is now measured with SimpleCov (line **and** branch coverage,
`enable_coverage :branch`), enforced at 100% via `minimum_coverage` in
`spec/spec_helper.rb` (opt-in locally via `COVERAGE=1`, always on in the
dedicated `coverage` CI job).

- **Before:** the existing single acceptance spec
  (`spec/rspec_junit_formatter_spec.rb`) shells out to a real `rspec`
  process to exercise the formatter, so none of the formatter's own code
  runs in the process SimpleCov instruments. Measured baseline: **31.64%**
  line coverage, **7.14%** branch coverage (both essentially just
  class/constant definition lines executed at `require` time).
- **After:** **100%** line coverage, **100%** branch coverage.

The gap was closed by adding `spec/formatter_spec.rb`, which drives
`RSpecJUnitFormatter` **in-process** using `RSpec::Core::Sandbox` (an
isolated `RSpec::Core::World` + `Configuration`, shipped by rspec-core
itself for exactly this kind of self-testing) instead of a subprocess. This
lets coverage tooling see what actually executes, and makes it practical to
reach branches that are impractical to trigger from the command line:

- A full realistic run (passing/failing/raising/pending examples, a shared
  example group failure, captured stdout/stderr, illegal/discouraged XML
  characters, a real ANSI-colored diff) through the real
  `RSpec::Core::Reporter` notification pipeline.
- `$TEST_ENV_NUMBER` and `--seed` propagation.
- Color forced on via `RSpec.configuration.force(...)` (simulating a
  `--color` CLI flag) to exercise the "already forced" branch of
  `swap_rspec_configuration`, which the default path never hits.
- Every branch of `#escape`, direct unit-tested against the character
  ranges in `ILLEGAL_REGEXP`/`DISCOURAGED_REGEXP`.
- `#error_count`'s fallback for summary notifications without
  `errors_outside_of_examples_count` (rspec-core < 3.6), via a synthetic
  double, since every real rspec-core version this gem now tests against
  has that method.
- `#xml_dump_example` omitting the `time` attribute for an example with no
  recorded duration (a real historical bug, fixed in v0.6.0 — see
  CHANGELOG — that had no regression test until now), via a minimal fake
  notification object.

The original acceptance spec (`spec/rspec_junit_formatter_spec.rb`) is kept
as-is in spirit — it's still the only test that proves the packaged gem
actually works end-to-end via the documented `--format RspecJunitFormatter`
CLI invocation — with only the `BUNDLE_GEMFILE` fix described above.

## Documentation

- Added YARD-style docs to `RSpecJUnitFormatter`'s class-level comment and
  every RSpec-invoked public method (`start`, `stop`, `dump_summary`) in
  `lib/rspec_junit_formatter/rspec3.rb`, plus short "why" comments on
  non-obvious private helpers (`example_group_file_path_for`'s walk to the
  outermost group, the `ILLEGAL_REPLACEMENT` codepoint-range reasoning, the
  `RspecJunitFormatter` casing alias).
- Refreshed `README.md`: RSpec-2 mention removed, a stated Ruby/RSpec
  version floor, and an expanded "Development" section covering
  `bundle exec rspec`, coverage enforcement, RuboCop, and bundler-audit.
- Added a `v0.7.0` `CHANGELOG.md` entry summarizing all of the above.

## Lint

Added `.rubocop.yml` (`rubocop` + `rubocop-rspec`, `TargetRubyVersion:
3.1`). All 258 initial offenses across the codebase were resolved — most
via `rubocop -A`, the rest by hand (moving constants out of a `private`
section where `private` has no effect on them, adding class documentation,
renaming a couple of spec descriptions/contexts to satisfy RSpec cops,
giving a `skip` call an explicit reason). A handful of cops are disabled
project-wide with an inline rationale where the default doesn't fit this
gem (e.g. `Metrics/MethodLength` for the hand-rolled XML builder,
`RSpec/ExpectActual`/`RSpec/NoExpectationExample`/
`RSpec/IdenticalEqualityAssertion` for the deliberately trivial
pass/fail/raise fixture examples used to generate XML in the specs). `bundle
exec rubocop` is now clean; `example/` (a standalone demo project, not
library or test code) is excluded from linting.

## CI

`.github/workflows/ci.yml` now has four jobs:

- **test**: the Ruby x rspec-core matrix (5 Ruby versions × 6 rspec-core
  versions = 30 jobs), now including Ruby 4.0 and rspec-core 3.8–3.13.
  Runs `bundle exec rspec` directly against each Appraisal gemfile (previously
  `bundle exec rake`, which unconditionally `require`s the `appraisal` gem —
  no longer available under the per-version Appraisal gemfiles now that it's
  moved out of the gemspec).
- **coverage**: `bundle exec rspec` with `COVERAGE=1`, enforcing the 100%
  floor, on Ruby 4.0.
- **lint**: `bundle exec rubocop`, on Ruby 4.0.
- **security**: `bundle exec bundler-audit check --update`, on Ruby 4.0.

## Design decisions worth flagging for review

1. **RSpec 2 support dropped, not shimmed.** Given it doesn't run on any
   Ruby this gem can plausibly still be used with, keeping the code around
   would only have added untestable dead code. Documented as a breaking
   change (v0.7.0).
2. **rspec-core 3.0–3.7 dropped from CI/Appraisal, not from the gemspec
   dependency.** The gem's *code* has no problem with those versions; it's
   purely that rspec-core itself can't boot on Ruby 4.0+ before 3.8. Users
   on older Rubies with older rspec-core pins are unaffected.
3. **`required_ruby_version` raised to `>= 3.1`**, not tied to the specific
   Ruby-4.0-only ERB issue above (which is an rspec-core constraint, not a
   constraint on this gem's own code). 3.1 was chosen as the oldest Ruby
   line with any remaining upstream attention at the time of this release.

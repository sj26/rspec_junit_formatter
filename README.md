# RSpec JUnit Formatter

[![Build results](https://github.com/sj26/rspec_junit_formatter/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/sj26/rspec_junit_formatter/actions/workflows/ci.yml?branch=main) 
[![Gem version](http://img.shields.io/gem/v/rspec_junit_formatter.svg)](https://rubygems.org/gems/rspec_junit_formatter)

[RSpec][rspec] 3 results that your CI can read. [Jenkins][jenkins-junit], [Buildkite][buildkite-junit], [CircleCI][circleci-junit], [Gitlab][gitlab-junit], and probably more, too.

  [rspec]: http://rspec.info/
  [jenkins-junit]: https://jenkins.io/doc/pipeline/steps/junit/
  [buildkite-junit]: https://github.com/buildkite/rspec-junit-example
  [circleci-junit]: https://circleci.com/docs/2.0/collect-test-data/
  [gitlab-junit]: https://docs.gitlab.com/ee/ci/unit_test_reports.html#ruby-example

## Supported versions and legacy upgrades

**0.7.0 requires Ruby >= 3.3 and RSpec >= 3.13, < 4.** We support upstream-maintained stable Ruby branches, including security maintenance, and the maintained stable RSpec minor series. As of October 2026, [Ruby 3.3 is security-maintained and Ruby 3.4/4.0 are normally maintained](https://www.ruby-lang.org/en/downloads/branches/). [RSpec supports only the latest major/minor pair](https://rspec.info/blog/2024/11/introducing-the-monorepo/), currently 3.13; RSpec 4 prereleases are not supported. Future minor releases may raise these minimums when upstream maintenance ends.

**[0.6.2](https://rubygems.org/gems/rspec_junit_formatter/versions/0.6.2) is the final legacy-compatible release.** It retains Ruby >= 2.3 and RSpec >= 2, < 4 (except 2.12.0), including the encoding and aggregate failure fixes. See its [compatibility table](https://github.com/sj26/rspec_junit_formatter/blob/v0.6.2/README.md#tested-versus-permitted-versions) for tested combinations and limitations. It does not make end-of-life Ruby or RSpec versions maintained again.

If you must keep an older Ruby **or** an older RSpec, use:

```ruby
gem "rspec_junit_formatter", "0.6.2", require: false
```

Then run `bundle update rspec_junit_formatter`. Without Bundler, use `gem install rspec_junit_formatter -v 0.6.2`. Upgrading Ruby alone is not enough if your project must keep an older RSpec.

To use 0.7.0, upgrade Ruby to a maintained version and RSpec to 3.13, remove the legacy formatter pin, and run `bundle update rspec rspec_junit_formatter`. Both Ruby and `rspec-core` requirements are recorded in the package so dependency resolution can retain 0.6.2 for older environments.

## Usage

Install the gem:

```sh
gem install rspec_junit_formatter
```

Use it:

```sh
rspec --format RspecJunitFormatter --out rspec.xml
```

You'll get an XML file `rspec.xml` with your results in it.

You can use it in combination with other [formatters][rspec-formatters], too:

```sh
rspec --format progress --format RspecJunitFormatter --out rspec.xml
```

  [rspec-formatters]: https://rspec.info/features/3-12/rspec-core/formatters/

### Using in your project with Bundler

Add it to your Gemfile if you're using [Bundler][bundler]. Put it in the same groups as rspec.

```ruby
group :test do
  gem "rspec"
  gem "rspec_junit_formatter", require: false
end
```

Put the same arguments as the commands above in [your `.rspec`][rspec-file]:

```sh
--format RspecJunitFormatter
--out rspec.xml
```
  [bundler]: https://bundler.io
  [rspec-file]: https://rspec.info/features/3-12/rspec-core/configuration/read-options-from-file/

### Parallel tests

For use with `parallel_tests`, add `$TEST_ENV_NUMBER` in the output file option (in `.rspec` or `.rspec_parallel`) to avoid concurrent process write conflicts.

```sh
--format RspecJunitFormatter
--out tmp/rspec<%= ENV["TEST_ENV_NUMBER"] %>.xml
```

The formatter includes `$TEST_ENV_NUMBER` in the test suite name within the XML, too.

### Capturing output

If you like, you can capture the standard output and error streams of each test into the `:stdout` and `:stderr` example metadata which will be added to the junit report, e.g.:

```ruby
# spec_helper.rb

RSpec.configure do |config|
  # register around filter that captures stdout and stderr
  config.around(:each) do |example|
    $stdout = StringIO.new
    $stderr = StringIO.new

    example.run

    example.metadata[:stdout] = $stdout.string
    example.metadata[:stderr] = $stderr.string

    $stdout = STDOUT
    $stderr = STDERR
  end
end
```

Note that this example captures all output from every example all the time, potentially interfering with local debugging. You might like to restrict this to only on CI, or by using [rspec filters](https://rspec.info/features/3-12/rspec-core/hooks/filtering/).

## Caveats

 * XML can only represent a [limited subset of characters][xml-charsets] which excludes null bytes and most control characters. This gem will use character entities where possible and fall back to replacing invalid characters with Ruby-like escape codes otherwise. For example, the null byte becomes `\0`.
 * When converting report text to UTF-8 for XML output, invalid byte sequences and characters with no UTF-8 conversion are replaced with `�` (U+FFFD REPLACEMENT CHARACTER). The formatter uses each string's declared encoding; it does not guess the encoding of binary data.

  [xml-charsets]: https://www.w3.org/TR/xml/#charsets

## Development

Use Ruby 3.4 (see [`.ruby-version`](.ruby-version)) for maintenance. This selects the development Ruby; the installed gem's minimum is defined in the [gemspec](rspec_junit_formatter.gemspec).

Install the Bundler version recorded in `Gemfile.lock`, then test the locked development bundle:

```sh
gem install bundler -v 4.0.23
bundle install
bundle exec rake spec
```

The [development workflow](.github/workflows/development.yml) tests this bundle separately from the [compatibility workflow](.github/workflows/ci.yml). Use `bundle update --all` to refresh the development lockfile.

The supported RSpec series is also defined by [Appraisal][appraisal], with a separate Gemfile to test dependency resolution without the root lockfile:

```sh
BUNDLE_GEMFILE=gemfiles/rspec_3_13.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rspec_3_13.gemfile bundle exec rake spec
```

Plain `bundle exec rake` also runs the Appraisals outside CI.

  [appraisal]: https://github.com/thoughtbot/appraisal

### Tested versus permitted versions

The [gemspec](rspec_junit_formatter.gemspec) permits Ruby >= 3.3 and `rspec-core` >= 3.13, < 4. These requirements allow installation; future versions are not automatically tested or supported.

The CI workflows test these combinations:

| Ruby | RSpec | Bundle |
| --- | --- | --- |
| 3.3, 3.4 and 4.0 | 3.13, latest patch | Appraisal |
| 3.3, 3.4 and 4.0 | 3.13, pinned by `Gemfile.lock` | Development |

CI selects the latest patch of each listed Ruby branch. The locked bundle currently uses RSpec 3.13.2 and rspec-core 3.13.6. Older Ruby and RSpec combinations remain available in [0.6.2](https://github.com/sj26/rspec_junit_formatter/tree/v0.6.2), not in the current test matrix.

## Releasing

Releases use the [Release workflow](https://github.com/sj26/rspec_junit_formatter/actions/workflows/release.yml)
and [RubyGems trusted publishing](https://guides.rubygems.org/trusted-publishing/).
GitHub Actions builds **unsigned gems**: it needs no personal signing key, persistent
RubyGems API key, or maintainer machine. Local `bundle exec rake build`, `install`,
and `release` tasks remain available; local releases may retain the maintainer's
traditional gem signatures. Do not publish the same version through both paths.

1. Bump the gemspec version and update the changelog in a reviewed PR. Merge it
   into `main`. Use a new stable `X.Y.Z` version; never reuse a published version.
2. Tag that exact commit as `vX.Y.Z` and push the tag. Record its full commit SHA
   with `git rev-parse 'vX.Y.Z^{commit}'`. Pushing a tag alone does not publish.
3. Run the Release workflow **from `main`**, supplying the tag and full SHA. Leave
   `publish` unchecked for validation only. It checks tag/version/commit agreement
   and main ancestry, runs the compatibility and development suites at that SHA,
   builds the gem, rejects embedded signatures, and tests a clean installation
   outside the checkout. PRs also exercise the package build/install check, but
   their artifacts can never be published by this workflow.
4. Run again with the same tag and SHA and `publish` checked. After the checks pass,
   review the commit and package SHA-256 in the build log, then approve the
   `release` environment deployment. Sam can approve his own run. The publish job
   downloads that run's exact immutable artifact, uses short-lived OIDC credentials,
   and does not check out or build project code.
5. The workflow verifies that RubyGems serves identical bytes before publishing a
   GitHub release with the same gem. Check both the
   [RubyGems version](https://rubygems.org/gems/rspec_junit_formatter/versions) and
   [GitHub release](https://github.com/sj26/rspec_junit_formatter/releases).

### One-time configuration

The GitHub `release` environment must require approval by `sj26`, allow
self-approval, disable admin bypass, and allow deployments only from the `main`
branch. The **Immutable release tags** repository ruleset blocks updates and
deletion of `v*` tags, with no bypass actors. Under the existing gem's
**Trusted publishers** on RubyGems, configure:

| Field | Value |
| --- | --- |
| Repository owner | `sj26` |
| Repository name | `rspec_junit_formatter` |
| Workflow filename | `release.yml` |
| Environment | `release` |

Leave reusable-workflow repository fields blank. This workflow grants
`id-token: write` only to the environment-protected publish job. Do not add a
RubyGems API key or personal signing key to repository secrets.

### Recovery

Release runs are serialized and never auto-cancel an active publication. If a
push succeeds but a later step fails, **re-run failed jobs in the original run**
while its `release-gem` artifact is retained (30 days). This reuses the validated
bytes and requires environment approval again. An existing RubyGems version is
accepted only if its SHA-256 matches, and its downloaded bytes must also match.
An incomplete GitHub draft can resume; an existing asset must match byte-for-byte
and is never overwritten. A published GitHub release missing its gem fails closed
and needs manual inspection rather than silently changing a public release.

If the tag moved, a digest differs, or the original artifact expired, stop and
investigate. Do not delete/recreate tags, yank/re-push gems, or overwrite release
assets to force a retry. A fresh run rebuilds and is safe only if it reproduces
the same bytes; otherwise recover the original artifact or use a new version
through the normal review process. Validation-only runs do not test OIDC exchange
or publication; only a real, explicitly approved new release can prove those paths.

## License

The MIT License, see [LICENSE](./LICENSE).

## Thanks

Inspired by the work of [Diego Souza][dgvncsz0f] on [RSpec Formatters][dgvncsz0f/rspec_formatters] after frustration with [CI Reporter][ci_reporter].

  [dgvncsz0f]: https://github.com/dgvncsz0f
  [dgvncsz0f/rspec_formatters]: https://github.com/dgvncsz0f/rspec_formatters
  [ci_reporter]: https://github.com/nicksieger/ci_reporter

# RSpec JUnit Formatter

[![Build results](https://github.com/sj26/rspec_junit_formatter/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/sj26/rspec_junit_formatter/actions/workflows/ci.yml?branch=main) 
[![Gem version](http://img.shields.io/gem/v/rspec_junit_formatter.svg)](https://rubygems.org/gems/rspec_junit_formatter)

[RSpec][rspec] 2 & 3 results that your CI can read. [Jenkins][jenkins-junit], [Buildkite][buildkite-junit], [CircleCI][circleci-junit], [Gitlab][gitlab-junit], and probably more, too.

  [rspec]: http://rspec.info/
  [jenkins-junit]: https://jenkins.io/doc/pipeline/steps/junit/
  [buildkite-junit]: https://github.com/buildkite/rspec-junit-example
  [circleci-junit]: https://circleci.com/docs/2.0/collect-test-data/
  [gitlab-junit]: https://docs.gitlab.com/ee/ci/unit_test_reports.html#ruby-example

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
 * When converting report text to UTF-8 for XML output, invalid byte sequences and characters with no UTF-8 conversion are replaced with `??invalid??`. The formatter uses each string's declared encoding; it does not guess the encoding of binary data.

  [xml-charsets]: https://www.w3.org/TR/xml/#charsets

## Development

Use Ruby 3.4 (see [`.ruby-version`](.ruby-version)) for maintenance. Ruby 3.4 is in [normal maintenance](https://www.ruby-lang.org/en/downloads/branches/). This selects the development Ruby without changing the installed gem's requirements. Keep Ruby requirements out of the root Gemfile: Appraisal copies them into legacy Gemfiles.

Install the Bundler version recorded in `Gemfile.lock`, then test the locked development bundle:

```sh
gem install bundler -v 4.0.23
bundle install
bundle exec rake spec
```

The [development workflow](.github/workflows/development.yml) tests this bundle separately from the [compatibility workflow](.github/workflows/ci.yml). Use `bundle update --all` to refresh the development lockfile.

Legacy bundles are defined by [Appraisal][appraisal] and have separate Gemfiles. Select a compatible Ruby and Bundler, then run an individual bundle without the root lockfile, for example on Ruby 2.6:

```sh
BUNDLE_GEMFILE=gemfiles/rspec_2_x.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rspec_2_x.gemfile bundle exec rake spec
```

Plain `bundle exec rake` also runs all Appraisals outside CI. Not all historical RSpec versions run on modern Ruby, so use the combinations in the compatibility workflow rather than running all Appraisals on the maintainer Ruby.

  [appraisal]: https://github.com/thoughtbot/appraisal

### Tested versus permitted versions

The [gemspec](rspec_junit_formatter.gemspec) permits Ruby >= 2.3 and `rspec-core` >= 2, < 4, excluding 2.12.0. These requirements allow installation; they do not mean every Ruby/RSpec combination is tested or works together.

The CI workflows test these combinations:

| Ruby | RSpec | Bundle |
| --- | --- | --- |
| 2.6–3.4 | 3.4–3.13, each minor series | Legacy Appraisals |
| 2.6–3.1 | 2.14 (`< 2.99`) and 3.0–3.3, each minor series | Legacy Appraisals |
| 3.4 and 4.0 | Current 3.13, pinned by `Gemfile.lock` | Development |

Ruby 4.0 coverage initially uses only the current RSpec development bundle, not the historical Appraisals. Ruby 2.3–2.5 remain permitted but are not covered by CI. RSpec versions allowed by the gemspec but outside the Appraisal ranges are also untested. Historical RSpec versions below 3.4 are not compatible with Ruby 3.2 or newer. Retaining installation permission does not imply that an end-of-life Ruby still receives upstream security updates.

## Releasing

Bump the gem version in the gemspec, and commit. Then `bundle exec rake build` to build a gem package, `bundle exec rake install` to install and test it locally, then `bundle exec rake release` to tag and push the commits and gem.

## License

The MIT License, see [LICENSE](./LICENSE).

## Thanks

Inspired by the work of [Diego Souza][dgvncsz0f] on [RSpec Formatters][dgvncsz0f/rspec_formatters] after frustration with [CI Reporter][ci_reporter].

  [dgvncsz0f]: https://github.com/dgvncsz0f
  [dgvncsz0f/rspec_formatters]: https://github.com/dgvncsz0f/rspec_formatters
  [ci_reporter]: https://github.com/nicksieger/ci_reporter

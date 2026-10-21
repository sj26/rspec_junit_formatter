# RSpec JUnit Formatter

[![Build results](https://github.com/sj26/rspec_junit_formatter/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/sj26/rspec_junit_formatter/actions/workflows/ci.yml?branch=main) 
[![Gem version](http://img.shields.io/gem/v/rspec_junit_formatter.svg)](https://rubygems.org/gems/rspec_junit_formatter)

[RSpec][rspec] 3 results that your CI can read. [Jenkins][jenkins-junit], [Buildkite][buildkite-junit], [CircleCI][circleci-junit], [Gitlab][gitlab-junit], and probably more, too.

  [rspec]: http://rspec.info/
  [jenkins-junit]: https://jenkins.io/doc/pipeline/steps/junit/
  [buildkite-junit]: https://github.com/buildkite/rspec-junit-example
  [circleci-junit]: https://circleci.com/docs/2.0/collect-test-data/
  [gitlab-junit]: https://docs.gitlab.com/ee/ci/unit_test_reports.html#ruby-example

## Usage

Requires Ruby >= 3.3 and RSpec >= 3.13, < 4. For older versions, see [legacy support](#supported-versions-and-legacy-upgrades).

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

## Supported versions and legacy upgrades

We support [maintained Ruby versions](https://www.ruby-lang.org/en/downloads/branches/), including security maintenance, and [the current stable RSpec series](https://rspec.info/blog/2024/11/introducing-the-monorepo/). Minor releases may raise the minimum versions when upstream support ends.

For Ruby < 3.3 or RSpec < 3.13, use [0.6.2](https://rubygems.org/gems/rspec_junit_formatter/versions/0.6.2), the final legacy release:

```ruby
gem "rspec_junit_formatter", "0.6.2", require: false
```

Run `bundle update rspec_junit_formatter`, or install without Bundler using `gem install rspec_junit_formatter -v 0.6.2`. This release permits Ruby >= 2.3 and RSpec >= 2, < 4, except 2.12.0; see its [tested combinations](https://github.com/sj26/rspec_junit_formatter/blob/v0.6.2/README.md#tested-versus-permitted-versions).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development, testing and release instructions.

## License

The MIT License, see [LICENSE](./LICENSE).

## Thanks

Inspired by the work of [Diego Souza][dgvncsz0f] on [RSpec Formatters][dgvncsz0f/rspec_formatters] after frustration with [CI Reporter][ci_reporter].

  [dgvncsz0f]: https://github.com/dgvncsz0f
  [dgvncsz0f/rspec_formatters]: https://github.com/dgvncsz0f/rspec_formatters
  [ci_reporter]: https://github.com/nicksieger/ci_reporter

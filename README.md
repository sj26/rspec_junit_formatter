# RSpec JUnit Formatter

[RSpec][rspec] results that [Hudson][hudson] can read. Probably a few other CI servers, too.

Inspired by the work of [Diego Souza][dsouza] on [RSpec Formatters][dsouza/rspec_formatters] after frustration with [CI Reporter][ci_reporter].

## Usage

Install the gem:

    gem install rspec_junit_formatter

Use it:

    rspec --format RspecJunitFormatter --out rspec.xml

You'll get an XML file with your results in it.

## More Permanent Usage

Add it to your Gemfile if you're using [Bundler][bundler].

In your .rspec, usually alongside another formatter, add:

    --format JUnitFormatter
    --out rspec.xml

I use it with the excellent [Fuubar formatter][fuubar].

## Roadmap

 * It would be nice to split things up into individual test suites, although would this correspond to example groups? The subject? The spec file? Not sure yet.
 * This would sit nicely in rspec-core, and has been designed to do so.

## License

The MIT License, see [LICENSE][license].

  [rspec]: http://rspec.info/
  [hudson]: http://hudson-ci.org/
  [dsouza]: https://github.com/dsouza
  [dsouza/rspec_formatters]: https://github.com/dsouza/rspec_formatters
  [ci_reporter]: http://caldersphere.rubyforge.org/ci_reporter/
  [bundler]: http://gembundler.com/
  [fuubar]: http://jeffkreeftmeijer.com/2010/fuubar-the-instafailing-rspec-progress-bar-formatter/
  [license]: https://github.com/sj26/rspec-junit-formatter/blob/master/LICENSE

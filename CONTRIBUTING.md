# Contributing

For installation and usage, see the [README](README.md).

## Development

Use Ruby 3.4 (see [`.ruby-version`](.ruby-version)) for maintenance. The installed gem's minimum is defined in the [gemspec](rspec_junit_formatter.gemspec).

Install the Bundler version recorded in `Gemfile.lock`, then test the locked development bundle:

```sh
gem install bundler -v 4.0.23
bundle install
bundle exec rake spec
```

The [development workflow](.github/workflows/development.yml) tests this bundle separately from the [compatibility workflow](.github/workflows/ci.yml). Use `bundle update --all` to refresh the development lockfile.

Dependabot PRs that change only `Gemfile.lock` merge after the development matrix passes. Changes to gem constraints, packaged code, or workflows still need manual review.

When changing an action reference, run [`gh actions-lock`](https://github.com/github/gh-actions-lock) and include the generated lockfile in the PR.

The supported RSpec series is also defined by [Appraisal](https://github.com/thoughtbot/appraisal), with a separate Gemfile to test dependency resolution without the root lockfile:

```sh
BUNDLE_GEMFILE=gemfiles/rspec_3_13.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rspec_3_13.gemfile bundle exec rake spec
```

Plain `bundle exec rake` also runs the Appraisals outside CI.

### Tested versus permitted versions

CI tests Ruby 3.3, 3.4 and 4.0 with RSpec 3.13, using both the locked development bundle and the Appraisal's latest patches. Future versions permitted by the gemspec are not tested until added to the matrix.

## Releasing

Releases use the [Release workflow](https://github.com/sj26/rspec_junit_formatter/actions/workflows/release.yml)
and [RubyGems trusted publishing](https://guides.rubygems.org/trusted-publishing/).
No persistent RubyGems API key or signing key is needed.

1. Bump the gemspec to a new stable version, update the changelog, and merge the PR.
2. After CI passes on the release commit on `main`, push a `vX.Y.Z` tag for that commit.
3. Run **Release** from `main` with that tag and approve the `release` environment.
   The job checks that the tag is on `main` and matches the gem version, builds the
   gem without the development bundle, and publishes it to RubyGems and as a
   [GitHub release asset](https://github.com/sj26/rspec_junit_formatter/releases).
   Pushing a tag alone does not publish.

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

If the GitHub release step fails after RubyGems accepts the gem, download the
[published gem](https://rubygems.org/gems/rspec_junit_formatter/versions) and use it
to finish the GitHub release for the existing tag. Do not rerun the push, move the
tag, or overwrite an existing asset.

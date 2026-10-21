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

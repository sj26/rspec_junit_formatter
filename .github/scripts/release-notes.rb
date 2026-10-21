require "json"
require "open3"
require "rubygems/version"
require "uri"

tag = ENV.fetch("RELEASE_TAG")
commit = ENV.fetch("RELEASE_COMMIT")
digest = ENV.fetch("RELEASE_SHA256")
abort "Invalid release tag" unless tag.match?(/\Av\d+\.\d+\.\d+\z/)
abort "Invalid release commit" unless commit.match?(/\A[0-9a-f]{40}\z/)
abort "Invalid gem digest" unless digest.match?(/\A[0-9a-f]{64}\z/)
abort "Release checkout differs from target" unless `git rev-parse HEAD`.strip == commit

# Exclude the target even on retries after it has already been published. Also
# exclude newer versions when reviewing an older release, drafts and prereleases.
version = Gem::Version.new(tag.delete_prefix("v"))
releases = JSON.parse(File.read(ARGV.fetch(0))).flatten
previous = releases.select do |release|
  release["draft"] == false && release["prerelease"] == false &&
    release["tag_name"].match?(/\Av\d+\.\d+\.\d+\z/) &&
    Gem::Version.new(release["tag_name"].delete_prefix("v")) < version
end.max_by { |release| Gem::Version.new(release.fetch("tag_name").delete_prefix("v")) }
abort "No previous published stable release found" unless previous
previous_tag = previous.fetch("tag_name")
previous_commit, status = Open3.capture2("git", "rev-parse", "refs/tags/#{previous_tag}^{commit}")
abort "Previous release tag is missing" unless status.success?
previous_commit = previous_commit.strip
abort "Previous release is not an ancestor of the target" unless
  system("git", "merge-base", "--is-ancestor", previous_commit, commit)

changelog = File.read("CHANGELOG.md")
section = changelog.split(/(?=^## )/).find { |part| part.lines.first.match?(/\A## \[#{Regexp.escape(tag)}\](?:\s|$)/) }
abort "Missing changelog section for #{tag}" unless section
notes = section.lines.drop(1).reject { |line| line.match?(/^\s*\[#{Regexp.escape(tag)}\]:/) }.join.strip
abort "Empty changelog section for #{tag}" if notes.empty?

repo_url = "#{ENV.fetch('GITHUB_SERVER_URL')}/#{ENV.fetch('GITHUB_REPOSITORY')}"
changelog_url = "#{repo_url}/blob/#{commit}/CHANGELOG.md"
# Changelog links normally resolve relative to the source file. Preserve that
# meaning when the section is rendered in a job summary or GitHub release body.
notes = notes.gsub(/\]\(([^\s)]+)\)/) { "](#{URI.join(changelog_url, Regexp.last_match(1))})" }
notes = notes.gsub(/^(\s*\[[^\]]+\]:\s*)(\S+)/) { "#{Regexp.last_match(1)}#{URI.join(changelog_url, Regexp.last_match(2))}" }

File.write(ARGV.fetch(1), <<~MARKDOWN)
  # Release review: #{tag}

  - **Version:** `#{version}`
  - **Target commit:** [`#{commit}`](#{repo_url}/commit/#{commit})
  - **Previous release:** [#{previous_tag}](#{repo_url}/releases/tag/#{previous_tag}) (`#{previous_commit}`)
  - **Code changes:** [Compare #{previous_tag} → #{tag}](#{repo_url}/compare/#{previous_commit}...#{commit})
  - **Gem:** `rspec_junit_formatter-#{version}.gem`
  - **Gem SHA-256:** `#{digest}`
  - **Source changelog:** [CHANGELOG.md at the target commit](#{changelog_url})

  ## Changelog

  #{notes}
MARKDOWN

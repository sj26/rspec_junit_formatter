require "json"
require "open3"
require "tmpdir"

describe "release approval notes" do
  let(:script) { File.expand_path("../.github/scripts/release-notes.rb", __dir__) }

  def git(*args)
    output, status = Open3.capture2e("git", *args)
    raise output unless status.success?
    output.strip
  end

  around do |example|
    Dir.mktmpdir("release-notes-") do |dir|
      Dir.chdir(dir) { example.run }
    end
  end

  before do
    git("init", "--quiet")
    git("config", "user.name", "Release test")
    git("config", "user.email", "release@example.invalid")
    git("-c", "commit.gpgsign=false", "commit", "--allow-empty", "-m", "previous")
    @previous = git("rev-parse", "HEAD")
    git("tag", "-a", "v0.10.0", "-m", "previous release")
    File.write("CHANGELOG.md", <<~MARKDOWN)
      # Changelog
      ## [Unreleased]
      Not part of this release.
      ## [v0.12.0] - 2026-10-21
      ### Changed
      - Exact release change. See [usage](README.md#usage).
      - See [details][details].
        [details]: docs/details.md
        [v0.12.0]: https://example.invalid/mutable-tag-compare
      ## [v0.10.0]
      Previous change, not this release.
    MARKDOWN
    git("add", "CHANGELOG.md")
    git("-c", "commit.gpgsign=false", "commit", "-m", "target")
    @target = git("rev-parse", "HEAD")
    git("tag", "v0.12.0")
    # Deliberately unsorted, paginated, with a newer release and the target
    # already published: retries must still compare against v0.10.0, not itself.
    releases = %w[v0.13.0 v0.12.0 v0.10.0 v0.9.0].map do |tag|
      { "tag_name" => tag, "draft" => false, "prerelease" => false }
    end
    releases << { "tag_name" => "v0.11.0", "draft" => true, "prerelease" => false }
    releases << { "tag_name" => "v0.11.1", "draft" => false, "prerelease" => true }
    File.write("releases.json", JSON.generate([releases.take(2), releases.drop(2)]))
    @env = { "RELEASE_TAG" => "v0.12.0", "RELEASE_COMMIT" => @target,
             "RELEASE_SHA256" => "a" * 64, "GITHUB_SERVER_URL" => "https://github.com",
             "GITHUB_REPOSITORY" => "owner/repo" }
  end

  def generate
    Open3.capture2e(@env, "ruby", script, "releases.json", "notes.md")
  end

  it "binds the exact changelog, compare and package identity to the release commit" do
    output, status = generate
    expect(status.success?).to be(true), output
    notes = File.read("notes.md")
    expect(notes).to include("https://github.com/owner/repo/compare/#{@previous}...#{@target}")
    expect(notes).to include("Compare v0.10.0 → v0.12.0", "rspec_junit_formatter-0.12.0.gem", "a" * 64)
    expect(notes).to include("Exact release change.", "https://github.com/owner/repo/blob/#{@target}/README.md#usage")
    expect(notes).to include("[details]: https://github.com/owner/repo/blob/#{@target}/docs/details.md")
    expect(notes).not_to include("Not part of this release", "Previous change", "mutable-tag-compare")
  end

  it "refuses notes from a different checkout" do
    @env["RELEASE_COMMIT"] = @previous
    output, status = generate
    expect(status.success?).to be(false)
    expect(output).to include("Release checkout differs from target")
    expect(File.exist?("notes.md")).to be(false)
  end

  it "refuses to substitute another version's changelog" do
    @env["RELEASE_TAG"] = "v0.12.1"
    output, status = generate
    expect(status.success?).to be(false)
    expect(output).to include("Missing changelog section for v0.12.1")
    expect(File.exist?("notes.md")).to be(false)
  end

  it "refuses an unrelated previous release rather than showing a misleading compare" do
    unrelated = git("-c", "commit.gpgsign=false", "commit-tree", "HEAD^{tree}", "-m", "unrelated")
    git("tag", "-f", "v0.10.0", unrelated)
    output, status = generate
    expect(status.success?).to be(false)
    expect(output).to include("Previous release is not an ancestor")
    expect(File.exist?("notes.md")).to be(false)
  end
end

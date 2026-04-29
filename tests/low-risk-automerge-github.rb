# frozen_string_literal: true

require "fileutils"
require "tmpdir"

require_relative "../tools/low-risk-automerge/common"
require_relative "../tools/low-risk-automerge/github"

def assert(value, message = "assertion failed")
  abort message unless value
end

def refute(value, message = "refutation failed")
  abort message if value
end

def assert_equal(expected, actual)
  return if expected == actual

  abort "Expected #{expected.inspect}, got #{actual.inspect}"
end

def assert_match(pattern, actual)
  return if pattern.match?(actual.to_s)

  abort "Expected #{actual.inspect} to match #{pattern.inspect}"
end

def assert_nil(actual)
  return if actual.nil?

  abort "Expected nil, got #{actual.inspect}"
end

class FakeGitHubClient
  attr_reader :posts, :puts

  def initialize(comments:, check_runs:, status:, pulls: {})
    @comments = comments
    @check_runs = check_runs
    @status = status
    @pulls = pulls
    @posts = []
    @puts = []
  end

  def get_json(path)
    case path
    when %r{\A/issues/(\d+)/comments(?:\?per_page=\d+&page=(\d+))?\z}
      comments = @comments.fetch(Regexp.last_match(1).to_i)
      page = (Regexp.last_match(2) || 1).to_i
      comments.is_a?(Hash) ? comments.fetch(page, []) : (page == 1 ? comments : [])
    when %r{\A/commits/([^/]+)/check-runs\z}
      @check_runs.fetch(Regexp.last_match(1))
    when %r{\A/commits/([^/]+)/status\z}
      @status.fetch(Regexp.last_match(1))
    when %r{\A/pulls/(\d+)\z}
      @pulls.fetch(Regexp.last_match(1).to_i)
    when "/pulls?state=open"
      @pulls.values
    else
      raise "unexpected GET #{path}"
    end
  end

  def post_json(path, payload)
    @posts << [path, payload]
  end

  def put_json(path, payload)
    @puts << [path, payload]
  end
end

REVIEW_BODY = <<~BODY
  <!-- codex-review:v1
  reviewed_head: abc123
  risk: low
  merge_ok: true
  reviewer: codex-pr-review
  -->

  ## Codex Review
BODY

def runner_for(client: client_for, trusted_authors: ["github-actions[bot]"], required_checks: ["CI", "Deploy Jekyll site to Pages"])
  LowRiskAutomerge::GitHubRunner.new(
    client: client,
    repo: "owner/repo",
    trusted_authors: trusted_authors,
    required_checks: required_checks
  )
end

def client_for(comments: [comment(REVIEW_BODY)], check_runs: success_check_runs, status: { "state" => "success" })
  FakeGitHubClient.new(
    comments: { 7 => comments },
    check_runs: { "abc123" => check_runs },
    status: { "abc123" => status },
    pulls: { 7 => same_repo_pr }
  )
end

def comment(body, author: "github-actions[bot]", created_at: "2026-04-26T18:00:00Z")
  { "body" => body, "created_at" => created_at, "user" => { "login" => author } }
end

def success_check_runs
  {
    "check_runs" => [
      { "name" => "CI", "status" => "completed", "conclusion" => "success" },
      { "name" => "Deploy Jekyll site to Pages", "status" => "completed", "conclusion" => "success" },
      { "name" => "Low-Risk Automerge", "status" => "in_progress", "conclusion" => nil }
    ]
  }
end

def same_repo_pr
  {
    "number" => 7,
    "head" => { "sha" => "abc123", "repo" => { "full_name" => "owner/repo" } },
    "base" => { "repo" => { "full_name" => "owner/repo" } }
  }
end

def fork_pr
  {
    "number" => 7,
    "head" => { "sha" => "abc123", "repo" => { "full_name" => "someone/repo" } },
    "base" => { "repo" => { "full_name" => "owner/repo" } }
  }
end

metadata = LowRiskAutomerge::MetadataParser.parse(REVIEW_BODY)
assert_equal "abc123", metadata.reviewed_head
assert_equal "low", metadata.risk
assert_equal true, metadata.merge_ok
assert_equal "codex-pr-review", metadata.reviewer

assert_nil LowRiskAutomerge::MetadataParser.parse("no metadata")
assert_nil LowRiskAutomerge::MetadataParser.parse("#{REVIEW_BODY}\n#{REVIEW_BODY}")
assert_nil LowRiskAutomerge::MetadataParser.parse(REVIEW_BODY.sub("risk: low", "risk: tiny"))
assert_nil LowRiskAutomerge::MetadataParser.parse(REVIEW_BODY.sub("merge_ok: true", "merge_ok: yes"))

result = runner_for.evaluate_pr(fork_pr)
refute result.merged?
assert_match(/fork/i, result.reason)

client = client_for
result = runner_for(client: client).evaluate_pr(same_repo_pr)
assert result.merged?
assert_equal [["/pulls/7/merge", { "sha" => "abc123", "merge_method" => "rebase" }]], client.puts

comments = [
  comment(REVIEW_BODY, created_at: "2026-04-26T18:00:00Z"),
  comment("Not merging PR #7: combined status is not successful", created_at: "2026-04-26T19:00:00Z")
]
client = client_for(comments: comments)
result = runner_for(client: client).evaluate_pr(same_repo_pr)
assert result.merged?
assert_equal [["/pulls/7/merge", { "sha" => "abc123", "merge_method" => "rebase" }]], client.puts

comments = [comment(REVIEW_BODY, author: "renovate[bot]")]
result = runner_for(client: client_for(comments: comments)).evaluate_pr(same_repo_pr)
refute result.merged?
assert_match(/trusted/i, result.reason)

comments = [comment(REVIEW_BODY, author: "f1sherman")]
client = client_for(comments: comments)
result = runner_for(client: client, trusted_authors: ["github-actions[bot]", "f1sherman"]).evaluate_pr(same_repo_pr)
assert result.merged?
assert_equal [["/pulls/7/merge", { "sha" => "abc123", "merge_method" => "rebase" }]], client.puts

comments = [comment(REVIEW_BODY.sub("abc123", "oldsha"))]
result = runner_for(client: client_for(comments: comments)).evaluate_pr(same_repo_pr)
refute result.merged?
assert_match(/stale/i, result.reason)

failed = { "check_runs" => [{ "name" => "CI", "status" => "completed", "conclusion" => "failure" }] }
pending = { "check_runs" => [{ "name" => "CI", "status" => "in_progress", "conclusion" => nil }] }
assert_match(/check/i, runner_for(client: client_for(check_runs: failed)).evaluate_pr(same_repo_pr).reason)
assert_match(/check/i, runner_for(client: client_for(check_runs: pending)).evaluate_pr(same_repo_pr).reason)
missing = { "check_runs" => [] }
result = runner_for(
  client: client_for(check_runs: missing, status: { "state" => "pending", "total_count" => 0, "statuses" => [] })
).evaluate_pr(same_repo_pr)
refute result.merged?
assert_match(/check/i, result.reason)

result = runner_for(client: client_for(status: { "state" => "failure" })).evaluate_pr(same_repo_pr)
refute result.merged?
assert_match(/status/i, result.reason)

client = client_for(status: { "state" => "pending", "total_count" => 0, "statuses" => [] })
result = runner_for(client: client).evaluate_pr(same_repo_pr)
assert result.merged?
assert_equal [["/pulls/7/merge", { "sha" => "abc123", "merge_method" => "rebase" }]], client.puts

client = client_for(status: { "state" => "failure" })
runner_for(client: client).evaluate_pr(same_repo_pr)
assert_equal "/issues/7/comments", client.posts.first.first
assert_match(/not merging/i, client.posts.first.last.fetch("body"))

client = client_for(
  comments: [
    comment(REVIEW_BODY),
    comment("Not merging PR #7: combined status is not successful")
  ],
  status: { "state" => "failure" }
)
runner_for(client: client).evaluate_pr(same_repo_pr)
assert_equal [], client.posts

comments = {
  1 => [comment(REVIEW_BODY.sub("abc123", "oldsha"), created_at: "2026-04-26T18:00:00Z")],
  2 => [comment(REVIEW_BODY, created_at: "2026-04-26T19:00:00Z")]
}
client = client_for(comments: comments)
result = runner_for(client: client).evaluate_pr(same_repo_pr)
assert result.merged?
assert_equal [["/pulls/7/merge", { "sha" => "abc123", "merge_method" => "rebase" }]], client.puts

tmpdir = Dir.mktmpdir("low-risk-automerge-event")
event_path = File.join(tmpdir, "event.json")
File.write(event_path, JSON.generate({ "issue" => { "number" => 7 } }))
client = client_for
runner = LowRiskAutomerge::GitHubRunner.new(
  client: client,
  repo: "owner/repo",
  trusted_authors: ["github-actions[bot]"],
  event_path: event_path
)
assert_equal [], runner.send(:candidate_prs)
FileUtils.rm_rf(tmpdir)

puts "PASS low-risk automerge github"

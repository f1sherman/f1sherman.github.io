# frozen_string_literal: true

require_relative "../tools/codex-pr-review/review_runner"

def assert_includes(haystack, needle)
  return if haystack.include?(needle)

  abort "Expected #{haystack.inspect} to include #{needle.inspect}"
end

body = CodexPrReview::ReviewRunner.top_level_comment_body(
  reviewed_at: "2026-04-26T18:00:00Z",
  reviewed_sha: "abc123",
  platform: "github",
  repo: "f1sherman/f1sherman.github.io",
  pr_number: 58,
  output: {
    "findings" => [],
    "overall_correctness" => "patch is correct",
    "overall_confidence_score" => 0.91,
    "overall_explanation" => "No actionable findings.",
    "risk" => "low",
    "merge_ok" => true
  },
  unplaced_findings: [],
  inline_count: 0
)

assert_includes body, "<!-- codex-review:v1\n"
assert_includes body, "reviewed_head: abc123\n"
assert_includes body, "risk: low\n"
assert_includes body, "merge_ok: true\n"
assert_includes body, "reviewer: codex-pr-review\n"
assert_includes body, "Risk: Low"
assert_includes body, "Merge OK: Yes"
assert_includes body, "Reviewed Head: `abc123`"

puts "PASS codex-pr-review runner metadata"

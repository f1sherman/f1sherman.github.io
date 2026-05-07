#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../tools/codex-pr-review/review_runner"

class CodexPrReviewMetadataTest < Minitest::Test
  def test_top_level_comment_includes_trusted_review_metadata
    output = {
      "findings" => [],
      "overall_correctness" => "patch is correct",
      "overall_confidence_score" => 0.91,
      "overall_explanation" => "No actionable findings.",
      "risk" => "low",
      "merge_ok" => true
    }

    body = CodexPrReview::ReviewRunner.top_level_comment_body(
      reviewed_at: "2026-05-07T00:00:00Z",
      reviewed_sha: "abc123",
      platform: "github",
      repo: "f1sherman/f1sherman.github.io",
      pr_number: 58,
      output: output,
      unplaced_findings: [],
      inline_count: 0
    )

    assert_includes body, "<!-- pr-upkeep:v1"
    assert_includes body, "kind: codex_review"
    assert_includes body, "platform: github"
    assert_includes body, "repo: f1sherman/f1sherman.github.io"
    assert_includes body, "pr: 58"
    assert_includes body, "head_sha: abc123"
    assert_match(/-->\z/, body)
  end
end

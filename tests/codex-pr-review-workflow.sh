#!/usr/bin/env bash
set -euo pipefail

ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
WORKFLOW="$ROOT/.github/workflows/codex-pr-review.yml"

grep -Fq "types: [opened, reopened]" "$WORKFLOW"
grep -Fq "workflow_dispatch:" "$WORKFLOW"
grep -Fq "pull_request_target:" "$WORKFLOW"
grep -Fq "pull-requests: write" "$WORKFLOW"
grep -Fq 'ref: ${{ github.event.pull_request.base.sha || github.event.repository.default_branch }}' "$WORKFLOW"
grep -Fq "ruby bin/codex-pr-review" "$WORKFLOW"
grep -Fq -- '--repo "$REVIEW_REPO"' "$WORKFLOW"
grep -Fq -- '--pr-number "$REVIEW_PR_NUMBER"' "$WORKFLOW"
grep -Fq "actions/upload-artifact@v4" "$WORKFLOW"
! grep -Fq "synchronize" "$WORKFLOW"
! grep -Fq "pull_request:" "$WORKFLOW"
printf 'PASS f1sherman.github.io codex review workflow wiring\n'

#!/usr/bin/env bash
set -euo pipefail

ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
WORKFLOW="$ROOT/.github/workflows/codex-pr-review.yml"

grep -Fq "workflow_dispatch:" "$WORKFLOW"
grep -Fq "pr_number:" "$WORKFLOW"
grep -Fq 'REVIEW_REPO="${GITHUB_REPOSITORY:-$(jq -r '\''.repository.full_name // empty'\'' "$GITHUB_EVENT_PATH")}"' "$WORKFLOW"
grep -Fq 'REVIEW_PR_NUMBER="$(jq -r '\''.inputs.pr_number // empty'\'' "$GITHUB_EVENT_PATH")"' "$WORKFLOW"
grep -Fq "curl -fsS -X POST https://codex-review.brianjohn.com/enqueue" "$WORKFLOW"
grep -Fq 'Authorization: Bearer ${{ secrets.CODEX_REVIEWER_SERVICE_TOKEN }}' "$WORKFLOW"
grep -Fq '"platform": "github"' "$WORKFLOW"
grep -Fq '"repo": env.REVIEW_REPO' "$WORKFLOW"
grep -Fq '"pr_number": (env.REVIEW_PR_NUMBER | tonumber)' "$WORKFLOW"
grep -Fq '"trigger": "manual"' "$WORKFLOW"
! grep -Fq "synchronize" "$WORKFLOW"
! grep -Fq "pull_request:" "$WORKFLOW"
! grep -Fq "pull_request_target:" "$WORKFLOW"
! grep -Fq "CODEX_AUTH_JSON" "$WORKFLOW"
! grep -Fq "npm install -g @openai/codex" "$WORKFLOW"
! grep -Fq "tools/codex-pr-review/ci_preflight.rb" "$WORKFLOW"
! grep -Fq "ruby bin/codex-pr-review" "$WORKFLOW"
! grep -Fq "actions/upload-artifact@v4" "$WORKFLOW"
! grep -Fq "bin/codex-ci-preflight" "$WORKFLOW"
printf 'PASS f1sherman.github.io codex review workflow enqueue bridge\n'

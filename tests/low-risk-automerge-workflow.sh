#!/usr/bin/env bash
set -euo pipefail

ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
WORKFLOW="$ROOT/.github/workflows/low-risk-automerge.yml"

grep -Fq "name: Low-Risk Automerge" "$WORKFLOW"
grep -Fq "schedule:" "$WORKFLOW"
grep -Fq "workflow_dispatch:" "$WORKFLOW"
grep -Fq "issue_comment:" "$WORKFLOW"
grep -Fq "workflow_run:" "$WORKFLOW"
grep -Fq 'workflows: ["CI", "Deploy Jekyll site to Pages"]' "$WORKFLOW"
grep -Fq "contents: write" "$WORKFLOW"
grep -Fq "pull-requests: write" "$WORKFLOW"
grep -Fq "issues: write" "$WORKFLOW"
grep -Fq "checks: read" "$WORKFLOW"
grep -Fq "statuses: read" "$WORKFLOW"
grep -Fq "ruby tools/low-risk-automerge/github.rb" "$WORKFLOW"
grep -Fq "LOW_RISK_AUTOMERGE_TRUSTED_AUTHORS: github-actions[bot],f1sherman" "$WORKFLOW"
grep -Fq "LOW_RISK_AUTOMERGE_REQUIRED_CHECKS: CI,Deploy Jekyll site to Pages" "$WORKFLOW"
printf 'PASS f1sherman.github.io low-risk automerge workflow wiring\n'

#!/usr/bin/env bash
set -euo pipefail

ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
WORKFLOW="$ROOT/.github/workflows/codex-pr-review.yml"

grep -Fq "types: [opened, reopened]" "$WORKFLOW"
grep -Fq "workflow_dispatch:" "$WORKFLOW"
grep -Fq "pull-requests: write" "$WORKFLOW"
grep -Fq "ruby bin/codex-pr-review" "$WORKFLOW"
grep -Fq "actions/upload-artifact@v4" "$WORKFLOW"
! grep -Fq "synchronize" "$WORKFLOW"
printf 'PASS f1sherman.github.io codex review workflow wiring\n'

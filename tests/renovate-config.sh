#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

require_file() {
  local path="$1"
  [[ -f "$path" ]] || {
    echo "missing file: $path" >&2
    exit 1
  }
}

require_no_file() {
  local path="$1"
  [[ ! -e "$path" ]] || {
    echo "unexpected file present: $path" >&2
    exit 1
  }
}

require_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"
  [[ "$actual" == "$expected" ]] || {
    echo "$message: expected '$expected', got '$actual'" >&2
    exit 1
  }
}

require_no_match() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  if grep -E -q -r "$pattern" "$path"; then
    echo "$message: found pattern '$pattern' in $path" >&2
    exit 1
  fi
}

require_file "renovate.json"
require_file ".github/workflows/renovate.yml"
require_no_file ".github/workflows/renovate-review.yml"
require_no_match "README.md" 'RENOVATE_APP_SLUG' "README should not document an in-repo review workflow slug"
require_no_match "README.md" 'CLAUDE_CODE_OAUTH_TOKEN' "README should not document Claude review secret setup"

schema="$(jq -r '."$schema"' renovate.json)"
extends0="$(jq -r '.extends[0]' renovate.json)"
min_age="$(jq -r '.minimumReleaseAge' renovate.json)"
label0="$(jq -r '.labels[0]' renovate.json)"
ignored_author_count="$(jq --arg author "PR Upkeeper <pr-upkeeper@brianjohn.com>" '[.gitIgnoredAuthors[]? | select(. == $author)] | length' renovate.json)"

require_eq "$schema" "https://docs.renovatebot.com/renovate-schema.json" "schema mismatch"
require_eq "$extends0" "config:recommended" "extends mismatch"
require_eq "$min_age" "7 days" "minimumReleaseAge mismatch"
require_eq "$label0" "dependencies" "label mismatch"
require_eq "$ignored_author_count" "1" "gitIgnoredAuthors should include PR Upkeeper"

schedule0="$(yq -r '.on.schedule[0].cron' .github/workflows/renovate.yml)"
dispatch_count="$(yq -r '.on.workflow_dispatch | length' .github/workflows/renovate.yml)"
token_uses="$(yq -r '.jobs.renovate.steps[] | select(.id == "app_token") | .uses' .github/workflows/renovate.yml)"
checkout_uses="$(yq -r '.jobs.renovate.steps[] | select(.name == "Checkout") | .uses' .github/workflows/renovate.yml)"
renovate_uses="$(yq -r '.jobs.renovate.steps[] | select(.name == "Self-hosted Renovate") | .uses' .github/workflows/renovate.yml)"
token_expr="$(yq -r '.jobs.renovate.steps[] | select(.name == "Self-hosted Renovate") | .with.token' .github/workflows/renovate.yml)"
repo_expr="$(yq -r '.jobs.renovate.steps[] | select(.name == "Self-hosted Renovate") | .env.RENOVATE_REPOSITORIES' .github/workflows/renovate.yml)"

require_eq "$schedule0" "23 3 * * *" "Renovate schedule mismatch"
require_eq "$dispatch_count" "0" "workflow_dispatch should be an empty mapping"
require_eq "$token_uses" "actions/create-github-app-token@v3.2.0" "GitHub App token action mismatch"
require_eq "$checkout_uses" "actions/checkout@v7" "checkout action mismatch"
require_eq "$renovate_uses" "renovatebot/github-action@v46.1.16" "Renovate action mismatch"
require_eq "$token_expr" '${{ steps.app_token.outputs.token }}' "Renovate token mismatch"
require_eq "$repo_expr" '${{ github.repository }}' "RENOVATE_REPOSITORIES mismatch"

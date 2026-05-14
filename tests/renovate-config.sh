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
  if grep -Eq "$pattern" "$path"; then
    echo "$message: found pattern '$pattern' in $path" >&2
    exit 1
  fi
}

require_file "renovate.json"
require_file ".github/workflows/renovate.yml"
require_no_file ".github/workflows/renovate-review.yml"
require_no_match "README.md" 'RENOVATE_APP_SLUG' "README should not document an in-repo review workflow slug"
require_no_match "README.md" 'CLAUDE_CODE_OAUTH_TOKEN' "README should not document Claude review secret setup"

json_value() {
  ruby -rjson -e '
    data = JSON.parse(File.read(ARGV.shift))
    value = ARGV.reduce(data) do |current, key|
      key.match?(/\A\d+\z/) ? current.fetch(key.to_i) : current.fetch(key)
    end
    puts value
  ' "$@"
}

yaml_value() {
  ruby -ryaml -e '
    data = YAML.load_file(ARGV.shift)
    data["on"] = data.delete(true) if data.key?(true) && !data.key?("on")
    steps = data.fetch("jobs").fetch("renovate").fetch("steps")
    values = {
      "schedule0" => data.fetch("on").fetch("schedule").fetch(0).fetch("cron"),
      "dispatch_count" => (data.fetch("on")["workflow_dispatch"] || {}).length,
      "token_uses" => steps.find { |step| step["id"] == "app_token" }.fetch("uses"),
      "checkout_uses" => steps.find { |step| step["name"] == "Checkout" }.fetch("uses"),
      "renovate_uses" => steps.find { |step| step["name"] == "Self-hosted Renovate" }.fetch("uses"),
      "token_expr" => steps.find { |step| step["name"] == "Self-hosted Renovate" }.fetch("with").fetch("token"),
      "repo_expr" => steps.find { |step| step["name"] == "Self-hosted Renovate" }.fetch("env").fetch("RENOVATE_REPOSITORIES")
    }
    puts values.fetch(ARGV.fetch(0))
  ' .github/workflows/renovate.yml "$1"
}

ignored_author_count() {
  ruby -rjson -e '
    data = JSON.parse(File.read(ARGV.shift))
    author = ARGV.fetch(0)
    puts data.fetch("gitIgnoredAuthors", []).count(author)
  ' renovate.json "$1"
}

schema="$(json_value renovate.json '$schema')"
extends0="$(json_value renovate.json extends 0)"
min_age="$(json_value renovate.json minimumReleaseAge)"
label0="$(json_value renovate.json labels 0)"
ignored_author_count="$(ignored_author_count "PR Upkeeper <pr-upkeeper@brianjohn.com>")"

require_eq "$schema" "https://docs.renovatebot.com/renovate-schema.json" "schema mismatch"
require_eq "$extends0" "config:recommended" "extends mismatch"
require_eq "$min_age" "7 days" "minimumReleaseAge mismatch"
require_eq "$label0" "dependencies" "label mismatch"
require_eq "$ignored_author_count" "1" "gitIgnoredAuthors should include PR Upkeeper"

schedule0="$(yaml_value schedule0)"
dispatch_count="$(yaml_value dispatch_count)"
token_uses="$(yaml_value token_uses)"
checkout_uses="$(yaml_value checkout_uses)"
renovate_uses="$(yaml_value renovate_uses)"
token_expr="$(yaml_value token_expr)"
repo_expr="$(yaml_value repo_expr)"

require_eq "$schedule0" "23 3 * * *" "Renovate schedule mismatch"
require_eq "$dispatch_count" "0" "workflow_dispatch should be an empty mapping"
require_eq "$token_uses" "actions/create-github-app-token@v3.1.1" "GitHub App token action mismatch"
require_eq "$checkout_uses" "actions/checkout@v6.0.2" "checkout action mismatch"
require_eq "$renovate_uses" "renovatebot/github-action@v46.1.13" "Renovate action mismatch"
require_eq "$token_expr" '${{ steps.app_token.outputs.token }}' "Renovate token mismatch"
require_eq "$repo_expr" '${{ github.repository }}' "RENOVATE_REPOSITORIES mismatch"

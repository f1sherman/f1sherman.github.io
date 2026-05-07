#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

require_no_match() {
  local path="$1"
  local pattern="$2"
  local message="$3"
  if grep -REq "$pattern" "$path"; then
    echo "$message: found pattern '$pattern' in $path" >&2
    exit 1
  fi
}

require_no_match "Gemfile" 'jekyll-gist' "Gemfile should not depend on jekyll-gist"
require_no_match "Gemfile.lock" 'jekyll-gist' "Gemfile.lock should not include jekyll-gist"
require_no_match "_config.yml" 'jekyll-gist' "_config.yml should not enable jekyll-gist"
require_no_match "_posts" '\{%\s+gist' "Posts should not use gist embeds"

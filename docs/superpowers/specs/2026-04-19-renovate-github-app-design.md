# Renovate GitHub App Design

Date: 2026-04-19
Status: Approved for planning

## Summary

Add Renovate to this Jekyll blog repository using the same repository-owned GitHub Actions pattern as `new-machine-bootstrap`. The repo will gain a committed `renovate.json`, a scheduled Renovate runner workflow authenticated with a repo-scoped GitHub App, and a companion PR review workflow that comments on Renovate pull requests.

The configuration baseline should match the approved "B" option:

- `extends: ["config:recommended"]`
- `minimumReleaseAge: "7 days"`
- `labels: ["dependencies"]`

This work is intentionally narrow. It enables Renovate for the dependency types already present in this repo, keeps policy light, and avoids introducing broader dependency-management automation such as auto-merge or custom grouping.

## Current State

This repository is a small Jekyll site with:

- Ruby dependencies managed through `Gemfile` and `Gemfile.lock`
- GitHub Actions workflows under `.github/workflows/`
- a GitHub Pages deployment workflow in `.github/workflows/pages.yml`

It does not currently have:

- a root `renovate.json`
- any Renovate workflow
- any Dependabot configuration
- a Renovate PR review workflow

That means dependency updates for gems and GitHub Actions versions are currently manual.

## Goals

- Enable automated dependency update PRs for this repository
- Match the proven GitHub Actions and GitHub App pattern already used in `new-machine-bootstrap`
- Keep Renovate policy minimal and predictable
- Ensure Renovate-authored PRs trigger an AI review comment workflow
- Avoid changing the existing Pages deployment design

## Non-Goals

- Do not add auto-merge
- Do not add custom regex managers
- Do not add grouping or rate-limiting rules beyond the recommended baseline
- Do not move Renovate execution into another repository
- Do not change site code, content, or the Pages workflow behavior outside of dependency updates

## Chosen Approach

Three approaches were considered:

- Repository-local Renovate with parity baseline
- Repository-local Renovate with a minimal config
- Repository-local Renovate with extra grouping and PR-volume controls

The chosen approach is repository-local Renovate with parity baseline.

Why this approach:

- It matches the user's reference implementation in `new-machine-bootstrap`
- It is simple enough for this small repo
- It avoids drift between repositories without copying unnecessary custom manager logic
- It keeps future maintenance obvious: the committed config is the source of truth

## Architecture

Add three repository-owned pieces:

### 1. Root Renovate config

Create `renovate.json` at the repository root with:

- `"$schema": "https://docs.renovatebot.com/renovate-schema.json"`
- `extends: ["config:recommended"]`
- `minimumReleaseAge: "7 days"`
- `labels: ["dependencies"]`

No custom managers should be added in this repo unless a future dependency source cannot be covered by Renovate's built-in managers.

### 2. Renovate runner workflow

Create `.github/workflows/renovate.yml`.

This workflow should:

- run on a daily schedule
- support `workflow_dispatch`
- mint a short-lived installation token with `actions/create-github-app-token`
- check out the repository
- run `renovatebot/github-action`
- target only `${{ github.repository }}`

Use the same schedule shape as the reference repo:

```yaml
schedule:
  - cron: '23 3 * * *'
```

The workflow should use the GitHub App token for Renovate itself, not `GITHUB_TOKEN`.

### 3. Renovate PR review workflow

Create `.github/workflows/renovate-review.yml`.

This workflow should:

- trigger on pull request `opened`, `synchronize`, and `reopened`
- run only for Renovate-authored PRs
- install the Claude Code CLI
- inspect the PR title and body
- post a review comment back to the PR

The PR author gate must allow these exact identities:

- `renovate[bot]`
- `renovate-bot`
- `format('{0}[bot]', vars.RENOVATE_APP_SLUG)`

That keeps compatibility with hosted Renovate bot names while also supporting the repository's dedicated GitHub App bot identity.

## Authentication And Repository Settings

The Renovate runner should authenticate with a GitHub App installed only on this repository.

Required repository secrets:

- `RENOVATE_APP_ID`
- `RENOVATE_APP_PRIVATE_KEY`

Required repository variables:

- `RENOVATE_APP_SLUG`

Required additional review secret:

- `CLAUDE_CODE_OAUTH_TOKEN`

Why this design:

- the GitHub App token has the permissions Renovate needs
- the token is short-lived and minted at runtime
- PRs created with the App token can trigger downstream workflows correctly
- the bot login is stable enough to gate the review workflow exactly

The GitHub App should be installed only on `f1sherman/f1sherman.github.io`, not account-wide.

Required GitHub App permissions:

- Checks: read and write
- Commit statuses: read and write
- Contents: read and write
- Issues: read and write
- Pull requests: read and write
- Workflows: read and write
- Administration: read
- Dependabot alerts: read
- Members: read
- Metadata: read

The review workflow may still use the repository-provided `GITHUB_TOKEN` for reading PR metadata and posting its comment. The restriction in this design is only that Renovate itself must authenticate with the GitHub App token.

## Dependency Coverage

Initial dependency coverage should be only what Renovate already understands from this repository structure:

- Bundler dependencies from `Gemfile` and `Gemfile.lock`
- GitHub Actions versions in `.github/workflows/*.yml`

No custom extraction logic is needed for this repo at initial rollout.

## Data Flow

1. A scheduled run or manual dispatch starts `.github/workflows/renovate.yml`.
2. The workflow mints a short-lived GitHub App installation token.
3. Renovate reads the committed `renovate.json`.
4. Renovate scans the repository for supported managers.
5. Renovate opens or updates dependency PRs as the App bot.
6. A Renovate PR event triggers `.github/workflows/renovate-review.yml`.
7. The review workflow posts an AI-generated dependency review comment.

## Error Handling

- Missing or invalid Renovate App secrets should fail the runner workflow in the token step.
- A wrong `RENOVATE_APP_SLUG` value should not block Renovate itself, but it will prevent the review workflow from running on App-authored PRs.
- A missing `CLAUDE_CODE_OAUTH_TOKEN` should fail only the review workflow; the dependency PR remains usable.
- `GITHUB_TOKEN` should not be used as the Renovate run token, because that can suppress expected follow-on workflow behavior on Renovate PRs.

## Verification

Implementation is not complete until both local static checks and a GitHub-side smoke test pass.

Minimum local verification:

- validate the committed `renovate.json`
- validate that `.github/workflows/renovate.yml` contains the daily schedule, `workflow_dispatch`, GitHub App token minting, and `renovatebot/github-action`
- validate that `.github/workflows/renovate-review.yml` contains the exact Renovate bot gate including `vars.RENOVATE_APP_SLUG`

Post-configuration smoke test:

- set the required repository secrets and variable
- manually dispatch `renovate.yml`
- confirm the workflow run succeeds
- confirm Renovate opens or updates PRs if updates are available
- confirm a Renovate PR triggers the review workflow

## Expected Files To Change During Implementation

- `renovate.json`
- `.github/workflows/renovate.yml`
- `.github/workflows/renovate-review.yml`
- `README.md` if setup or verification notes need to be documented there

## Out Of Scope Follow-Up Work

Reasonable future additions, but not part of this design:

- auto-merge for selected update classes
- package grouping rules
- PR-rate limiting rules
- custom managers for non-standard pinned versions
- caching or other GitHub Actions runtime optimizations

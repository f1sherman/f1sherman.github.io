# Renovate GitHub App Design

Date: 2026-04-19
Status: Approved for planning

## Summary

Add Renovate to this Jekyll blog repository using the same repository-owned GitHub Actions pattern as `new-machine-bootstrap`. The repo will gain a committed `renovate.json` and a scheduled Renovate runner workflow authenticated with a repo-scoped GitHub App. Dependency PR review is handled outside GitHub by Codex, so this repository should not carry a companion review workflow.

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

That means dependency updates for gems and GitHub Actions versions are currently manual.

## Goals

- Enable automated dependency update PRs for this repository
- Match the proven GitHub Actions and GitHub App pattern already used in `new-machine-bootstrap`
- Keep Renovate policy minimal and predictable
- Keep PR review outside repository-managed GitHub Actions
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

Add two repository-owned pieces:

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

## Authentication And Repository Settings

The Renovate runner should authenticate with a GitHub App installed only on this repository.

Required repository secrets:

- `RENOVATE_APP_ID`
- `RENOVATE_APP_PRIVATE_KEY`

Why this design:

- the GitHub App token has the permissions Renovate needs
- the token is short-lived and minted at runtime
- review automation is intentionally decoupled from repository-managed GitHub Actions

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
6. Any follow-on PR review happens outside this repository's GitHub Actions configuration.

## Error Handling

- Missing or invalid Renovate App secrets should fail the runner workflow in the token step.
- `GITHUB_TOKEN` should not be used as the Renovate run token, because that can suppress expected follow-on workflow behavior on Renovate PRs.

## Verification

Implementation is not complete until both local static checks and a GitHub-side smoke test pass.

Minimum local verification:

- validate the committed `renovate.json`
- validate that `.github/workflows/renovate.yml` contains the daily schedule, `workflow_dispatch`, GitHub App token minting, and `renovatebot/github-action`
- validate that `.github/workflows/renovate-review.yml` is absent

Post-configuration smoke test:

- set the required repository secrets
- manually dispatch `renovate.yml`
- confirm the workflow run succeeds
- confirm Renovate opens or updates PRs if updates are available
- confirm no repository-managed review workflow is triggered

## Expected Files To Change During Implementation

- `renovate.json`
- `.github/workflows/renovate.yml`
- `README.md` if setup or verification notes need to be documented there

## Out Of Scope Follow-Up Work

Reasonable future additions, but not part of this design:

- auto-merge for selected update classes
- package grouping rules
- PR-rate limiting rules
- custom managers for non-standard pinned versions
- repository-managed Renovate PR review automation
- caching or other GitHub Actions runtime optimizations

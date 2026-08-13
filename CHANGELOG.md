# Changelog

All notable changes to this project will be documented in this file. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed
- Onboarding reduced to three quick selections: multi-select learning goals with six suggested examples (core standards, emerging edge, agentic security, career signal, ecosystem deep-dive, product/PM lens), a defaults-or-changes sources question that names the current defaults, and a confirm-style cadence question.
- Repo root is now the skill directory itself (`SKILL.md` at top level): install by cloning straight into `~/.claude/skills/scout`, update with `git pull`. Helper scripts remain a copy-on-install step by design (auto-executing hook code should never update silently via pull).

## [0.1.0] - 2026-08-13

### Added
- Initial public version of the scout skill, generalized from a personal GenAI-tracking setup:
  - discovery/corroboration source model with per-user swappable sources (`profile.json`) and a fitness check for added channels
  - traction gate for emerging tools (≥2 independent channels ≥14 days apart + third-party usage evidence) and concepts (two independent voices)
  - promotion review on shortlist entry: negative-signals search, comparables check with replacement, four-dimension 1–5 scoring (standard / emerging / friction / value)
  - re-evaluation paths for shortlist leavers: activity trigger, monthly `revisit_if` sweep, decline cooldown
  - auto-built living project profile: ask-once tracking (track / decline / defer), summaries self-filled from CLAUDE.md/README with hash-based refresh, activity decay, decline-driven corrections
  - suggestion cards with star scores, caveats, alternatives, dual citation, and a weekly cap (configurable); `suggest` is the default mode
  - SessionStart hook for daily background refresh (`scripts/check-due.sh`) and an allow-listable JSON validator (`scripts/validate.sh`)

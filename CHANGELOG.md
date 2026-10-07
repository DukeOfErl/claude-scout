# Changelog

All notable changes to this project will be documented in this file. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- State persistence: when `~/.claude/scout/` sits in a git working tree other than the skill repo, every run that changes state ends with a commit of the three state files, staged and committed by explicit path so nothing else the user had staged is swept in; ignored, untracked state is left alone. A failed commit is recorded as `state.json.uncommitted_since` and reported, never worked around. Pushing happens only in a foreground session after the user says yes, never to a public remote, and never from a background run. A rule keeps material the user holds apart from their code repositories out of scout state.

### Changed
- Suggestion cap is now a minimum gap rather than a per-week count: `profile.json.user.max_suggestions_per_week` is replaced by `min_days_between_suggestions` (default 7). The old key could not be enforced from the single `state.json.last_suggestion_date` the skill stores — counting suggestions within a window needs a list of dates, while a minimum gap needs only the most recent one. Onboarding, the `suggest` cap rule and the README now describe the gap.

## [0.1.0] - 2026-08-13

### Added
- Pain-point-first README (title, problems/solution table), with a minimal skill-only install path, optional helpers, a prominent first-run section, and an MIT license note.
- Three-selection onboarding in one dialog (suggested learning goals, defaults-or-changes sources, confirm-style cadence); layout mock-validated.
- Repo root is the skill directory itself: install by cloning into `~/.claude/skills/scout`, update with `git pull`; helper scripts are copy-on-install by design.
- Initial public version of the scout skill, generalized from a personal GenAI-tracking setup:
  - discovery/corroboration source model with per-user swappable sources (`profile.json`) and a fitness check for added channels
  - traction gate for emerging tools (≥2 independent channels ≥14 days apart + third-party usage evidence) and concepts (two independent voices)
  - promotion review on shortlist entry: negative-signals search, comparables check with replacement, four-dimension 1–5 scoring (standard / emerging / friction / value)
  - re-evaluation paths for shortlist leavers: activity trigger, monthly `revisit_if` sweep, decline cooldown
  - auto-built living project profile: ask-once tracking (track / decline / defer), summaries self-filled from CLAUDE.md/README with hash-based refresh, activity decay, decline-driven corrections
  - suggestion cards with star scores, caveats, alternatives, dual citation, and a weekly cap (configurable); `suggest` is the default mode
  - SessionStart hook for daily background refresh (`scripts/check-due.sh`) and an allow-listable JSON validator (`scripts/validate.sh`)

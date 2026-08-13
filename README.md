# Scout

A [Claude Code](https://claude.com/claude-code) skill that tracks curated GenAI sources, filters new tools and concepts through a **traction gate** (only things proven beyond their own developers), runs a **promotion review** on survivors (critical reviews, comparable tools, four-dimension scoring), and occasionally suggests **exactly one** item — matched to your projects and learning goals, capped (default: one per week) so it informs instead of overwhelming.

```
╭──────────────────────────────────────────────────╮
  LANGFUSE  ·  tool  ·  standard

  Standard  ★★★★☆     Emerging  ★★★☆☆
  Friction  ★★☆☆☆     Value     ★★★★☆
  ───────────────────────────────────────────────
  Open-source LLM tracing/observability + evals;
  drop-in LangChain callback.

  Caveats:       self-host stack is heavy — use cloud tier
  Alternatives:  Arize Phoenix — best no-SaaS fallback
  Sources:  langfuse.com · via LangSmith comparables review
╰──────────────────────────────────────────────────╯
```

## How it works

- **Discovery**: fetches curated channels (defaults: [GenAI PM wiki](https://genaipm.com/wiki/tools?sort=recent), [AI News](https://news.smol.ai/rss.xml), [TLDR AI](https://tldr.tech/api/rss/ai)) and records dated sightings per item.
- **Traction gate**: emerging tools need sightings in ≥2 independent channels ≥14 days apart **plus** third-party usage evidence before they can be suggested. No launch hype.
- **Promotion review**: on shortlist entry, every item gets a negative-signals search (trusted critics), a comparables check (a clearly better alternative *replaces* the item), and 1–5 scores: how standard, how emerging, friction (for *you*), value (to *your* projects).
- **Living profile**: scout asks once per project whether to track it ("track / don't / ask me later"), self-fills descriptions from your CLAUDE.md/README, refreshes them when those files change, and stops targeting projects you haven't touched in weeks.
- **Suggestions**: at most one per week (configurable), only at opportune moments (stage match or lull), always with the score card, caveats, alternatives, and dual citation (aggregator + original source).

## Install

1. Copy the skill and helper scripts:
   ```bash
   mkdir -p ~/.claude/skills/scout ~/.claude/scout
   cp skill/SKILL.md ~/.claude/skills/scout/SKILL.md
   cp scripts/check-due.sh scripts/validate.sh ~/.claude/scout/
   ```
2. Add the daily trigger — a SessionStart hook in `~/.claude/settings.json` (reminds Claude to refresh at most once a day, only on days you actually work):
   ```json
   "hooks": {
     "SessionStart": [
       { "hooks": [ { "type": "command", "command": "bash \"$HOME/.claude/scout/check-due.sh\"" } ] }
     ]
   }
   ```
3. **Recommended permission allow-rules** (in `~/.claude/settings.json` → `permissions.allow`) so background runs don't prompt you. Read these before adding — each grants something consciously:
   ```json
   "Read(~/.claude/skills/**)",
   "Read(~/.claude/scout/**)",
   "Write(~/.claude/scout/**)",
   "Edit(~/.claude/scout/**)",
   "Bash(bash ~/.claude/scout/validate.sh:*)",
   "WebFetch(domain:genaipm.com)",
   "WebFetch(domain:news.smol.ai)",
   "WebFetch(domain:tldr.tech)",
   "WebFetch(domain:huggingface.co)",
   "WebSearch"
   ```
   Rationale: the first five confine writes to scout's own state dir plus one fixed validation script; the WebFetch rules are scoped to the default source domains only (swap them if you swap sources); `WebSearch` is the one broad grant — queries go only to the search provider (no third-party host sees them), but if you prefer to approve each search, omit it and expect prompts during promotion reviews.
4. Start a new Claude Code session anywhere and run `/scout` — the first run walks you through onboarding (cadence, learning goals, keep/trim/add sources) and starts building your project profile.

## Usage

- `/scout` — suggest one worthwhile item now (or hear honestly that nothing clears the bar)
- `/scout scout` — force a manual refresh (normally happens daily in the background)
- `/scout status` — digest, statuses, whether the suggestion slot is open

Your `~/.claude/scout/` state (digest, profile, scores) is **personal and local** — two people with identical rules get different digests, by design. Don't commit it.

## Contributing

- Branch per change, PR to `main`, keep `CHANGELOG.md` current.
- **Proposing a new source**: state its role — *discovery* (broad, aggregated, recurring), *corroboration* (independent hands-on voices), or *calibration* (periodic adoption-staged reports) — and why it won't smuggle launch hype into the discovery role. Single-voice diaries don't qualify for discovery.
- **Gate/scoring changes are policy debates**: the PR diff of `skill/SKILL.md` *is* the proposal; argue it in the PR.
- Share conclusions ("X beat Y for solo devs") in discussions or notes — never your state files.

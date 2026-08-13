# Scout — turn GenAI overwhelm into just-in-time project-targeted suggestions

A [Claude Code](https://claude.com/claude-code) skill that watches the GenAI firehose for you and occasionally surfaces **exactly one** vetted, scored, project-matched suggestion.

## The problems

Keeping up with GenAI feels like this:

- **Too much, too fast.** Fifty launches a week, five newsletters a day. Reading it all is a part-time job; skipping it all feels like falling behind.
- **Hype is indistinguishable from traction.** Everything trends on launch day. By the time you try the viral thing, it's abandoned — or nobody beyond its own developers ever actually used it.
- **You only hear the pitch.** Announcements don't mention the 51% hallucination rate, the pricing cliff, or the better-established alternative.
- **None of it knows what you're building.** Generic roundups can't say whether a tool fits your stack, your project stage, or your learning goals.
- **It arrives at the wrong moment.** The interesting link lands while you're heads-down, and dies in a tab.

## The solution

Five mechanisms, each aimed at a pain point:

| Mechanism | Addresses |
|---|---|
| **Traction gate** — emerging items need sightings in ≥2 independent sources ≥14 days apart, plus third-party usage evidence | Launch hype, single-dev demos |
| **Promotion review** — critical-reviews search + comparables check before anything becomes suggestible; a clearly better alternative *replaces* the item | One-sided pitches, missed alternatives |
| **Scored cards** — standard / emerging / friction / value, 1–5 | Judgment at a glance instead of vibes |
| **Living project profile** — auto-built from your repos, refreshed as they change, dormant when you stop touching them | Generic, stack-blind recommendations |
| **Cap + timing** — default one suggestion per week, offered only at a stage match or a lull | Overwhelm, badly timed interruptions |

A suggestion looks like this:

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

A daily background run (via an optional hook) fetches curated channels — defaults: [GenAI PM wiki](https://genaipm.com/wiki/tools?sort=recent), [AI News](https://news.smol.ai/rss.xml), [TLDR AI](https://tldr.tech/api/rss/ai); swappable at onboarding — records dated sightings per item, applies the gate and review, and rewrites your personal digest (a scored shortlist plus a watching list with promote-conditions). Suggestions draw only from the reviewed shortlist and always carry the card, the caveats, and a dual citation: the aggregator *and* the original source. Scout asks once per project whether to track it ("track / don't / ask me later") and keeps descriptions fresh from your CLAUDE.md/README automatically.

## Install

**Minimal — just the skill.** The skill is a single file and works on its own: copy `SKILL.md` to `~/.claude/skills/scout/SKILL.md` and run `/scout`. Onboarding, suggestions, and manual refreshes (`/scout scout`) all work. Everything else in this section is optional convenience: without the hook you refresh manually instead of getting a daily background nudge, and without the allow-rules/validator you'll click through some permission prompts during background runs. Skip what you don't want.

**Recommended — clone + helpers:**

1. Clone this repo as the skill — functionally identical to copying, but updates become `git pull` and contributing back is a branch away:
   ```bash
   git clone https://github.com/DukeOfErl/claude-scout.git ~/.claude/skills/scout
   mkdir -p ~/.claude/scout
   cp ~/.claude/skills/scout/scripts/*.sh ~/.claude/scout/
   ```
   The helper scripts (`check-due.sh` — the daily-refresh nudge; `validate.sh` — prompt-free JSON validation) are **deliberately copied, not run from the clone**: the SessionStart hook executes automatically, so auto-running it from a pull-updated checkout would let any upstream change execute on your machine unreviewed. After a `git pull` that touches `scripts/`, review the diff, then re-copy.
2. Add the daily trigger (optional) — a SessionStart hook in `~/.claude/settings.json` (reminds Claude to refresh at most once a day, only on days you actually work):
   ```json
   "hooks": {
     "SessionStart": [
       { "hooks": [ { "type": "command", "command": "bash \"$HOME/.claude/scout/check-due.sh\"" } ] }
     ]
   }
   ```
3. **Permission allow-rules** (optional, in `~/.claude/settings.json` → `permissions.allow`) so background runs don't prompt you. Read these before adding — each grants something consciously:
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
## First run (both install types)

**Start a new Claude Code session anywhere and run `/scout`.** The first run walks you through a three-question onboarding — learning goals, sources (keep the defaults or change them), suggestion cadence — and starts building your project profile.

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

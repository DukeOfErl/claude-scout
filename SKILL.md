---
name: scout
description: Track curated GenAI sources, maintain a traction-gated, reviewed and scored digest of tools/concepts, and suggest one high-value item at opportune moments, matched to the user's projects and learning goals. Modes — suggest (default), scout (background refresh), status.
---

# Scout — GenAI tool & concept tracking

Scout watches curated GenAI sources, filters for things that have proven value beyond their own developers, reviews and scores the survivors, and occasionally suggests exactly one — matched to what the user is building and learning.

State lives in `~/.claude/scout/`:
- `state.json` — tracked items (machine state)
- `profile.json` — the user: suggestion cadence, learning goals, sources (with roles), and tracked projects
- `digest.md` — the human-readable shortlist + watching list

**File access (avoid permission prompts):** use the **Read/Write/Edit tools** for these files; shell reads/writes (`python3 -c`, `cat`, `jq`) will prompt. Never `cd` — use absolute paths. Validate JSON after writing with `bash ~/.claude/scout/validate.sh [file]` (allow-listed) — or, on script-less installs where that file doesn't exist, any equivalent JSON parse check (it may prompt; that's expected).

Mode is the first argument: **`suggest` (default when no argument)**, `scout`, or `status`.

## Persisting state (git)

Scout state is the record of weeks of sightings and reviews. If it lives only on disk, nothing signals when it is lost. So when the user keeps it under version control, every run that changes it ends with a commit.

- **When.** Commit only if `~/.claude/scout/` sits inside a git working tree (`git -C ~/.claude/scout rev-parse --show-toplevel` succeeds) **and** that top level differs from this skill's own (`git -C <skill dir> rev-parse --show-toplevel`). State is personal and must never enter the published skill repo. With no such tree, skip silently. Also skip silently when the state files are ignored there and not tracked (`git check-ignore` matches): the user chose not to version them.
- **What.** Stage the state files by explicit path only (`state.json`, `digest.md`, `profile.json`), never `git add -A`: the same repository may hold unrelated work. For the same reason, commit those paths only, `git commit -m "…" -- state.json digest.md profile.json`, so nothing the user had already staged is swept in. Skip the commit when nothing changed.
- **Message.** `scout: <mode> <ISO date> — <one line on what changed>`, e.g. `scout: scout 2026-10-07 — 2 sightings, Foo promoted`.
- **Before staging, check what you wrote.** Fit notes describe a project from its own repository. Never copy into scout state material the user keeps deliberately apart from their code repositories, such as a private planning repo or personal, financial or HR matters. The state repo may have a different audience from that material.
- **If the commit fails** (a held `index.lock`, a read-only `.git` under a sandbox): do not retry, and do not work around it. Set `state.json.uncommitted_since` (ISO date, kept from the first failure) and say so in the run's report, so a foreground session can tell the user. Clear the key after the next successful commit.
- **Push only with permission.** Pushing is outward-facing. A background run never pushes and never asks. It reports how many commits are ahead of upstream. A foreground session asks the user once per session, showing the count and the remote, and pushes only on an explicit yes. Never push the state to a public remote. If the remote's visibility is unknown, say so in the question.

## First run / onboarding

If `profile.json` doesn't exist: create it from the defaults in this file's Sources section, then run a **three-selection onboarding**. Where AskUserQuestion is available, bundle all three as ONE call (three questions, one dialog — a single setup moment, never a form or free-text essay). Note the component's 4-options-per-question limit; the layouts below respect it.

1. **Learning goals** — multi-select: *"What are you tracking for? Pick 1–3 — these become your learning goals and steer what gets suggested."* Show these four options; fold the last two examples into the fourth option's description as an "Other examples: ... — write your own via Other" hint. Selections become `profile.json.user.learning_goals` verbatim (an "Other" free-text answer is equally valid):
   - **Core standards** — the tools everyone assumes an AI engineer knows (evals, observability, orchestration, RAG patterns)
   - **Emerging edge** — catch rising tools/concepts before they're mainstream
   - **Agentic security** — prompt injection, sandboxing, permissions, secure agent design
   - **Career signal** — what shows up in AI-engineer job postings and interviews right now *(+ hint: ecosystem deep-dive of one named stack; product/PM capability lens)*
   Goals steer scoring: they shape the `value` dimension and fit-matching, so record them exactly as chosen.
2. **Sources** — name the current defaults explicitly and ask defaults-or-changes: *"Default sources: GenAI PM wiki, AI News (Smol AI), TLDR AI (discovery) + HF daily papers, pasted briefs (corroboration). Use defaults?"* Options: **Use defaults (Recommended)** / **Make changes**. On changes, a follow-up dialog: Add a source / Remove a default / Both (removal picks from the defaults via multi-select — mind the 4-option limit, put the fifth behind Other). Any **added** source gets a quick fitness check before it counts: is it **discovery** material (broad, aggregated, recurring coverage), **corroboration** (independent hands-on voices, single-perspective diaries), or **calibration** (periodic adoption-staged reports)? Single-voice or launch-hype feeds must not enter the discovery role — that would defeat the traction gate.
3. **Cadence** — confirm, don't interrogate: *"Suggestion cap — at least how many days between unprompted suggestions?"* with **7 days (Recommended)** first. Store as `profile.json.user.min_days_between_suggestions`.

The new-project ask (see Profile maintenance) arrives as its own contextual dialog — "scout noticed you're working in <dir>..." — not folded into the setup bundle.

## Profile maintenance (runs opportunistically in any mode)

- **New projects:** when running in a working directory whose project isn't in `profile.json.projects`, ask once: track it for tool/concept matching? Three answers: `tracking` / `declined` (never ask again) / `deferred` (re-ask when the project gains substance: CLAUDE.md acquires a "What this is" section, or real source files appear). On `tracking`, self-fill the entry: summary from CLAUDE.md's "What this is" → README fallback → one-line ask; stack from manifests (pyproject/package.json); record `derived_from` with a 16-char sha256 of the summary's source file. If the user can't describe a greenfield project yet, record `direction: "still exploring"` — fit-matching then favors learning value and broadly applicable items for it.
- **Refresh:** when running in a tracked project, compare the stored hash against the current file; on material change, re-derive the summary silently (tracking consent already given). Update `last_seen` on every run in that project.
- **Decay:** projects with `last_seen` older than ~3 weeks are treated as dormant — they stop attracting suggestions until a session touches them again. Never delete entries.
- **Corrections:** when the user declines a suggestion because the *project description* is wrong ("we don't do X anymore"), fix the profile entry, not just the item.

## Sources

Read the live list from `profile.json.sources`. Each source has a `role`:
- **discovery** — may seed new items and counts as an independent channel for the gate
- **corroboration** — never seeds items; corroborates existing ones (concepts especially)

Default channels (shipped with the skill; users may swap):
- GenAI PM wiki (discovery): https://genaipm.com/wiki/tools?sort=recent + https://genaipm.com/wiki/concepts?sort=recent
- AI News / Smol AI (discovery): https://news.smol.ai/rss.xml
- TLDR AI (discovery): https://tldr.tech/api/rss/ai — skip raw arXiv items for the tools track
- Hugging Face daily papers API (corroboration, concepts only)
- Pasted briefs (corroboration): newsletter content the user pastes into a session

`user-submitted` is always a valid sighting source: the user explicitly asking to track something counts as one independent channel for the gate.

## `scout` — refresh the digest (run as a background agent; never block project work; the SessionStart hook requests this daily)

1. Fetch the discovery channels from the profile. Diff against `state.json.items` (match by `id` = kebab slug; dedupe name variants).
2. For every sighting of a tracked item, append to its `sources`: `{source: <profile source name>|user-submitted, date}` (one entry per source per day; refresh `mentions` where the source provides counts). For each genuinely new item worth tracking, record: `id`, `name`, `type` (`tool`|`concept`), `genaipm_url`/reference URL (null if none), `sources` (seeded with the discovering channel), `original_source` + `original_source_link` (one quick WebSearch for the strongest candidates if only named), `class` (`standard` | `emerging` | `niche`), `hurdle` (`low`|`med`|`high`), `project_fit_notes` (one line, against the profile's tracked projects), `first_seen`, `status` (`new` for standard, **`watching` for emerging**), `traction_evidence: []`.
3. **Traction gate** — only emerging things that have shown value beyond their own developers:
   - `emerging` **tools** need ALL of: (a) sightings in ≥2 independent discovery channels ≥14 days apart, and (b) ≥1 `traction_evidence` entry — third-party usage by someone other than the vendor (practitioner writeup, integration by another product; for OSS, strong download trends or GitHub dependents). Hunt for evidence with one targeted WebSearch **at promotion time only**. Record as `{type, note, url, date}`.
   - `emerging` **concepts** need only (a) — two independent voices (original author + independent amplifier counts).
   - `standard` items skip the gate; `niche` items stay off the shortlist regardless.
   - Passing the gate triggers the **promotion review**; only items that clear it become `shortlisted`. `watching` items are NEVER suggested.
4. **Promotion review** — once, whenever an item first enters the Shortlist (emerging AND standard alike):
   - **Negative signals**: WebSearch for substantive criticism from trusted sources (practitioners, engineering blogs, quality HN/Reddit threads). Record `negative_signals: [{source, note, url, date, outcome}]` and act: `disqualify` (→ status `rejected`, with reason), `restrict` (narrow `project_fit_notes` to surviving use cases), `friction` (raise the friction score/hurdle), or `noted` (doesn't outweigh value — say why).
   - **Comparables**: 1–3 alternatives — better-established or better-fitting for this user's profile. Record `alternatives: [{name, verdict}]`. If one is *clearly* better, track it instead (with its own review) and demote the original with a pointer.
   - **Scores** (1–5, honest judgment): `standard` (how established), `emerging` (rising-star strength), `friction` (learning + implementation burden *for this user*; 5 = heavy), `value` (to tracked projects + learning goals). Record as `scores: {...}`.
5. **Re-evaluation of past shortlist leavers:**
   - On any demotion, record `demoted_date` + a concrete `revisit_if` one-liner.
   - **Activity trigger** (every run): a `demoted`/`rejected` item with a fresh burst (≥2-channel sightings since demotion, or a major new development) gets a fresh promotion review.
   - **Periodic sweep** (first run of each calendar month): skim `revisit_if` conditions; where one plausibly holds, verify with one WebSearch and re-review. Note the sweep in the digest header.
   - `declined` items re-enter only after their 30-day cooldown AND newly stronger fit; `adopted` items never need re-promotion.
6. Rewrite `digest.md`: a **Shortlist** of the ~5–10 strongest reviewed candidates (each: 2-line description, the four scores as stars, standard-vs-emerging framing, project fit, Caveats line, Alternatives line, hurdle, citation pair) and a compact **Watching** section (one line per item: what would promote it). Capacity demotions drop the weakest-scored item. Never delete `state.json` records.
7. Set `state.json.last_checked` (ISO date); validate JSON after writing.
8. Persist: commit per **Persisting state (git)**, and include in the report the commit hash (or why there is none) and the number of unpushed commits.

## `suggest` (default mode) — surface one item

**Cap (from `profile.json.user.min_days_between_suggestions`, default 7): an unprompted suggestion is allowed only when today minus `state.json.last_suggestion_date` is at least that many days; applies across all sessions.** (A single stored date is enough for a minimum-gap rule; it was not enough for the earlier per-week count, which is why that key was replaced on 2026-09-03.) An explicit `/scout` invocation overrides the cap; an unprompted suggestion never does. Only `shortlisted`/`new`-standard items are eligible — never `watching` (even when invoked; explain what's still unproven instead). Zero is a fine outcome — when invoked with nothing clearing the bar, say so usefully: name the closest candidates and what would promote them.

**Timing (for unprompted suggestions).** Only at: **stage match** (the item concretely helps the task in front of the user) or **lull** (work package just merged / exploratory session). Never mid-large-change, mid-debug, or heads-down.

**Selection.** Judge eligible candidates on: value to the current project, value to learning goals (standard-you-should-know vs emerging-stay-ahead), friction, and priority fit (would adopting it displace higher-priority work?). Pick at most one. Skip `declined` (30-day cooldown) and `snoozed` (until date); repeat a `suggested` item only if the fit is newly stronger.

**Mandatory format.**
1. Open by stating explicitly that this comes from the scout tracking scheme.
2. Show the **card** — fixed template, fenced code block (stars: `★` filled, `☆` empty, from `scores`):
   ```
   ╭──────────────────────────────────────────────────╮
     <NAME>  ·  <tool|concept>  ·  <standard|emerging>
   
     Standard  ★★★★☆     Emerging  ★★☆☆☆
     Friction  ★★☆☆☆     Value     ★★★★★
     ───────────────────────────────────────────────
     <2–3 line summary: what it is, why it matters>
   
     Caveats:       <top negative signal, or "none material">
     Alternatives:  <best alternative — verdict, or "none better">
     Sources:  <aggregator URL> · <original source>
   ╰──────────────────────────────────────────────────╯
   ```
3. Below the card: the considerations (project value, learning value, priority fit), **why this moment** (stage match or lull), and for `emerging` items the traction evidence. Link the original source if traceable; name it with a note if not.
4. Offer the **full brief** (all sightings, evidence, negative signals, alternatives, fit reasoning from `state.json`) on request.
5. End with a clear no-pressure out (adopt now / park it / not interested).

Afterwards update `state.json`: item `status` (`suggested`, then `adopted`/`declined`/`snoozed` per the user's reaction) and `last_suggestion_date`. Then persist per **Persisting state (git)**. This is a foreground session, so if commits are unpushed, ask about pushing here.

## `status` — report

Show `digest.md` (shortlist + watching), item statuses, `last_checked`, `last_suggestion_date`, whether the suggestion slot is open, and the profile's tracked projects. Also show `uncommitted_since` if set, and the number of unpushed state commits. Read-only, except for the push question, which `status` may ask per **Persisting state (git)**.

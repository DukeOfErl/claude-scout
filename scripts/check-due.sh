#!/usr/bin/env bash
# SessionStart hook: remind Claude to run the scout background run when it's stale (>24h).
# Prints nothing when the check is fresh, so most sessions see no output.
STATE="$HOME/.claude/scout/state.json"
python3 - "$STATE" <<'EOF'
import json, sys, datetime

try:
    state = json.load(open(sys.argv[1]))
    last = state.get("last_checked")
except Exception:
    last = None

due = True
if last:
    try:
        days = (datetime.date.today() - datetime.date.fromisoformat(last[:10])).days
        due = days >= 1
    except Exception:
        due = True

if due:
    print(
        "Scout: the daily scouting run is due. At the first natural pause, "
        "run the scout skill's `scout` mode in a background agent (policy in "
        "~/.claude/skills/scout/SKILL.md). Also consult ~/.claude/scout/digest.md "
        "during this session for suggestion opportunities, per the profile's cap and timing rules."
    )
EOF

#!/usr/bin/env bash
# SessionStart hook for scout. Prints nothing when there is nothing to say, so most sessions see
# no output. Otherwise prints one JSON object:
#   additionalContext  (to Claude)  the daily scouting run is due; a suggestion is due
#   systemMessage      (to the user) no suggestion for SILENCE_DAYS days: scout may not be firing
STATE="$HOME/.claude/scout/state.json"
PROFILE="$HOME/.claude/scout/profile.json"
python3 - "$STATE" "$PROFILE" <<'EOF'
import datetime
import json
import sys

SILENCE_DAYS = 7  # no suggestion at all for this long means the user should hear about it


def load(path):
    try:
        with open(path) as handle:
            return json.load(handle)
    except Exception:
        return {}


def days_since(value, today):
    try:
        return (today - datetime.date.fromisoformat(str(value)[:10])).days
    except Exception:
        return None


state, profile = load(sys.argv[1]), load(sys.argv[2])
today = datetime.date.today()
context, warning = [], None

checked = days_since(state.get("last_checked"), today)
if checked is None or checked >= 1:
    context.append(
        "Scout: the daily scouting run is due. At the first natural pause, run the scout "
        "skill's `scout` mode in a background agent (policy in ~/.claude/skills/scout/SKILL.md)."
    )

cap = profile.get("user", {}).get("min_days_between_suggestions", 7)
silent = days_since(state.get("last_suggestion_date"), today)
eligible = [
    item.get("name", item.get("id"))
    for item in state.get("items", [])
    if item.get("status") == "shortlisted"
    or (item.get("status") == "new" and item.get("class") == "standard")
]
if eligible and (silent is None or silent >= cap):
    context.append(
        f"Scout: a suggestion is due (last one {silent if silent is not None else 'never'} "
        f"days ago, cap {cap}; {len(eligible)} eligible items in ~/.claude/scout/digest.md). "
        "Look for a stage match or a lull this session and follow the skill's `suggest` rules, "
        "including the suggestion_log entry."
    )

# A fresh install has never suggested anything and has nothing eligible yet: that is not silence.
if (silent is not None and silent >= SILENCE_DAYS) or (silent is None and eligible):
    warning = (
        f"Scout has not suggested anything for {silent if silent is not None else 'an unknown number of'} "
        f"days (last: {state.get('last_suggestion_date') or 'never'}). Something may be off; "
        "run /scout status to check."
    )

if context or warning:
    output = {}
    if warning:
        output["systemMessage"] = warning
    if context:
        output["hookSpecificOutput"] = {
            "hookEventName": "SessionStart",
            "additionalContext": "\n".join(context),
        }
    print(json.dumps(output))
EOF

#!/usr/bin/env bash
# Validate scout state.json (or a given file) parses as JSON. Allow-listed in settings.
f="${1:-$HOME/.claude/scout/state.json}"
python3 -c "import json,sys; json.load(open(sys.argv[1])); print('valid JSON:', sys.argv[1])" "$f"

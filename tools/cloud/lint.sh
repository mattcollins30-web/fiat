#!/bin/bash
# lint.sh <workspace> [port] : the project's own warnings check (tools/gdlint.py via Godot's language server, ~2.5 min).
# TOTAL must be 0. Each builder its own port so two runs don't collide.
. "$(dirname "$0")/env.sh"
cd $S && timeout 500 python3 $1/tools/gdlint.py "$GODOT" $1 ${2:-6011} 2>&1 | tail -40

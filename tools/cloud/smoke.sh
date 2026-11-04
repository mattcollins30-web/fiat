#!/bin/bash
# smoke.sh <workspace> [-- only <area> ...] : the full smoke in the cloud (Godot 4.7.2 as on Matt's machine, xvfb).
# The bar: 0 CHECK FAILED, 0 SCRIPT ERROR, and the log ends "all labels fit, all checks pass". A full run takes 10-25
# min (longer with builders sharing the CPUs): run it in the background (`nohup ... &`) and poll the log - a run cut
# short prints "fails 0" with no verdict line. The workspace needs .godot/imported (copy it from the base).
. "$(dirname "$0")/env.sh"
d=$1; shift
mkdir -p $S/.xdg_$d; cd $S/$d && XDG_DATA_HOME=$S/.xdg_$d timeout 1700 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . -s res://tests/smoke.gd "$@" > $S/$d.smoke.log 2>&1
echo "fails $(grep -c 'CHECK FAILED' $S/$d.smoke.log) errors $(grep -c 'SCRIPT ERROR' $S/$d.smoke.log)"; grep -E "all labels fit|labels do not fit" $S/$d.smoke.log | tail -1

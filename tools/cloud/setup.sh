#!/bin/bash
# setup.sh <base name> <head.tar> [art_untracked.tar] : a fresh base workspace from Matt's HEAD (a `git archive` tar
# staged up from his machine) plus his untracked art, and Godot 4.7.2 if it isn't there. The base is never written to.
. "$(dirname "$0")/env.sh"
b=$1; mkdir -p $S && rm -rf $S/$b && mkdir -p $S/$b && tar -xf "$2" -C $S/$b && { [ -z "$3" ] || tar -xf "$3" -C $S/$b; }
if [ ! -x "$GODOT" ]; then
  cd $S && curl -sSLO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip && unzip -oq Godot_v4.7.2-stable_linux.x86_64.zip && chmod +x "$GODOT"
fi
# import every asset once (the smoke needs .godot/imported; a copy without it fails on fonts and pictures)
cd $S/$b && timeout 900 xvfb-run -a "$GODOT" --headless --path . --import > /dev/null 2>&1; echo "base $b: $(ls $S/$b/.godot/imported 2>/dev/null | wc -l) imported"

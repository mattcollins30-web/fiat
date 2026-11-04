#!/bin/bash
# merge.sh <base> <into> <from> : 3-way merges every file <from> changed against <base> into <into> (git merge-file);
# a file only <from> changed is copied. Prints each conflict; two builders' appended blocks at one spot conflict -
# keep both (ours then theirs). Copy the base's .godot into <into> afterwards.
. "$(dirname "$0")/env.sh"
cd $S && diff -rq --exclude=.godot --exclude='*.import' --exclude='*.uid' --exclude=.git $1 $3 | sed "s#^Files $1/\(.*\) and .*#\1#; s#^Only in $3/\(.*\): #\1/#; s#^Only in $3: ##" | while read f; do
  [ -f "$3/$f" ] || continue
  mkdir -p "$2/$(dirname "$f")"
  if [ -f "$1/$f" ] && [ -f "$2/$f" ] && ! cmp -s "$1/$f" "$2/$f"; then git merge-file "$2/$f" "$1/$f" "$3/$f" || echo "CONFLICT $f"; else cp "$3/$f" "$2/$f"; fi
done

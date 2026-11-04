#!/bin/bash
# snap.sh <workspace> : saves it (without .godot, imports and art) to the durable outputs folder - the cloud's /tmp is
# wiped when its container restarts (29 Oct: two builds lost). Every 30 min of work and at the end of every phase.
. "$(dirname "$0")/env.sh"
mkdir -p $SNAP && tar czf $SNAP/$1.tgz -C $S --exclude=.godot --exclude='*.import' --exclude=art $1 && echo "snap $1 $(date -u +%H:%M) $(stat -c %s $SNAP/$1.tgz)"

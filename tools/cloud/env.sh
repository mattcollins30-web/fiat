#!/bin/bash
# The cloud build kit's shared settings (docs/process/cloud_builds.md). S: the session's scratch folder, where the
# workspaces, Godot and the logs live; override it per session: `export S=/tmp/.../scratchpad`.
S=${S:-/tmp/claude-0/-home-claude/17fbe8af-3b8e-5c47-af2f-5ddb8fb0f07d/scratchpad}
GODOT=${GODOT:-$S/Godot_v4.7.2-stable_linux.x86_64}
SNAP=${SNAP:-/mnt/user-data/outputs/snap}

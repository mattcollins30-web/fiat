# PixelLab: writing a manifest, costing it, handing it over

Every image in Fiat is generated from a manifest run with `tools/pixellab_batch_v2.gd`. This is what a manifest has
to get right before it costs anything, what it costs, and how a manifest gets from the session that writes it to the
session that runs it. Learned over the fight kit, room boxes, map, heads and web art (17-23 Oct): each lesson below
cost at least one reroll.

## The lessons - check every job against these

**Guns**
- **Guns in hand point down the barrel**: foreshortened, muzzle into the scene, back of the gun at bottom right.
  `art/fight/hands/big_revolver.png` is the view (Matt: "the perfect view"); every gun job takes it as a
  `reference_images` entry and says "seen from behind, looking straight down the barrel ... not a side view, not in
  profile".
- **Side-on style images pull shapes into profile.** A `style_image` of an `art/items/*.png` icon makes the model copy
  its silhouette: say "its parts and colours, but turned to point away into the scene", not "its shape and colours".
- **Long guns keep the stock low**: running into the bottom-right corner, cut off by the frame, the top of the weapon
  below mid-frame.

**Lettering** - "no text" in the tail is not enough; the subject itself has to be blank.
- **Naming a place or thing invites its lettering.** "a chippy, a bookie's" came back with signs reading CHIPPY.
  Describe blank or faded fascia boards, paint without words.
- **"Sign" invites lettering**, even as a style word ("as a painted sign would show it"): say "pictogram".
- **Clock faces, banknotes, beer mats, labels, notebooks, timetables, dials**: say plain / blank / no numbers.
- **Things that are usually branded or printed** (tins, sacks, compost bags, bar towels, polish lids, push plates,
  bait boxes, bins, dodgems): "plain", "unprinted", "no lettering", "no number on it" in the subject.
- **"Hand-written" asks for writing**, however blank you say it is.

**Framing**
- **Plates can come out inset with a border**: say the painting fills the whole canvas to all four edges, no border,
  frame or margin.
- **Landscape style images pull top-down or flat art into a horizon view** (the `art/places/*` headers): add "Only the
  palette, light and painting style of the style image, not its view or its subject."
- **Cut-out icons must not name a setting.** "standing by a door", "on concrete", "against a grey sky", "at night",
  "on a bar towel", "in the dirt", "on a pub table" all come back as little square scenes. Describe the object alone;
  the tail says "no floor, wall, ground or sky around it".
- **Never describe what will be drawn over a backdrop.** "a chart of lines and small discs is drawn on top of this"
  made it paint the chart; props in the brief ("a table under a desk lamp, a mug ring") came back as clutter. A
  backdrop is a bare surface: "nothing on it, no lines, no marks".
- **Prompts that fight each other lose**: "a glass screen above it" against "nothing above it".

**Defaults the model brings**
- **Coins come out American** (a Lincoln cent): say "British".

**Seeds and outputs**
- **A fixed seed gives near-identical rerolls** even with a changed prompt: bump the seed (+1000) when a reroll must
  actually differ.
- **No two jobs share a seed or an `out`.**
- **Check what's already on disk** before costing: a job whose output exists is skipped (and free) unless `--force`.
- **Watch `out` paths**: hands jobs write into the live `art/fight/hands/`, not a `_new` folder.

## What it costs

`generate-image-v2`, one image a job (`"single": true`), by canvas area:

| Canvas | Cost a job | Seen at |
|---|---|---|
| up to about 65k px | $0.08 | 64x64 icons and nodes, 280x210 hands, 384x96, 188x160, 208x192, 168x300, 128x192 |
| about 150-240k px | $0.15 | 744x320 plates, 744x256 and 744x173 walls, 496x296 places, 508x420 map land |

- Rerolls cost the same as a first run: budget 30-50% on top for a new kind of art, less for a proven template.
- The script sometimes reports $0.0000 for a job that did run (all of one 316-job run): treat it as unknown, not free;
  cost from the job count.
- A server "QueuePool limit" failure isn't charged: just rerun.

## How long it takes

About 3-4 minutes a job, one at a time (a 316-job run took about 16 hours). `++ --parallel 3` keeps three jobs in
flight and PixelLab works them at once (23 Oct: three 64 px nodes came back together in under 4 minutes), so a run
takes about a third of the time for the same money.

## Running a manifest

```
C:\Godot\godot.console.exe --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/<m>.json [++ --parallel 3] [++ --only <substring>] [++ --force] [++ --dry-run]
```

- `godot.console.exe`, not `godot` / `Godot.exe` (they print nothing to the shell).
- `--only` takes one substring; the script reads only the first `--only`.
- `--dry-run` first: it lists every job it would make and skips what exists.
- Python isn't installed on Matt's machine. The `tools/make_*.py` generators are the source of truth; a fix goes into
  the generator and is mirrored into its JSON by hand.

## The handoff (23 Oct)

The session that writes a manifest and the session that runs it are often different Claudes. They pass work through
files in `docs/art/handoff/` (the watcher's flag pattern; the folder is git-ignored):

1. **Asking for a run.** Once Matt has agreed the manifest, the writing session puts `docs/art/handoff/art.flag` in
   place: one manifest path a line (`tools/pixellab_<name>_manifest.json`), in the order to run. Anything the runner
   should know goes on lines starting `#` (a test to run first, a job Matt wants rerolled).
2. **Picked up.** The running session renames it `art.running`, checks every job against the lessons above, fixes any
   breach in both the generator and the JSON, dry-runs it, and runs it (`--parallel 3`).
3. **Done.** It writes `docs/art/handoff/art.done`: the time, each manifest, the files written, any that failed and why,
   the fixes it made, and the cost. `art.running` goes.
4. **Wiring.** The writing session reads `art.done` and wires the art in where the code doesn't already find it by
   name.

A new `art.flag` while one is running waits its turn. Rerolls come back the same way: a flag naming the manifest, with
`# reroll <out> <why>` lines.

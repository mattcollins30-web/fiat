# Fiat - outstanding art and sound, 25 Oct

Checked on Matt's machine against every manifest in tools/ and every name the game looks up (item bases, uniques,
set pieces, materials, sound ids). Art runs through the handoff (docs/art/pixellab_lessons.md: a manifest named in
docs/art/handoff/art.flag, run by a Claude Code session on Matt's machine) or by hand with tools\art.bat; sound by
`powershell -File tools/eleven_batch.ps1 -Only <id>`. Each needs Matt's go (credits).

## Written, never run

| Manifest | Jobs | What | Note |
|---|---|---|---|
| tools/pixellab_chase_art_manifest.json | 23 | The Lineman's Tool Bag, the Registrar's Stamp, the Issuer's Revolver; 20 web nodes (Defib, Cut throat, Tear gas, the Recruit's fillers...) | about $1.84; flagged again 25 Oct 13:43 (docs/art/handoff/art.flag): the runner is a Claude Code session on Matt's machine, closed the first time |
| tools/pixellab_order_glyphs_manifest.json | 9 | The Grid's key, ledger seals, a true fiat note; the materials paving, glass, ledgers, cable drums, army kit, fuses | the six materials show a plain cell today |
| tools/pixellab_doom_test_manifest.json | 3 | the Parade "deeper" and "way out" plates | an old test; drop it unless the idea comes back |

Partly run, with leftovers the game no longer reads (superseded): pixellab_campaign (11 of 16 unmade: ui_new room
glyphs, the Gamekeeper's new face), pixellab_people_all (11 of 14), pixellab_bodies (3 of 5). Five single item
leftovers (issue plates, issue pistol, the Paramedic's bumbag, the Ambulance's bag, quick mag) are older names; the
game finds art for every live base. Papers share art/items/paper.png by design.

## To write

| Manifest | Jobs | What | Code change too |
|---|---|---|---|
| Boss fight backdrops (written 25 Oct: tools/pixellab_boss_backdrops_manifest.json, _test_manifest.json, seeds 105000-105013) | 14 + a 2-job test | A plate (744x320) and a cover wall (744x256) for each boss's fight: the Gamekeeper, the Carpet Man, the Manager, the Quartermaster, and the pinnacles' places - the Grid (the Lineman), the Archive (the Registrar), the Mint (the Issuer). Styled on each one's site pair, as make_fight_walls_manifest.py does, and the pinnacles on their map cards (art/places/the_grid, the_archive, the_mint) | done 25 Oct: RunView reads art/fight_boss/<boss>_plate/_cover while he's out, else the site's |
| Skill sounds | about 10 | the 48 skills cast silently: a sound a family (a hit, a stun, a throw, a buff, a heal, a trap, a shout), the energy full, a skill sealed | yes: sound.gd cues |
| The order's fights | about 4 | the Lineman's shield up and broken, the Registrar's seal, the Issuer printing a man | yes |
| Rain | 1 written | rain.mp3 exists (steady rain on tin roofs, 30 s). Written 25 Oct: `rain_roof` in tools/sound_manifest.json, rain on a roof heard from inside, played at the four roofed sites (the rain until it's made). Later, if wanted: a drizzle and a heavy shower to follow the sky's two layers | done for the roof |
| Temper | 1 | the Bench's temper uses the craft sound today; optional | small |

## Housekeeping

- 145 art PNGs on Matt's machine are untracked (generated, never committed): nodes, bodies, fight walls. His to
  commit or keep out.
- Seeds: 52 seeds are shared between different outputs across manifests (two inside the fight kit). A new manifest
  should take fresh seeds; an art lint (unique seeds, sizes under the cap, nothing under art/ui/) is in tools2.md.
- A `tools\art.bat` (dry run first, then the run) would save typing the batch line; kept out of the watcher on
  purpose, as the credits need a person's go.

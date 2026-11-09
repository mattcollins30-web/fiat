# Art 76: the slice's PixelLab files, for builder H's slice/art.gd

Manifest: tools/pixellab_art76_manifest.json (generator tools/make_art76_manifest.py). 37 files, all under
`res://slice/art/pl/`. All are new; nothing in slice/art/kenney/ is replaced. Load them through art.gd's png_texture()
as the Kenney files are, because a file with no .import still has to show in the headless smoke.

## Figures: 64x64, transparent, seen from directly above, facing +x (right)

Drawn at about 30 px on screen (a scale of about 0.5). The pivot is near the canvas centre (32, 32), because the
prompt puts the head in the centre. Measure the real pivot and BODY_R from the delivered pictures; they will not match
the Kenney figures' PIVOT (19, 21.5) and BODY_R 20.

`<who>_<pose>.png`, where who is runner, gang1, gang2, gang3 or hard, and pose is aim, fire, reload or down.

| who | look | gun |
|---|---|---|
| runner | the Poacher: olive waxed jacket, tweed flat cap | bolt-action rifle with a scope |
| gang1 | Estate gang: plain grey tracksuit top, cropped hair | sawn-off double-barrelled shotgun |
| gang2 | Estate gang: plain black hoodie, hood up | small pistol, held in both hands |
| gang3 | Estate gang: navy donkey jacket, fair hair | short submachine gun |
| hard | the hard man: bigger build, heavy coat with a hi-vis vest, shaved head | pump-action shotgun |

| pose | what it shows |
|---|---|
| aim | standing, the gun pointing right |
| fire | as aim, with a muzzle flash at the muzzle |
| reload | the gun lowered across the body, a hand at the magazine or breech |
| down | lying dead on his back, the gun dropped, head toward +x. No blood pool. Draw it unrotated, or at the facing he died at |

All 20: runner_aim, runner_fire, runner_reload, runner_down; gang1_aim, gang1_fire, gang1_reload, gang1_down;
gang2_aim, gang2_fire, gang2_reload, gang2_down; gang3_aim, gang3_fire, gang3_reload, gang3_down; hard_aim, hard_fire,
hard_reload, hard_down.

Mapping from art.gd today: "stand" becomes aim (there is no separate stand pose; a man stood with his gun lowered can
use aim), "gun"/"machine" becomes aim, and fire is used for a few frames after a shot. MEN becomes ["gang1", "gang2",
"gang3"], HARD "hard" and RUNNER "runner".

## Tiles and props: 64 px canvas = one 32 px tile on screen (a scale of 0.5)

| file | size | background | what it is | replaces (art.gd) |
|---|---|---|---|---|
| asphalt_a.png | 64x64 | opaque | worn asphalt, a faint crack | FLOOR tile_93 |
| asphalt_b.png | 64x64 | opaque | asphalt, a patched repair, gravel (a variant, scattered) | - |
| paving.png | 64x64 | opaque | concrete slabs, 2x2, mossy joints | PAVING tile_08 |
| kerb.png | 64x64 | opaque | kerb across the middle, asphalt below, paving above (rotate for other runs) | - |
| bay_line.png | 64x64 | transparent | faded white painted stripe, vertical, edge to edge (decal) | - |
| drain.png | 64x64 | transparent | square cast-iron grate (decal/prop) | - |
| oil_stain.png | 64x64 | transparent | oil stain (decal) | - |
| burnt_car.png | 128x192 | transparent | burnt-out car, nose up (2x3 tiles) | the board's car blocks |
| van.png | 128x224 | transparent | plain white van, nose up (2x3.5 tiles) | the board's car blocks |
| bin_wheelie.png | 64x64 | transparent | green wheelie bin, lid shut | BINS tile_317 |
| bin_round.png | 64x64 | transparent | round metal litter bin | BINS tile_316 |
| brick_wall.png | 64x64 | transparent | low brick wall top with coping stones, running left to right (rotate for vertical) | the low wall run |
| fence.png | 64x64 | transparent | palisade fence top, running left to right (rotate for vertical) | FENCE_H / FENCE_V tile_466 / 440 |
| kiosk_floor.png | 64x64 | opaque | worn lino tiles | KIOSK_FLOOR tile_96 |
| kiosk_wall.png | 64x64 | opaque | top of a sooted breeze-block wall | WALL tile_271 |
| crate.png | 64x64 | transparent | banded wooden crate lid (the searchable one) | CRATE tile_129 |
| shelter_roof.png | 128x64 | transparent | corrugated shelter roof on a steel frame (2x1 tiles) | the board's blue block |

The ground tiles are asked to repeat side by side, but PixelLab does not promise a seamless tile. If a seam shows,
offset the tiles or mix asphalt_a and asphalt_b at random, rather than rerolling first.

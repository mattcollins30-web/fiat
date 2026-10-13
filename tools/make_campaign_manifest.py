#!/usr/bin/env python3
"""Writes tools/pixellab_campaign_manifest.json (13 Oct, docs/design/campaign_gates.md): the tin glyph, the nine
rail glyphs for the rooms as they're named now, the Gamekeeper's portrait and the five unlock items.

  python3 tools/make_campaign_manifest.py
  godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_campaign_manifest.json
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REFS = ["res://art/reference/items/ref_%02d.png" % k for k in range(1, 5)]
STYLE = {"color_palette": True, "outline": True, "detail": True, "shading": True}

GLYPH_TAIL = (" One object centred and filling the frame, a single bold silhouette that still reads at a quarter of this size, "
              "soft directional overcast daylight, natural material rendering with painterly shading; no black outlines, no flat "
              "cel shading, not anime, not a cartoon, not a glossy video-game icon; the look of a real object photographed on a "
              "grey day in a country that has run out of money. Muted cool northern palette, worn and repaired, nothing new. "
              "Nothing else in the frame, no hands, no person, no text, no logos, a plain dark neutral background.")
ITEM_TAIL = (" One object centred and filling the frame, soft directional overcast daylight, natural material rendering with fine "
             "detail and painterly shading; no black outlines, no flat cel shading, not anime, not a cartoon, not a glossy "
             "video-game item; the look of a real object photographed on a grey day in a country that has run out of money. "
             "Muted cool northern palette, worn and repaired, nothing new. Nothing else in the frame, no hands, no person, "
             "no text, no logos, a plain dark neutral background.")

# art/ui_new/<name>.png: nothing in art/ui is touched; move the keepers over (the shell maps rooms to names in
# rail_button.gd GLYPH_OF, rewired when they're in)
GLYPHS = [
    ("yard", "the rail: The Yard (opened by the deeds)", "A realistic painted pixel-art still-life of a rolled property deed on thick cream paper, tied with faded pink legal ribbon, a cracked red wax seal on the ribbon."),
    ("stats", "the rail: Stats (the runner's sheet)", "A realistic painted pixel-art still-life of a small pocket notebook, its card cover soft and curled with handling, a stub of pencil pushed through the spiral."),
    ("runner", "the rail: Runner (the loadout)", "A realistic painted pixel-art still-life of a worn olive canvas field jacket hung on a bent wire coat hanger, a patch on one elbow, seen front on."),
    ("runs", "the rail: Runs (going out)", "A realistic painted pixel-art still-life of a folded paper road map, creased soft and torn at the folds, a route marked on it in blue biro."),
    ("training", "the rail: Training (the trees)", "A realistic painted pixel-art still-life of a thick hardback army field manual, its spine mended with tape, torn paper strips marking pages, standing slightly open."),
    ("workshop", "the rail: Workshop (opened by the armourer's tool roll)", "A realistic painted pixel-art still-life of a canvas tool roll laid open flat, spanners, a screwdriver and a file in its pockets, oil on the canvas."),
    ("clinic", "the rail: Clinic (opened by the vet's bag)", "A realistic painted pixel-art still-life of an old brown leather vet's bag, the doctor's kind with a hinged mouth and a brass clasp, scuffed at the corners."),
    ("fence", "the rail: The Fence (opened by the Carpet Man's ledger)", "A realistic painted pixel-art still-life of a fat cloth-bound account ledger held shut with a perished rubber band, receipts and scraps of paper sticking out of it."),
    ("radio", "the rail: Radio (opened by the military radio)", "A realistic painted pixel-art still-life of a military field radio, olive drab metal case with a short whip aerial and a coiled handset clipped to its side, chipped paint."),
    ("tins", "the top bar: tins (what was cash)", "A realistic painted pixel-art still-life of a single tin can, its paper label gone, the steel dented on one side and rusting at the rim, standing upright."),
]

# art/items/<slug>.png: the unlock papers, 2 x 2 cells (128 px) as the deeds; new names, nothing written over
ITEMS = [
    ("the_vet_s_bag", "The vet's bag: the Gamekeeper's, opens the Clinic", "A realistic painted pixel-art still-life of an old brown leather vet's bag, the doctor's kind with a hinged mouth and a brass clasp, standing a little open, a roll of bandage and a brown glass bottle showing inside, dog hair on the leather."),
    ("the_carpet_man_s_ledger", "The Carpet Man's ledger: opens the Fence", "A realistic painted pixel-art still-life of a fat cloth-bound account ledger held shut with a perished rubber band, receipts, carpet offcut samples and scraps of paper with phone numbers sticking out of it, a coffee ring on the cover."),
    ("the_deeds", "The deeds: the Manager's, opens the Yard", "A realistic painted pixel-art still-life of a rolled property deed on thick cream paper, tied with faded pink legal ribbon, a cracked red wax seal, a bank's old brown envelope half under it."),
    ("a_military_radio", "A military radio: the Quartermaster's, opens the Radio", "A realistic painted pixel-art still-life of a military field radio set, olive drab metal case with dials and switches on its face, a short whip aerial, a coiled handset clipped to its side, a stencilled number half worn off."),
    ("the_armourer_s_tool_roll", "The armourer's tool roll: the Quartermaster's, opens the Workshop", "A realistic painted pixel-art still-life of a heavy canvas armourer's tool roll laid open, punches, a small hammer, a cleaning rod and spanners in its pockets, gun oil darkening the canvas, a leather tie hanging from it."),
]

BOSS = ("the_gamekeeper", "A realistic painted pixel-art portrait, head and shoulders, of the Gamekeeper, a lean weathered man in his sixties who kept the shoot on Top Farm's land and keeps it for himself now: a tweed cap, a waxed jacket gone pale at the seams, a shotgun broken over his shoulder, a dog lead looped round his neck, close-cut white beard, eyes that watch the hedges. Looking just past the viewer. Post-collapse Britain, overcast light. One person centred, filling the frame, no text, no border, plain dark background.")

jobs = []
for k, (name, where, obj) in enumerate(GLYPHS):
    jobs.append({"out": "art/ui_new/%s.png" % name, "endpoint": "generate-image-v2", "description": obj + GLYPH_TAIL,
                 "width": 64, "height": 64, "no_background": True, "seed": 92000 + k, "single": True,
                 "style_image": REFS[k % 4], "style_options": STYLE, "_where": where})
for k, (slug, where, obj) in enumerate(ITEMS):
    jobs.append({"out": "art/items/%s.png" % slug, "endpoint": "generate-image-v2", "description": obj + ITEM_TAIL,
                 "width": 128, "height": 128, "no_background": True, "seed": 92100 + k, "single": True,
                 "style_image": REFS[k % 4], "style_options": STYLE, "_where": where})
jobs.append({"out": "art/people_new/%s.png" % BOSS[0], "endpoint": "generate-image-v2", "description": BOSS[1],
             "width": 128, "height": 128, "no_background": False, "seed": 92200, "single": True,
             "style_image": "res://art/people/fence.png", "style_options": STYLE, "_where": "the Outskirts' boss, Top Farm"})

readme = [
    "FIAT CAMPAIGN ART (13 Oct, docs/design/campaign_gates.md): the tin glyph and the nine rail glyphs for the rooms as they're named now (art/ui_new/, 64 x 64; nothing in art/ui is touched - move the keepers over and Claude rewires GLYPH_OF), the five unlock items (art/items/, 128 x 128 as the deeds, new names), the Gamekeeper's portrait (art/people_new/, in the Fence's portrait style).",
    "The rail glyphs for the Yard, Workshop, Clinic, Fence and Radio are the things that open them, drawn simpler for 38 px.",
    "Run: godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_campaign_manifest.json   (++ --dry-run to list). A job whose file exists is skipped; one that came out wrong: ++ --only <name> ++ --force.",
    "Regenerate with python3 tools/make_campaign_manifest.py.",
]
with open(os.path.join(ROOT, "tools", "pixellab_campaign_manifest.json"), "w") as f:
    json.dump({"_readme": readme, "jobs": jobs}, f, indent=1)
print(len(jobs), "jobs")

extends RefCounted
## The slice's stand-in art (round 3, Matt: "some art ... even if it's just open source"): Kenney's Top-down Shooter
## pack, CC0 (slice/art/kenney/License.txt). Only the files used are copied. An imported picture (the editor, every
## export) is load()ed; one not imported yet (Matt's headless smoke on a fresh checkout) is read from its PNG, so a
## picture with no .import beside it still shows.
##
## (build 76) The PixelLab set (ART76: top-down, at Zero Sievert's scale) lands in slice/art/pl/ by art.flag. A picture
## there wins over Kenney's by name - PL_WHO x PL_POSE for the characters, PL_TILES for the ground and the props - so the
## new art shows with no code once it lands, and the slice draws from Kenney's till then. The set's other pieces (the
## cars, the van, the shelter's roof, the decals) by pl_tex(name), null until they land. Names: tools/make_art76_manifest.py.

const DIR := "res://slice/art/kenney/"
const RUNNER := "soldier1"                            # Soldier 1: the runner (ringed amber, as the token was)
const MEN := ["hitman1", "manBrown", "manBlue"]       # the gang's men, one look each in turn
const HARD := "manOld"                                # the hard man (his gold ring and glow kept)
const PIVOT := Vector2(19.0, 21.5)                    # a character's head, in its picture (they face +x)
const BODY_R := 20.0                                  # a character's shoulders' half-width in its picture, px
const FLOOR := "tile_93"                              # asphalt
const PAVING := "tile_08"                             # the paving at the park's edge
const KIOSK_FLOOR := "tile_96"                        # the kiosk's boards
const WALL := "tile_271"                              # concrete: the walls and (burnt dark) the kiosk's
const CRATE := "tile_129"                             # the searchable crate
const BINS := ["tile_317", "tile_316"]                # the bins: a grey barrel and an orange one, in turn
const FENCE_H := "tile_466"                           # the low wall run: a fence, along
const FENCE_V := "tile_440"                           # ...and up

## The poses each character is drawn in (and so the only pictures copied): the runner's from runner.pose(); a
## man's from man_pose() - "stand", or his gun up.
const POSES := {"soldier1": ["stand", "gun", "machine", "reload"], "hitman1": ["stand", "machine"], "manBlue": ["stand", "machine"],
	"manBrown": ["stand", "gun"], "manOld": ["stand", "gun"]}
const GUN_UP := {"hitman1": "machine", "manBlue": "machine", "manBrown": "gun", "manOld": "gun"}

## (build 76) The PixelLab set: <who>_<pose>.png for the characters, the tiles by name (ART76's names).
const PL_DIR := "res://slice/art/pl/"
const PL_WHO := {"soldier1": "runner", "hitman1": "gang1", "manBrown": "gang2", "manBlue": "gang3", "manOld": "hard"}
## Kenney's poses (the callers' today) to the set's; the set's own names pass through. "stand" (the gun down: searching,
## leaving, swapping) has no picture of its own in the set: the aim's stands in.
const PL_POSE := {"stand": "aim", "gun": "aim", "machine": "aim", "reload": "reload", "aim": "aim", "fire": "fire", "down": "down"}
## Each set pose's Kenney stand-in, when the set's picture isn't there: "aim" and "fire" his gun up (the caller's
## kenney_up, else GUN_UP's), "down" stood (Kenney has no body: a dead man fades as he stood, as before).
const KENNEY_POSE := {"aim": "", "fire": "", "reload": "reload", "down": "stand"}
const PL_TILES := {"tile_93": "asphalt_a", "tile_08": "paving", "tile_96": "kiosk_floor", "tile_271": "kiosk_wall",
	"tile_129": "crate", "tile_317": "bin_wheelie", "tile_316": "bin_round", "tile_466": "fence", "tile_440": "fence"}
const PL_RUNS := ["kiosk_wall", "fence"]             # drawn along a run left to right: turned a quarter for one up the screen
const PL_TILED := ["tile_93", "tile_08", "tile_96"]   # the floors, repeated: a set tile is drawn at the slice's TILE
const TILE_PX := 64                                   # (SliceTuning.TILE) a floor tile's world size
const PL_SCALE_R := 38.0                              # a token this radius (the runner's, 40 x 0.95) draws a set figure 1:1 in
                                                      # world px: 64 px, 32 on screen at W's zoom (ART76: "about 30 px")

static var _cache := {}
static var pl_dir := PL_DIR                           # where the set's read from (the smoke points it at a probe)
static var _looks := 0


## A picture of the pack by its file's name (no extension), cached; null if it isn't there.
static func tex(name: String) -> Texture2D:
	if not _cache.has(name):
		var t: Texture2D = pl_tex(pl_name(name))
		_cache[name] = t if t != null else png_texture(DIR + name + ".png")
	return _cache[name]


## The set's name for a Kenney picture's ("soldier1_machine" -> "runner_aim", "tile_93" -> "asphalt_1"); "" for none.
static func pl_name(name: String) -> String:
	if PL_TILES.has(name):
		return str(PL_TILES[name])
	var cut: int = name.rfind("_")
	if cut > 0 and PL_WHO.has(name.substr(0, cut)) and PL_POSE.has(name.substr(cut + 1)):
		return "%s_%s" % [PL_WHO[name.substr(0, cut)], PL_POSE[name.substr(cut + 1)]]
	return ""


## The set's picture by its name, null when it hasn't landed. A floor tile smaller than the slice's tile is scaled up
## (nearest) to it, so the floor's repeat stays a tile whatever the picture's size.
static func pl_tex(pl: String) -> Texture2D:
	if pl == "":
		return null
	var key := "pl:" + pl
	if not _cache.has(key):
		var t: Texture2D = png_texture(pl_dir + pl + ".png")
		if t != null and PL_TILED.any(func(k): return PL_TILES[k] == pl) and t.get_width() != TILE_PX:
			var img: Image = t.get_image()
			if img != null and not img.is_empty():
				if img.is_compressed():
					img.decompress()
				img.resize(TILE_PX, TILE_PX, Image.INTERPOLATE_NEAREST)
				t = ImageTexture.create_from_image(img)
		if t != null:
			var cut: int = pl.rfind("_")
			if cut > 0 and PL_WHO.values().has(pl.substr(0, cut)):
				t.set_meta("pl_who", pl.substr(0, cut))     # a set figure: draw_char centres it and sizes it by its shoulders
		_cache[key] = t
	return _cache[key]


## Every picture read forgotten (the smoke's probe of the set, then back).
static func forget() -> void:
	_cache.clear()


## Whether the set's picture for a Kenney name is the one drawn (it has landed).
static func is_pl(name: String) -> bool:
	return pl_tex(pl_name(name)) != null


## A PNG as a texture. Imported (the editor after Matt's import, and every export - an export packs the imported
## texture, not the PNG): load() it. Not imported (the headless smoke on a fresh checkout): read the file itself.
static func png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			return res
	if not FileAccess.file_exists(path):
		return null
	var abs_path := ProjectSettings.globalize_path(path)
	var img: Image = Image.load_from_file(abs_path) if FileAccess.file_exists(abs_path) else null
	if img == null or img.is_empty():
		img = Image.new()                               # no file on disk but the bytes in a pack: read them
		if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
			return null
	return ImageTexture.create_from_image(img)


## The part of a picture that isn't see-through (a fence plank, a barrel), as {tex, src}.
static func used(name: String) -> Dictionary:
	var key := name + "#used"
	if not _cache.has(key):
		var t := tex(name)
		var r := Rect2(Vector2.ZERO, t.get_size()) if t != null else Rect2()
		if t != null:
			r = Rect2(t.get_image().get_used_rect())
		_cache[key] = {"tex": t, "src": r}
	return _cache[key]


## (round 5's review) A man's pose in the art set's names: down when dead, fire just after a shot, aim when he sees you,
## else stood (the set's aim; Kenney's gun down).
static func man_set_pose(dead: bool, firing: bool, sees: bool) -> String:
	if dead:
		return "down"
	if firing:
		return "fire"
	return "aim" if sees else "stand"


## A man's pose: his gun up when he sees you or has just fired; else stood.
static func man_pose(who: String, up: bool) -> String:
	return str(GUN_UP.get(who, "machine")) if up else "stand"


## The set's pictures the slice would draw, by name (no extension): what art76_names.md promises.
static func pl_files() -> Array:
	var out: Array = []
	for who in PL_WHO.values():
		for pose in ["aim", "fire", "reload", "down"]:
			out.append("%s_%s" % [who, pose])
	for k in PL_TILES:
		if not out.has(PL_TILES[k]):
			out.append(PL_TILES[k])
	return out


## Every picture the slice draws, by file name (no extension).
static func used_files() -> Array:
	var out: Array = [FLOOR, PAVING, KIOSK_FLOOR, WALL, CRATE, FENCE_H, FENCE_V] + BINS
	for who in POSES:
		for pose in POSES[who]:
			out.append("%s_%s" % [who, pose])
	return out


## The next gang man's look (Hitman 1, Man Brown, Man Blue in turn).
static func next_look() -> String:
	_looks += 1
	return MEN[(_looks - 1) % MEN.size()]


## (build 76) The picture a character's drawn with: the set's when it has landed (pose "aim", "fire", "reload", "down",
## or Kenney's, mapped), else Kenney's (the set's "aim" and "fire" as his gun up, "down" as he stood).
static func char_tex(who: String, pose: String, kenney_up := "") -> Texture2D:
	var pl_who: String = str(PL_WHO.get(who, ""))
	var pl: Texture2D = pl_tex("%s_%s" % [pl_who, PL_POSE[pose]]) if pl_who != "" and PL_POSE.has(pose) else null
	if pl != null:
		return pl
	var kpose: String = pose
	if KENNEY_POSE.has(pose):
		kpose = str(KENNEY_POSE[pose])
		if kpose == "":
			kpose = kenney_up if kenney_up != "" else str(GUN_UP.get(who, "machine"))
	return tex("%s_%s" % [who, kpose])


## A character drawn on `ci` at its origin, turned to `angle`, its body `radius` across the token's: a set figure centred
## on its picture at PL_SCALE_R's scale; Kenney's on his head's pivot.
static func draw_char(ci: CanvasItem, who: String, pose: String, angle: float, radius: float, tint: Color = Color.WHITE, kenney_up := "") -> bool:
	var t := char_tex(who, pose, kenney_up)
	if t == null:
		return false
	if t.has_meta("pl_who"):
		var kp := radius / PL_SCALE_R
		ci.draw_set_transform(Vector2.ZERO, angle, Vector2(kp, kp))
		ci.draw_texture(t, -t.get_size() * 0.5, tint)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return true
	var k := radius / BODY_R
	ci.draw_set_transform(Vector2.ZERO, angle, Vector2(k, k))
	ci.draw_texture(t, -PIVOT, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


## A picture repeated along a rectangle at its own scale across the short side (a wall of concrete, a fence's planks).
static func draw_strip(ci: CanvasItem, name: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
	if rect.size.y > rect.size.x and PL_RUNS.has(pl_name(name)) and is_pl(name):
		ci.draw_set_transform(rect.position + Vector2(rect.size.x, 0.0), PI / 2.0, Vector2.ONE)     # (build 76) the set's run, turned
		draw_strip(ci, name, Rect2(Vector2.ZERO, Vector2(rect.size.y, rect.size.x)), tint)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var u := used(name)
	var t: Texture2D = u["tex"]
	if t == null:
		ci.draw_rect(rect, tint)
		return
	var src: Rect2 = u["src"]
	var along_x := rect.size.x >= rect.size.y
	var step := src.size.x * (rect.size.y / src.size.y) if along_x else src.size.y * (rect.size.x / src.size.x)
	step = maxf(8.0, step)
	var at := 0.0
	var length := rect.size.x if along_x else rect.size.y
	while at < length - 0.5:
		var part := minf(step, length - at)
		var f := part / step
		var s := Rect2(src.position, Vector2(src.size.x * f, src.size.y)) if along_x else Rect2(src.position, Vector2(src.size.x, src.size.y * f))
		var d := Rect2(rect.position + Vector2(at, 0), Vector2(part, rect.size.y)) if along_x else Rect2(rect.position + Vector2(0, at), Vector2(rect.size.x, part))
		ci.draw_texture_rect_region(t, d, s, tint)
		at += step

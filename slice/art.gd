extends RefCounted
## The slice's stand-in art (round 3, Matt: "some art ... even if it's just open source"): Kenney's Top-down Shooter
## pack, CC0 (slice/art/kenney/License.txt). Only the files used are copied. An imported picture (the editor, every
## export) is load()ed; one not imported yet (Matt's headless smoke on a fresh checkout) is read from its PNG, so a
## picture with no .import beside it still shows.

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

static var _cache := {}
static var _looks := 0


## A picture of the pack by its file's name (no extension), cached; null if it isn't there.
static func tex(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = png_texture(DIR + name + ".png")
	return _cache[name]


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


## A man's pose: his gun up when he sees you or has just fired; else stood.
static func man_pose(who: String, up: bool) -> String:
	return str(GUN_UP.get(who, "machine")) if up else "stand"


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


## A character drawn on `ci` at its origin, turned to `angle`, its body `radius` across the token's.
static func draw_char(ci: CanvasItem, who: String, pose: String, angle: float, radius: float, tint: Color = Color.WHITE) -> bool:
	var t := tex("%s_%s" % [who, pose])
	if t == null:
		return false
	var k := radius / BODY_R
	ci.draw_set_transform(Vector2.ZERO, angle, Vector2(k, k))
	ci.draw_texture(t, -PIVOT, tint)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return true


## A picture repeated along a rectangle at its own scale across the short side (a wall of concrete, a fence's planks).
static func draw_strip(ci: CanvasItem, name: String, rect: Rect2, tint: Color = Color.WHITE) -> void:
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

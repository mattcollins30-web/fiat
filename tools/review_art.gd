extends SceneTree
## The fight art review (17 Oct, Matt: "a review tool for the new art" - while the kit's batch runs): every site's
## fight as the run view draws it - its plate and wall (the kit's first), its zone's gang up at their slots, a pair of
## hands - then every zone's head out at his site, and every gun base's hands with its muzzle marked. Headless: the run
## view's own nodes, laid out by the game, painted into an image here (no window needed), so what it shows is where
## the game puts things.
##   tools\review_art.bat    (or: godot --headless --path . -s tools/review_art.gd)
## Writes docs/review/: sites.png (every site, a contact sheet), heads.png, hands.png, and site_<key>.png at 2x.
## Painted: the pictures (plate, wall, figures, shadows, hands) and flat fills. Not painted: the flash, the figures'
## HP bars, words, the glass and the particles - a missing bar or flash here is the tool, not the game.

const Sim := preload("res://scripts/sim/sim.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const RunView := preload("res://scripts/ui/run_view.gd")
const OUT := "res://docs/review/"
const FONT_PX := 2                       # the captions' pixel size (a 5x7 block font, drawn here: no font file needed)
const COLS := 3
const HANDS_COLS := 8


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var view = RunView.new()
	root.add_child(view)
	var sites: Array = []
	var heads: Array = []
	var guns: Array = _guns()
	for i in range(Data.TIERS.size()):
		var sim = _open_sim()
		var gun: Dictionary = guns[i % guns.size()]
		sim.equipped["Primary"] = gun
		sim.equipped["Secondary"] = null
		sim.deploy(i)
		if not sim.on_mission():
			print("site %d (%s): could not deploy" % [i, Data.TIERS[i]["name"]])
			continue
		var m: Dictionary = sim.mission
		m["event_at"] = -1.0
		m["remaining"] = 3
		var img := _shot(view, sim, m)
		var key: String = RunView.site_key(str(Data.TIERS[i]["name"]))
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		img.save_png(ProjectSettings.globalize_path(OUT + "site_%s.png" % key))
		sites.append([img, "%s  %s" % [str(Data.TIERS[i]["name"]), "kit" if RunView.kit_pair(key) else "OLD ART"], str(gun["base"])])
		sim.extract_now()
	# the heads, each at a site of his zone, out and alone
	for i in range(Data.TIERS.size()):
		var sim = _open_sim()
		if not sim.can_arm_boss(i):
			continue
		var zone: int = int(Data.TIERS[i]["zone"])
		if heads.any(func(h): return h[3] == zone):
			continue
		sim.arm_boss(i, true)
		sim.deploy(i)
		if not sim.on_mission() or not sim.mission.has("boss"):
			continue
		var m: Dictionary = sim.mission
		m["event_at"] = -1.0
		m["remaining"] = 1
		m["boss"]["started"] = true
		m["boss"]["alive"] = true
		var img := _shot(view, sim, m)
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
		heads.append([img, "%s at %s" % [str(m["boss"]["name"]), str(Data.TIERS[i]["name"])], "", zone])
		sim.extract_now()
	_sheet(sites, COLS).save_png(ProjectSettings.globalize_path(OUT + "sites.png"))
	if not heads.is_empty():
		_sheet(heads, 2).save_png(ProjectSettings.globalize_path(OUT + "heads.png"))
	_hands_sheet(guns).save_png(ProjectSettings.globalize_path(OUT + "hands.png"))
	print("review: %d sites, %d heads, %d hands -> docs/review/" % [sites.size(), heads.size(), guns.size()])
	quit()


## A sim with every site open: the campaign's depths, the heads beaten, the rooms open.
func _open_sim():
	var sim = Sim.new()
	sim.start()
	sim.xp = Data.xp_for_level(30)
	for i in range(Data.TIERS.size()):
		sim.best_depth[i] = 1
	sim.best_tier = Data.TIERS.size() - 1
	for z in range(sim.bosses_beaten.size()):
		sim.bosses_beaten[z] = true
	sim.notes = 999999                        # a head's fight costs notes once he's down
	sim.hp = sim.max_hp()
	return sim


## Every gun base, primary then secondary, as a plain item.
func _guns() -> Array:
	var sim = Sim.new()
	var out: Array = []
	for slot in ["Primary", "Secondary"]:
		for b in Data.BASES[slot]:
			out.append(sim._plain(slot, str(b["name"])))
	return out


## The run view on this mission, a second in (the gang up), painted.
func _shot(view, sim, m: Dictionary) -> Image:
	view.show_state(sim, m)
	for k in range(6):
		view._process(0.2)
		view.show_state(sim, m)
	var guard := 0
	while view._swing >= 0.0 and guard < 40:
		view._process(0.05)                     # off a swing's frame: the painter draws the arm unrotated
		guard += 1
	view._duck = 0.0                            # up from behind the wall: every shot the same, the wall at its own height
	view._duck_t = 0.0
	view._process(0.001)
	var img := Image.create(RunView.W, RunView.H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.08, 0.09, 0.1))
	_paint(view, view, img)
	return img


## Every visible TextureRect and ColorRect under the view, in draw order, into img at its place in the view.
func _paint(node: Node, view: Control, img: Image) -> void:
	for c in node.get_children():
		if not (c is CanvasItem) or not c.visible:
			continue
		if c is TextureRect and c.texture != null:
			_blit(c, view, img)
		elif c is ColorRect:
			var r: Rect2 = _rect_in(c, view)
			var col: Color = c.color * _tint(c)
			if col.a > 0.01:
				var fill := Image.create(maxi(1, int(r.size.x)), maxi(1, int(r.size.y)), false, Image.FORMAT_RGBA8)
				fill.fill(col)
				img.blend_rect(fill, Rect2i(Vector2i.ZERO, fill.get_size()), Vector2i(r.position))
		_paint(c, view, img)


func _rect_in(c: Control, view: Control) -> Rect2:
	var g: Rect2 = c.get_global_rect()
	return Rect2(g.position - view.get_global_rect().position, g.size)


func _tint(c: CanvasItem) -> Color:
	var col: Color = c.self_modulate
	var n: Node = c
	while n != null and n is CanvasItem:
		col *= n.modulate
		n = n.get_parent()
	return col


## A TextureRect drawn as its stretch mode lays it, flipped and tinted as it is.
func _blit(c: TextureRect, view: Control, img: Image) -> void:
	var r: Rect2 = _rect_in(c, view)
	var src: Image = c.texture.get_image()
	if src == null:
		return
	src = src.duplicate()
	if src.is_compressed():
		src.decompress()
	src.convert(Image.FORMAT_RGBA8)
	var ts := Vector2(src.get_size())
	var dst := r
	match c.stretch_mode:
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED, TextureRect.STRETCH_KEEP_ASPECT:
			var s: float = minf(r.size.x / ts.x, r.size.y / ts.y)
			dst = Rect2(r.position + (r.size - ts * s) / 2.0 if c.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED else r.position, ts * s)
		TextureRect.STRETCH_KEEP_CENTERED:
			dst = Rect2(r.position + (r.size - ts) / 2.0, ts)
		TextureRect.STRETCH_KEEP:
			dst = Rect2(r.position, ts)
		TextureRect.STRETCH_TILE:
			dst = r
		_:
			dst = r
	if c.expand_mode == TextureRect.EXPAND_KEEP_SIZE and c.stretch_mode == TextureRect.STRETCH_SCALE:
		dst = r
	var w: int = int(round(dst.size.x))
	var h: int = int(round(dst.size.y))
	if w < 1 or h < 1 or w > 4000 or h > 4000:
		return
	if c.stretch_mode == TextureRect.STRETCH_TILE:
		var tile := src
		var gs: Vector2 = c.get_global_transform().get_scale()
		tile.resize(maxi(1, int(round(tile.get_width() * gs.x))), maxi(1, int(round(tile.get_height() * gs.y))), Image.INTERPOLATE_NEAREST)     # tiled at its own size, then the node's scale (the kit's wall fill)
		src = Image.create(w, h, false, Image.FORMAT_RGBA8)
		for ty in range(0, h, tile.get_height()):
			for tx in range(0, w, tile.get_width()):
				src.blit_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(tx, ty))
	else:
		src.resize(w, h, Image.INTERPOLATE_NEAREST)
	if c.flip_h:
		src.flip_x()
	if c.flip_v:
		src.flip_y()
	var tint: Color = _tint(c)
	if not tint.is_equal_approx(Color.WHITE):
		for y in range(h):
			for x in range(w):
				src.set_pixel(x, y, src.get_pixel(x, y) * tint)
	img.blend_rect(src, Rect2i(0, 0, w, h), Vector2i(int(round(dst.position.x)), int(round(dst.position.y))))


## Shots in a grid, each captioned underneath.
func _sheet(shots: Array, cols: int) -> Image:
	var cw: int = shots[0][0].get_width()
	var ch: int = shots[0][0].get_height() + 36
	var rows: int = int(ceil(shots.size() / float(cols)))
	var sheet := Image.create(cols * (cw + 12) + 12, rows * (ch + 12) + 12, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.06, 0.07, 0.08))
	for k in range(shots.size()):
		var at := Vector2i(12 + (k % cols) * (cw + 12), 12 + int(k / float(cols)) * (ch + 12))
		var s: Image = shots[k][0]
		sheet.blit_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), at)
		var cap: String = str(shots[k][1]) + (("   hands: " + str(shots[k][2])) if str(shots[k][2]) != "" else "")
		_text(sheet, cap.to_upper(), at + Vector2i(0, s.get_height() + 10), Color(0.93, 0.93, 0.93) if not cap.contains("OLD ART") else Color(0.93, 0.46, 0.39))
	return sheet


## Every gun base's hands, the muzzle the flash comes from marked (magenta) and its way (green).
func _hands_sheet(guns: Array) -> Image:
	var cw := 280
	var ch := 210 + 30
	var rows: int = int(ceil(guns.size() / float(HANDS_COLS)))
	var sheet := Image.create(HANDS_COLS * (cw + 8) + 8, rows * (ch + 8) + 8, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.25, 0.27, 0.3))
	for k in range(guns.size()):
		var gun: Dictionary = guns[k]
		var at := Vector2i(8 + (k % HANDS_COLS) * (cw + 8), 8 + int(k / float(HANDS_COLS)) * (ch + 8))
		var slug: String = RunView.art_slug(str(gun["base"]))
		var t: Texture2D = RunView.hands_tex(gun)
		var own: bool = RunView.tex("hands/" + slug) != null
		if t != null:
			var src: Image = t.get_image().duplicate()
			if src.is_compressed():
				src.decompress()
			src.convert(Image.FORMAT_RGBA8)
			sheet.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), at)
			var kind: String = RunView._hands_kind(gun)
			if not Items.is_melee(gun):
				var mz: Dictionary = RunView.muzzle_of(t, kind, slug)
				if not mz.is_empty():
					_mark(sheet, at, mz["at"], (mz["dir"] as Vector2).normalized())
		_text(sheet, (str(gun["base"]) + ("" if own else "  (KIND'S)")).to_upper(), at + Vector2i(0, 216), Color(0.93, 0.93, 0.93) if own else Color(0.93, 0.46, 0.39))
	return sheet


func _mark(sheet: Image, at: Vector2i, p: Vector2, d: Vector2) -> void:
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			if abs(dx) == 3 or abs(dy) == 3:
				_px(sheet, at + Vector2i(int(p.x) + dx, int(p.y) + dy), Color(1, 0, 1))
	for s in range(4, 22):
		_px(sheet, at + Vector2i(int(p.x + d.x * s), int(p.y + d.y * s)), Color(0, 1, 0))


func _px(img: Image, q: Vector2i, col: Color) -> void:
	if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
		img.set_pixelv(q, col)


## A caption in a 5x7 block font, upper case, digits and a little punctuation; anything else a gap.
const GLYPHS := {
	"A": "01110100011000111111100011000110001", "B": "11110100011111010001100011000111110", "C": "01110100011000010000100001000101110",
	"D": "11110100011000110001100011000111110", "E": "11111100001111010000100001000011111", "F": "11111100001111010000100001000010000",
	"G": "01110100011000010111100011000101111", "H": "10001100011111110001100011000110001", "I": "01110001000010000100001000010001110",
	"J": "00111000100001000010000101001001100", "K": "10001100101010011000101001001010001", "L": "10000100001000010000100001000011111",
	"M": "10001110111010110101100011000110001", "N": "10001110011010110011100011000110001", "O": "01110100011000110001100011000101110",
	"P": "11110100011000111110100001000010000", "Q": "01110100011000110001101011001001101", "R": "11110100011000111110101001001010001",
	"S": "01111100001000001110000010000111110", "T": "11111001000010000100001000010000100", "U": "10001100011000110001100011000101110",
	"V": "10001100011000110001100010101000100", "W": "10001100011000110101101011101110001", "X": "10001100010101000100010101000110001",
	"Y": "10001100010101000100001000010000100", "Z": "11111000010001000100010001000011111",
	"0": "01110100011001110101110011000101110", "1": "00100011000010000100001000010001110", "2": "01110100010000100010001000100011111",
	"3": "11111000100010000010000011000101110", "4": "00010001100101010010111110001000010", "5": "11111100001111000001000011000101110",
	"6": "00110010001000011110100011000101110", "7": "11111000010001000100010000100001000", "8": "01110100011000101110100011000101110",
	"9": "01110100011000101111000010001001100", "'": "00100001000010000000000000000000000", "-": "00000000000111000000000000000000000",
	"(": "00010001000100001000010000010000010", ")": "01000001000001000010000100010001000", ":": "00000001000010000000001000010000000",
	".": "00000000000000000000000000110001100", "/": "00001000010001000100010001000010000",
}


func _text(img: Image, s: String, at: Vector2i, col: Color) -> void:
	var x: int = at.x
	for ch in s:
		var g: String = GLYPHS.get(ch, "")
		if g != "":
			for gy in range(7):
				for gx in range(5):
					if g[gy * 5 + gx] == "1":
						for py in range(FONT_PX):
							for px in range(FONT_PX):
								_px(img, Vector2i(x + gx * FONT_PX + px, at.y + gy * FONT_PX + py), col)
		x += 6 * FONT_PX

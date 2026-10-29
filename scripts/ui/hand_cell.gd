extends Button
## A hired hand as an item cell (29 Oct, docs/design/trips.md 3: "shown in item cells - one system, not two"): the
## rarity the border's colour and the wash at the foot, the trade as its name, its tier and level, the trade's figure
## in green, then its affixes, the number first. A face (art/hands/<trade>_<look>.png) at the top right once painted.
## Out or hurt, said first on the tier's line in its colour (a corner tag cut the trade's name short in the smallest
## cell). The owner wires the press.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Items := preload("res://scripts/sim/items.gd")
const Data := preload("res://scripts/sim/data.gd")
const Words := preload("res://scripts/sim/words.gd")

const H := 126
const PAD := 6
const FACE := 28
const AFFIX_LINES := 4

var id := -1
var picked := false
var _name: Label
var _sub: Label
var _trade: Label
var _lines: Array[Label] = []
var _face: TextureRect
static var _faces := {}


func _init(w: float) -> void:
	size = Vector2(w, H)
	text = ""
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	var iw: float = w - 2 * PAD
	_name = UI.label(self, Rect2(PAD, 3, iw, 22), "", "SemiBold", 14, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_sub = UI.label(self, Rect2(PAD, 24, iw, 18), "", "Regular", 12, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_trade = UI.label(self, Rect2(PAD, 42, iw, 18), "", "Medium", 12, Pal.GOOD, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(AFFIX_LINES):
		_lines.append(UI.label(self, Rect2(PAD, 60 + k * 16, iw, 16), "", "Regular", 11, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false))
	_face = TextureRect.new()
	_face.position = Vector2(w - PAD - FACE, 4)
	_face.size = Vector2(FACE, FACE)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.visible = false
	add_child(_face)


## A trade's face at a look, once painted: res://art/hands/<trade>_<look>.png; null until then.
static func face(trade: String, look: int) -> Texture2D:
	var key := "%s_%d" % [trade, look]
	if not _faces.has(key):
		var path := "res://art/hands/%s.png" % key
		_faces[key] = null
		if ResourceLoader.exists(path):
			_faces[key] = load(path)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))     # dropped in, not yet imported
			if img != null:
				_faces[key] = ImageTexture.create_from_image(img)
	return _faces[key]


## The hand shown: `state` "" free, "out" away on an expedition, "hurt". For the smoke: `said()` the state as shown.
func show_hand(h: Dictionary, state := "") -> void:
	id = int(h.get("id", -1))
	visible = not h.is_empty()
	if h.is_empty():
		return
	var r: int = int(h.get("rarity", 0))
	var col: Color = Pal.tone_color(Pal.rarity_tone(r)) if r > 0 else Pal.CARD_LINE
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, UI.box(Pal.SELECT if st == "hover" else Pal.PANEL, 6, 3 if picked else 2, Pal.TEXT if picked else col))
	var tex := face(str(h.get("trade", "")), int(h.get("look", 0)))
	_face.texture = tex
	_face.visible = tex != null and state == ""
	var room: float = size.x - 2 * PAD - (FACE + 4.0 if _face.visible else 0.0)
	_name.size.x = room
	UI.fit(_name, [str(h.get("base", ""))])
	_name.add_theme_color_override("font_color", col if r > 0 else Pal.TEXT)
	var t: int = int(h.get("tier", 1))
	var lv: int = int(h.get("lv", 1))
	var forms: Array = ["%s · T%d · level %d" % [Items.rarity_name(h), t, lv], Words.EXPEDITIONS["hand_tier"] % [t, lv], "T%d" % t]
	if state != "":
		var told: String = Words.EXPEDITIONS["hand_out"] if state == "out" else Words.EXPEDITIONS["hand_hurt"]
		forms = forms.map(func(f): return "%s · %s" % [told, f]) + [told]
	UI.fit(_sub, forms)
	_sub.add_theme_color_override("font_color", Pal.TEXT_2 if state == "" else (Pal.WARN if state == "out" else Pal.BAD))
	UI.fit(_trade, [Items.hand_trade_line(h), Items.hand_trade_short(h)])
	var long: Array = Items.hand_lines(h, false)
	var short: Array = Items.hand_lines(h, true)
	var tight: Array = Items.hand_lines(h, true, false, true)
	for k in range(_lines.size()):
		var l: Label = _lines[k]
		l.visible = k < long.size()
		if l.visible:
			UI.fit(l, [long[k], short[k], tight[k]])


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [_name, _sub, _trade]
	for l in _lines:
		if l.visible:
			out.append(l)
	return out


func said() -> String:
	return _sub.text

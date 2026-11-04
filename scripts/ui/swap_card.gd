extends Panel
## The class swap's card on Training (BUILD49 U, item 6; Matt: "class swap - should display what the class does in the
## space on the right"): a class not yet run, armed for a swap. Over the node card, at its size (488 x 318): the class
## and the level it joins at (the crew's floor, item 7); its line as chips (Data.CLASSES "short", a cost in red); its
## one skill (the start's) with its words; its two trees and its two elements as pictures; Swap. Every word from the
## game's data. Barracks shows it and wires the button to its own second press.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Chips := preload("res://scripts/ui/chips.gd")
const People := preload("res://scripts/ui/people.gd")
const Words := preload("res://scripts/sim/words.gd")

const W := 488
const H := 318
const CP := 16
const FACE := 56
const FACE_R := 28
const SKILL_PIC := 40
const TILE_H := 52
const TILE_GAP := 8
const TILE_PIC := 26
const BTN_H := 52
const CHIP_TEXT := 14
const SIZES := [14, 13, 12]          # a line or a tile's name drops a size before it shortens

var face: TextureRect
var face_ring: Panel
var title: Label
var sub: Label
var chips: Chips
var skill_pic: TextureRect
var skill_kicker: Label
var skill_name: Label
var skill_words: Label
var tiles: Array = []             # {panel, pic, name, kind}: the two trees, then the two elements
var swap: Button
var cls := ""                     # the class shown


func _init() -> void:
	size = Vector2(W, H)
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_STOP
	var iw: float = W - 2 * CP
	face_ring = UI.panel(self, Rect2(CP, 14, FACE, FACE), UI.box(Pal.BG, FACE_R, 2, Pal.ACCENT))
	face = _pic(face_ring, Rect2(4, 4, FACE - 8, FACE - 8))
	var tx: float = CP + FACE + 14
	title = UI.label(self, Rect2(tx, 12, W - tx - CP, 34), "", "SemiBold", Pal.TITLE - 4, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	sub = UI.label(self, Rect2(tx, 46, W - tx - CP, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	chips = Chips.new(iw)
	chips.position = Vector2(CP, 82)
	add_child(chips)
	for l in chips._labels:
		l.add_theme_font_size_override("font_size", CHIP_TEXT)     # three chips across the card (the Paramedic's)
	var sy: float = 82 + Chips.CHIP_H + 10
	var sp := UI.panel(self, Rect2(CP, sy, SKILL_PIC, SKILL_PIC), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
	skill_pic = _pic(sp, Rect2(2, 2, SKILL_PIC - 4, SKILL_PIC - 4))
	var kx: float = CP + SKILL_PIC + 10
	skill_kicker = UI.label(self, Rect2(kx, sy - 2, 44, 22), Words.U49_SWAP["skill"], "SemiBold", 12, Pal.ENERGY, HORIZONTAL_ALIGNMENT_LEFT, false)
	UI.track(skill_kicker, 1)
	skill_name = UI.label(self, Rect2(kx + 46, sy - 2, W - CP - kx - 46, 22), "", "SemiBold", Pal.CELL_TEXT_BIG - 1, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	skill_words = UI.label(self, Rect2(kx, sy + 20, W - CP - kx, 20), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	var ty: float = sy + SKILL_PIC + 10
	var tw: float = (iw - 3 * TILE_GAP) / 4.0
	for k in range(4):
		var t := {}
		t["panel"] = UI.panel(self, Rect2(CP + k * (tw + TILE_GAP), ty, tw, TILE_H), UI.box(Pal.BG, 6))
		t["pic"] = _pic(t["panel"], Rect2(5, (TILE_H - TILE_PIC) / 2.0, TILE_PIC, TILE_PIC))
		var lx: float = 5 + TILE_PIC + 5
		t["name"] = UI.label(t["panel"], Rect2(lx, 6, tw - lx - 4, 20), "", "SemiBold", Pal.CELL_TEXT - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["kind"] = UI.label(t["panel"], Rect2(lx, 26, tw - lx - 4, 18), "", "Regular", Pal.CELL_TEXT - 3, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		tiles.append(t)
	swap = UI.button(self, Rect2(CP, H - CP - BTN_H, iw, BTN_H), true)
	swap.add_theme_font_size_override("font_size", Pal.CELL_TEXT_BIG + 2)
	visible = false


func _pic(parent: Control, r: Rect2) -> TextureRect:
	var t := TextureRect.new()
	t.position = r.position
	t.size = r.size
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


## The class's two trees and its two elements, as [{name, kind, slug, element}] (the joints: a class tree and an
## element tree a pair, Data.JOINTS).
static func parts_of(c: String) -> Array:
	var trees: Array = []
	var els: Array = []
	for j in Data.JOINTS:
		if str(j["class"]) != c:
			continue
		trees.append({"name": str(j["tree"]), "kind": Words.U49_SWAP["tree"], "slug": slug(str(j["tree"])), "element": ""})
		var et: Dictionary = Data.element_tree(str(j["element_tree"]))
		var el: String = str(et.get("element", ""))
		els.append({"name": str(j["element_tree"]), "kind": el.substr(0, 1).to_upper() + el.substr(1), "slug": slug(str(j["element_tree"])), "element": el})
	return trees + els


static func slug(nm: String) -> String:
	return nm.to_lower().replace("'", "_").replace(" ", "_")


## The class's own skill: the one on its start (Data.web_start), as {name, line, key}; {} if none.
static func skill_of(c: String) -> Dictionary:
	for k in Data.SKILLS:
		var sd: Dictionary = Data.SKILLS[k]
		if str(sd.get("cls", "")) == c and _on_start(c, str(k)):
			return {"key": str(k), "name": str(sd["name"]), "line": str(sd.get("line", ""))}
	return {}


static func _on_start(c: String, key: String) -> bool:
	var sid: String = Data.web_start(c)
	return sid != "" and str(Data._web_node(sid).get("skill", "")) == key


func show_class(c: String, join_level: int, busy: bool) -> void:
	cls = c
	var cd: Dictionary = {}
	for x in Data.CLASSES:
		if str(x["name"]) == c:
			cd = x
	face.texture = People.portrait(c)
	UI.fit(title, [Words.U49_SWAP["title"] % c, c])
	UI.fit(sub, [Words.U49_SWAP["joins"] % join_level, Words.U49_SWAP["joins_short"] % join_level])
	var items: Array = []
	for s in cd.get("short", []):
		items.append({"forms": [str(s[0])], "colour": Pal.GOOD if bool(s[1]) else Pal.BAD})
	chips.show_chips(items)
	var sk: Dictionary = skill_of(c)
	skill_pic.texture = _art("res://art/skills/%s.png" % str(sk.get("key", ""))) if not sk.is_empty() else null
	UI.fit(skill_name, [str(sk.get("name", ""))])
	var line: String = str(sk.get("line", ""))
	_fit_sized(skill_words, [line, line.replace(" and ", ", ")])
	var parts: Array = parts_of(c)
	for k in range(tiles.size()):
		var t: Dictionary = tiles[k]
		t["panel"].visible = k < parts.size()
		if k >= parts.size():
			continue
		var p: Dictionary = parts[k]
		t["pic"].texture = _art("res://art/nodes/%s.png" % str(p["slug"]))
		_fit_sized(t["name"], [str(p["name"]), str(p["name"]).trim_prefix("The ")])
		UI.fit(t["kind"], [str(p["kind"])])
		t["kind"].add_theme_color_override("font_color", Pal.ELEMENT_COLOURS.get(str(p["element"]), Pal.TEXT_3) if str(p["element"]) != "" else Pal.TEXT_3)
	UI.fit_button(swap, [Words.U49_SWAP["button"] % c, c])
	swap.disabled = busy
	visible = true


## The first form that fits at the biggest of SIZES; past them all, the last form at the smallest, shortened.
func _fit_sized(l: Label, forms: Array) -> void:
	for f in forms:
		for fs in SIZES:
			l.add_theme_font_size_override("font_size", fs)
			if UI.text_width(l, str(f)) <= l.size.x:
				l.text = str(f)
				return
	UI.fit(l, [forms.back()])


static func _art(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func text_nodes() -> Array:
	if not visible:
		return []
	var out: Array = [title, sub, skill_kicker, skill_name, skill_words, swap]
	out.append_array(chips.text_nodes())
	for t in tiles:
		if t["panel"].visible:
			out.append_array([t["name"], t["kind"]])
	return out

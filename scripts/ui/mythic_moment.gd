extends Control
## A mythic found (17 Oct, Matt: the item-colours canvas, "the mythic moment"): the game held, a white flash, the world
## greyed and dimmed behind the sting, then an ember card with the piece - its name, its base and slot, its picture
## glowing, what it does - and Take it. On the floor and room in the pack, Take it takes it; already in the pack, it's
## taken; on the floor with no room, the button says so and the card closes for a ditch. The run goes on where it
## stopped. The game is held while it's up (main._process).

signal done

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Items := preload("res://scripts/sim/items.gd")
const Data := preload("res://scripts/sim/data.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")

const W := 560
var H := 470                       # laid to what it holds (_init)
const PAD := 30
const FLASH_S := 0.2               # the white, gone by here
const GREY_S := 0.4                # the world greyed and dimmed by here
const CARD_AT := 0.5               # the card up
const RISE := 24.0
const PULSE_S := 1.8
const ART_H := 84
const GREY_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.0;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 o = mix(c, vec3(g), 0.65 * amount) * mix(1.0, 0.45, amount);
	float d = distance(SCREEN_UV, vec2(0.5, 0.48));
	o += vec3(0.16, 0.04, 0.0) * amount * clamp(1.0 - d * 2.2, 0.0, 1.0);
	COLOR = vec4(o, 1.0);
}
"""

var item: Dictionary
var sim
var _t := 0.0
var _finished := false
var _grey: ColorRect
var _flash: ColorRect
var _card: Panel
var _sb: StyleBoxFlat
var _kicker: Label
var _name: Label
var _base: Label
var _art: TextureRect
var _words: Label
var _take: Button
var _card_y := 0.0


func _init(it: Dictionary, sim_v) -> void:
	item = it
	sim = sim_v
	mouse_filter = Control.MOUSE_FILTER_STOP
	_grey = ColorRect.new()
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GREY_SHADER
	mat.shader = sh
	_grey.material = mat
	_grey.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_grey)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0.85)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_sb = UI.box(Color("1a1416"), 10, 2, Pal.MYTHIC)
	_card = UI.panel(self, Rect2(0, 0, W, H), _sb)
	_card.modulate.a = 0.0
	var y := PAD
	_kicker = UI.label(_card, Rect2(PAD, y, W - 2 * PAD, 20), "MYTHIC", "SemiBold", 13, Pal.MYTHIC, HORIZONTAL_ALIGNMENT_CENTER)
	UI.track(_kicker, 4)
	y += 30
	_name = UI.label(_card, Rect2(PAD, y, W - 2 * PAD, 40), Items.full_name(it), "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	y += 44
	_base = UI.label(_card, Rect2(PAD, y, W - 2 * PAD, 22), "%s · %s" % [str(it["base"]), str(it["slot"])], "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER)
	y += 34
	_art = TextureRect.new()
	_art.texture = Items.art(it)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art.position = Vector2(PAD, y)
	_art.size = Vector2(W - 2 * PAD, ART_H)
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := ShaderMaterial.new()
	var gs := Shader.new()
	gs.code = ItemCell.GLOW_SHADER
	gm.shader = gs
	gm.set_shader_parameter("glow", Color(Pal.MYTHIC, 0.9))
	_art.material = gm
	_card.add_child(_art)
	if _art.texture != null:
		y += ART_H + 16
	else:
		_art.visible = false                   # no picture made yet: the words come up under the base
	_words = UI.label(_card, Rect2(PAD, y, W - 2 * PAD, 70), words_of(it), "Medium", Pal.CELL_TEXT_BIG, Color("ffb59c"), HORIZONTAL_ALIGNMENT_CENTER, false)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	y += 84
	_take = UI.button(_card, Rect2((W - 220) / 2.0, y, 220, Pal.BUTTON_H), true)
	_take.text = take_words()
	H = y + Pal.BUTTON_H + PAD
	_card.size.y = H
	_take.pressed.connect(_on_take)
	var tsb := UI.box(Pal.MYTHIC, 8)
	for st in ["normal", "hover", "pressed", "focus"]:
		_take.add_theme_stylebox_override(st, tsb)
	_take.add_theme_color_override("font_color", Color("1a0e08"))
	_take.add_theme_color_override("font_hover_color", Color("1a0e08"))
	_take.add_theme_color_override("font_pressed_color", Color("1a0e08"))


## What the piece does: its unique's words, else its short.
static func words_of(it: Dictionary) -> String:
	for u in Data.UNIQUES:
		if str(u["name"]) == str(it.get("unique", "")):
			return str(u.get("words", u.get("short", "")))
	return ""


## Where it is: in the pack (taken), on the floor with room (Take it takes it), or on the floor with none.
func where() -> String:
	if sim == null or not sim.on_mission():
		return "pack"
	for f in sim.mission.get("floor", []):
		if int(f["id"]) == int(item["id"]):
			return "floor" if sim.floor_fits(f) else "no_room"
	return "pack"


func take_words() -> String:
	return "No room in the pack: ditch something" if where() == "no_room" else "Take it"


func _ready() -> void:
	_place(get_viewport_rect().size)
	get_viewport().size_changed.connect(func(): _place(get_viewport_rect().size))


func _place(s: Vector2) -> void:
	size = s
	_grey.size = s
	_flash.size = s
	_card_y = floorf((s.y - H) / 2.0)
	_card.position = Vector2(floorf((s.x - W) / 2.0), _card_y + RISE * (1.0 - _rise()))


func _rise() -> float:
	return clampf((_t - CARD_AT) / 0.3, 0.0, 1.0)


func _process(dt: float) -> void:
	if _finished:
		return
	_t += dt
	_flash.color.a = 0.85 * clampf(1.0 - _t / FLASH_S, 0.0, 1.0)
	(_grey.material as ShaderMaterial).set_shader_parameter("amount", clampf(_t / GREY_S, 0.0, 1.0))
	var r: float = _rise()
	_card.modulate.a = r
	_card.position.y = _card_y + RISE * (1.0 - r)
	var k: float = 0.5 - 0.5 * cos(maxf(0.0, _t - CARD_AT) * TAU / PULSE_S)
	_sb.shadow_color = Color(Pal.MYTHIC, 0.35 + 0.35 * k)
	_sb.shadow_size = int(round(10.0 + 20.0 * k))


func _on_take() -> void:
	if where() == "floor":
		sim.take_floor(int(item["id"]))
	finish()


func finish() -> void:
	if _finished:
		return
	_finished = true
	done.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if _finished or _t < CARD_AT:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		if event.is_action_pressed("ui_accept"):
			_on_take()
		else:
			finish()


## For the tests: the labels showing.
func text_nodes() -> Array:
	return [_kicker, _name, _base, _words, _take]

extends Control
## The menus: the title screen, the pause menu and the save slots (Pithole's
## menu_shell.md §12). One panel: a heading, a line under it, and up to five
## rows. A row is a full-width button carrying a name and a line of detail. A row
## that needs a second press - overwriting a slot, starting over - says so in its
## detail line on the first. Fixed geometry, like the cards - except where the
## words run long: the line under the heading wraps over up to four lines (the
## away report) and pushes the rows down, and a row's detail wraps over two,
## the row growing to hold it. Nothing in a menu trails off.
##
## The title screen (opaque) stands on art/title.png when it exists - the
## town after the collapse, covering the screen, the panel over its left
## third on a dark glass so the view stays readable - and on the plain
## ground until it does.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const PANEL_W := 880
const PANEL_H := 760
const PAD := 48
const ROW_W := PANEL_W - 2 * PAD          # 784
const ROW_H := 96
const DETAIL_H := 28                      # a detail line; a second one grows the row by this
const ROW_GAP := 16
const ROWS := 5
const ROWS_Y := 196
const SUB_Y := 116
const SUB_H := 32                         # a sub line's height
const SUB_LINES := 4                      # the most the sub wraps over
const TITLE_ART := "res://art/title.png"
const WORDMARK_ART := "res://art/wordmark.png"
const PICTURE_X := 96              # the panel's left edge over a picture
const WORDMARK_SCALE := 3          # the painting's own scale (640 x 360 drawn at 1920 x 1080)
const PICTURE_BOTTOM := 40         # the panel's foot over a picture; the wordmark sits above the panel
const WORDMARK_GAP := 24

var _dim: ColorRect
var _backdrop: Panel
var _picture: TextureRect          # the title's painting, when there is one
var _wordmark: TextureRect         # "Fiat - let it be done" over the sky, when there is one
var _panel: Panel
var _title: Label
var _subs: Array[Label] = []              # the line under the heading, wrapped
var _rows: Array[Button] = []
var _names: Array[Label] = []
var _details: Array[Label] = []
var _details2: Array[Label] = []           # the detail's second line, when it needs one
var _rows_y := ROWS_Y                      # where the first row sits this time
var _items: Array = []
var _armed := -1                            # the row waiting for its second press
var _back := Callable()


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop = UI.panel(self, Rect2(0, 0, 1920, 1200), UI.box(Pal.BG, 0))
	_picture = TextureRect.new()
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picture.visible = false
	if ResourceLoader.exists(TITLE_ART):
		_picture.texture = load(TITLE_ART)
	elif FileAccess.file_exists(TITLE_ART):
		var img := Image.load_from_file(ProjectSettings.globalize_path(TITLE_ART))
		if img != null:
			_picture.texture = ImageTexture.create_from_image(img)
	_backdrop.add_child(_picture)
	_wordmark = TextureRect.new()
	_wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wordmark.stretch_mode = TextureRect.STRETCH_SCALE
	_wordmark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wordmark.visible = false
	if ResourceLoader.exists(WORDMARK_ART):
		_wordmark.texture = load(WORDMARK_ART)
	elif FileAccess.file_exists(WORDMARK_ART):
		var wimg := Image.load_from_file(ProjectSettings.globalize_path(WORDMARK_ART))
		if wimg != null:
			_wordmark.texture = ImageTexture.create_from_image(wimg)
	if _wordmark.texture != null:
		_wordmark.size = _wordmark.texture.get_size() * WORDMARK_SCALE
	_backdrop.add_child(_wordmark)
	_dim = ColorRect.new()
	_dim.color = Pal.DIM
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_panel = UI.panel(self, Rect2(0, 0, PANEL_W, PANEL_H), UI.box(Pal.CARD, 12, 1, Pal.CARD_LINE))
	_title = UI.label(_panel, Rect2(PAD, 40, ROW_W, 72), "", "Bold", 56, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	for k in range(SUB_LINES):
		_subs.append(UI.label(_panel, Rect2(PAD, SUB_Y + k * SUB_H, ROW_W, SUB_H), "", "Regular", Pal.LINE, Pal.TEXT_2,
				HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(ROWS):
		var b := Button.new()
		b.position = Vector2(PAD, ROWS_Y + i * (ROW_H + ROW_GAP))
		b.size = Vector2(ROW_W, ROW_H)
		b.focus_mode = Control.FOCUS_ALL
		b.text = ""
		_style(b)
		b.pressed.connect(_on_pressed.bind(i))
		_panel.add_child(b)
		_rows.append(b)
		_names.append(UI.label(b, Rect2(24, 12, ROW_W - 48, 40), "", "SemiBold", Pal.TITLE, Pal.TEXT,
				HORIZONTAL_ALIGNMENT_LEFT, false))
		_details.append(UI.label(b, Rect2(24, 52, ROW_W - 48, 32), "", "Regular", Pal.FLOOR, Pal.TEXT_2))
		_details2.append(UI.label(b, Rect2(24, 52 + DETAIL_H, ROW_W - 48, 32), "", "Regular", Pal.FLOOR, Pal.TEXT_2))
	visible = false


## items: [{name, detail, action: Callable, enabled (true), confirm ("")}]. With
## `confirm` set, the first press arms the row and shows it; the second acts.
## `opaque` hides the game behind (the title screen); otherwise it dims it.
## `title` is a String, or an Array of forms, long to short, the first that fits shown.
func open(title, sub: String, items: Array, back := Callable(), opaque := false) -> void:
	assert(items.size() <= ROWS, "a menu holds five rows")
	_items = items
	_armed = -1
	_back = back
	UI.fit(_title, title if title is Array else [title])
	UI.wrap(_subs, sub)
	_backdrop.visible = opaque
	_picture.visible = opaque and _picture.texture != null
	_wordmark.visible = _picture.visible and _wordmark.texture != null
	_dim.visible = not opaque
	# over the painting the panel is dark glass at the left, the rows alone -
	# the painting and the wordmark carry the name; otherwise a card in the
	# middle with the heading
	_panel.add_theme_stylebox_override("panel", UI.box(Color(Pal.CARD, 0.88) if _picture.visible else Pal.CARD, 12, 1, Pal.CARD_LINE))
	_title.visible = not _picture.visible
	for l in _subs:
		l.visible = not _picture.visible
	# a sub over more than one line pushes the rows down
	_rows_y = PAD if _picture.visible else maxi(ROWS_Y, SUB_Y + sub_lines() * SUB_H + 48)
	var first := -1
	for i in range(ROWS):
		var on := i < items.size()
		_rows[i].visible = on
		if not on:
			continue
		var it: Dictionary = items[i]
		_rows[i].disabled = not it.get("enabled", true)
		_names[i].text = it.get("name", "")
		_names[i].add_theme_color_override("font_color", Pal.TEXT if not _rows[i].disabled else Pal.TEXT_3)
		_show_detail(i)
		if first < 0 and not _rows[i].disabled:
			first = i
	_lay_rows()
	visible = true
	if first >= 0 and is_inside_tree():
		_rows[first].grab_focus()


func close() -> void:
	visible = false
	_items = []
	_armed = -1


## Esc: whatever this menu's way back is, if it has one.
func back() -> void:
	if _back.is_valid():
		_back.call()


## The rows from _rows_y, each as tall as its detail needs; the panel grows
## to hold them when it must (the title screen's panel is only as tall as its rows).
func _lay_rows() -> void:
	var y := _rows_y
	for i in range(_items.size()):
		_rows[i].position.y = y
		_rows[i].size.y = ROW_H + (DETAIL_H if _details2[i].text != "" else 0)
		y += int(_rows[i].size.y) + ROW_GAP
	var rows_h := y - ROW_GAP + PAD
	_panel.size.y = rows_h if _picture.visible else maxi(PANEL_H, rows_h)
	layout(get_viewport_rect().size if is_inside_tree() else Vector2(1920, 1080))


func layout(s: Vector2) -> void:
	_backdrop.size = s
	_picture.size = s
	_panel.position = ((s - _panel.size) / 2.0).floor()
	if _picture.visible:
		_panel.position = Vector2(floorf((s.x - 1920.0) / 2.0) + PICTURE_X, s.y - PICTURE_BOTTOM - _panel.size.y)
	if _wordmark.visible:
		_wordmark.position = Vector2(_panel.position.x, _panel.position.y - WORDMARK_GAP - _wordmark.size.y)


func _on_pressed(i: int) -> void:
	if i >= _items.size():
		return
	var it: Dictionary = _items[i]
	if it.get("confirm", "") != "" and _armed != i:
		var was := _armed
		_armed = i
		if was >= 0:
			_show_detail(was)
		_show_detail(i)
		_lay_rows()
		return
	var a: Callable = it.get("action", Callable())
	if a.is_valid():
		a.call()


## The detail: `detail` (or `confirm` when the row's armed) over one line, or
## two when it runs long. The row grows for the second (_lay_rows).
func _show_detail(i: int) -> void:
	var it: Dictionary = _items[i]
	var armed := i == _armed
	UI.wrap([_details[i], _details2[i]], it.get("confirm", "") if armed else it.get("detail", ""))
	for l in [_details[i], _details2[i]]:
		l.add_theme_color_override("font_color", Pal.WARN if armed else Pal.TEXT_2)
	# a row with no detail carries its name in the middle
	_names[i].position.y = 12 if _details[i].text != "" else 28


func _style(b: Button) -> void:
	for pair in [["normal", Pal.PANEL], ["hover", Pal.SELECT], ["pressed", Pal.BUTTON_PRESS],
			["hover_pressed", Pal.BUTTON_PRESS], ["disabled", Pal.BUTTON_OFF]]:
		b.add_theme_stylebox_override(pair[0], UI.box(pair[1], 8))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 8, 2, Pal.ACCENT))


## For tests/ui_check.gd.
func text_nodes() -> Array:
	var out: Array = []
	if _title.visible:
		out.append(_title)
		for l in _subs:
			if l.text != "":
				out.append(l)
	for i in range(ROWS):
		if _rows[i].visible:
			out.append_array([_names[i], _details[i], _details2[i]])
	return out


func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.size)


## For the tests: press row i as a player would.
func press(i: int) -> void:
	_on_pressed(i)


func row_names() -> Array:
	var out: Array = []
	for i in range(_items.size()):
		out.append(_names[i].text)
	return out


func detail(i: int) -> String:
	return _details[i].text if _details2[i].text == "" else _details[i].text + " " + _details2[i].text


## How many lines the sub takes.
func sub_lines() -> int:
	var n := 0
	for l in _subs:
		if l.text != "":
			n += 1
	return n


func sub() -> String:
	var parts := []
	for l in _subs:
		if l.text != "":
			parts.append(l.text)
	return " ".join(parts)

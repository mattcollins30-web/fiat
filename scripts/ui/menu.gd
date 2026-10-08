extends Control
## The menus: the title screen, the pause menu and the save slots (Pithole's
## menu_shell.md §12), in the rail's shape (8 Oct, Matt: "looks like a default
## godot project"). The rows are a ledger: ruled by hairlines, no boxes, the lit
## one (the focus) on the card ground with a gold bar at its left, a stamp with a
## glyph where the item brings one (the title's and the pause's rows do). A row
## carries a name and a line of detail; a row that needs a second press -
## overwriting a slot, starting over - says so in its detail line on the first.
## A row's detail wraps over two, the row growing to hold it. Nothing in a menu
## trails off.
##
## Three shapes:
## - the card (default): a heading, a line under it (wrapped over up to four:
##   the away report), the rows; in the middle of the screen over a dim.
## - the title (`opaque`, over art/title.png - Title A on the canvas): a column
##   down the painting's left, fading into it; the wordmark (art/wordmark.png,
##   200 x 80 drawn at the painting's 3x) at its head, the rows under, the studio
##   at the foot. On the plain ground until the painting exists.
## - the drawer (`dock`: the rail's rect - Pause B): the panel takes the rail's
##   place over the dimmed game, edged gold, a kicker strip at its head, the
##   rows names only.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")

const PANEL_W := 880
const PANEL_H := 760
const PAD := 48
const ROW_W := PANEL_W - 2 * PAD          # 784
const ROW_H := 92                         # a row with a detail line
const ROW_PLAIN_H := 72                   # a row with none
const DETAIL_H := 28                      # a second detail line grows the row by this
const DETAIL_SIZE := 20                   # the detail's type, under the name's 30
const ROWS := 5
const ROWS_Y := 196
const SUB_Y := 116
const SUB_H := 32                         # a sub line's height
const SUB_LINES := 4                      # the most the sub wraps over
const STAMP := 56                         # the stamp, as the rail's
const STAMP_X := 16
const TEXT_X := STAMP_X + STAMP + 16      # the name's x with a stamp
const TEXT_PLAIN_X := 24                  # without one
const TITLE_ART := "res://art/title.png"
const WORDMARK_ART := "res://art/wordmark.png"
const COLUMN_W := 650                     # the title's column over the painting
const COLUMN_X := 60                      # the rows and the wordmark in it
const COLUMN_ROW_W := 570
const WORDMARK_SCALE := 3                 # the painting's own scale (640 x 360 drawn at 1920 x 1080)
const WORDMARK_Y := 50
const COLUMN_ROWS_Y := 375
const FOOT_H := 30
const DRAWER_HEAD_H := 44                 # the drawer's kicker strip, as the rail's heading

var _dim: ColorRect
var _backdrop: Panel
var _picture: TextureRect          # the title's painting, when there is one
var _column: TextureRect           # the dark column over the painting's left, fading into it
var _wordmark: TextureRect         # "FIAT - let it be done" at the column's head
var _foot_left: Label
var _foot_right: Label
var _panel: Panel
var _title: Label
var _kicker: Label                 # the drawer's head strip
var _kicker_rule: Panel
var _subs: Array[Label] = []              # the line under the heading, wrapped
var _rows: Array[Button] = []
var _stamps: Array[Panel] = []
var _glyphs: Array[TextureRect] = []
var _names: Array[Label] = []
var _details: Array[Label] = []
var _details2: Array[Label] = []           # the detail's second line, when it needs one
var _rules: Array[Panel] = []              # the hairline under each row
var _rows_y := ROWS_Y                      # where the first row sits this time
var _row_w := ROW_W
var _row_x := PAD
var _items: Array = []
var _armed := -1                            # the row waiting for its second press
var _back := Callable()
var _dock := Rect2()                        # the drawer's place when it has one
var _shape := "card"                        # "card", "title" or "drawer"


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
	_picture.texture = _load_art(TITLE_ART)
	_backdrop.add_child(_picture)
	# the column: a horizontal gradient, the ground's dark fading into the painting at its right
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.82, 1.0])
	grad.colors = PackedColorArray([Color(Pal.BG, 0.96), Color(Pal.BG, 0.92), Color(Pal.BG, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 64
	gt.height = 4
	_column = TextureRect.new()
	_column.texture = gt
	_column.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_column.stretch_mode = TextureRect.STRETCH_SCALE
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.visible = false
	_backdrop.add_child(_column)
	_wordmark = TextureRect.new()
	_wordmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wordmark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_wordmark.stretch_mode = TextureRect.STRETCH_SCALE
	_wordmark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wordmark.visible = false
	_wordmark.texture = _load_art(WORDMARK_ART, true)       # from the file: a stale import of the old wordmark (260 x 108) ran it out of the column on the Legion
	if _wordmark.texture != null:
		_wordmark.size = _wordmark.texture.get_size() * WORDMARK_SCALE
	_backdrop.add_child(_wordmark)
	_foot_left = UI.label(_backdrop, Rect2(0, 0, 300, FOOT_H), "MUNDANE STUDIOS", "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_foot_right = UI.label(_backdrop, Rect2(0, 0, 300, FOOT_H), _build_words(), "Medium", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	_foot_left.visible = false
	_foot_right.visible = false
	_dim = ColorRect.new()
	_dim.color = Pal.DIM
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE          # sized in layout(): a full-rect preset set before the node is in the tree left it at nothing
	add_child(_dim)
	_panel = UI.panel(self, Rect2(0, 0, PANEL_W, PANEL_H), UI.box(Pal.CARD, 12, 1, Pal.CARD_LINE))
	_title = UI.label(_panel, Rect2(PAD, 40, ROW_W, 72), "", "Bold", 56, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_kicker = UI.label(_panel, Rect2(22, 0, 300, DRAWER_HEAD_H), "", "Medium", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_kicker.visible = false
	_kicker_rule = UI.panel(_panel, Rect2(0, DRAWER_HEAD_H - 1, Pal.RAIL_W, 1), UI.box(Pal.CARD_LINE, 0))
	_kicker_rule.visible = false
	for k in range(SUB_LINES):
		_subs.append(UI.label(_panel, Rect2(PAD, SUB_Y + k * SUB_H, ROW_W, SUB_H), "", "Regular", Pal.LINE, Pal.TEXT_2,
				HORIZONTAL_ALIGNMENT_LEFT, false))
	for i in range(ROWS):
		var b := Button.new()
		b.position = Vector2(PAD, ROWS_Y + i * ROW_H)
		b.size = Vector2(ROW_W, ROW_H)
		b.focus_mode = Control.FOCUS_ALL
		b.text = ""
		_style(b)
		b.pressed.connect(_on_pressed.bind(i))
		_panel.add_child(b)
		_rows.append(b)
		var st := UI.panel(b, Rect2(STAMP_X, 0, STAMP, STAMP), UI.box(Pal.STAMP, 8, 1, Pal.CARD_LINE))
		_stamps.append(st)
		_glyphs.append(UI.glyph(st, Rect2(9, 9, STAMP - 18, STAMP - 18), "menu_continue", Pal.TEXT_2))
		_names.append(UI.label(b, Rect2(TEXT_X, 12, ROW_W - TEXT_X - 24, 36), "", "SemiBold", Pal.NAME, Pal.TEXT,
				HORIZONTAL_ALIGNMENT_LEFT, false))
		_details.append(UI.label(b, Rect2(TEXT_X, 48, ROW_W - TEXT_X - 24, DETAIL_H), "", "Regular", DETAIL_SIZE, Pal.TEXT_2))
		_details2.append(UI.label(b, Rect2(TEXT_X, 48 + DETAIL_H, ROW_W - TEXT_X - 24, DETAIL_H), "", "Regular", DETAIL_SIZE, Pal.TEXT_2))
		_rules.append(UI.panel(b, Rect2(0, ROW_H - 1, ROW_W, 1), UI.box(Pal.RAIL_RULE, 0)))
	visible = false


static func _load_art(path: String, from_file := false) -> Texture2D:
	if ResourceLoader.exists(path) and not from_file:
		return load(path)
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			return ImageTexture.create_from_image(img)
	return null


static func _build_words() -> String:
	var v := str(ProjectSettings.get_setting("application/config/version", ""))
	return ("FIAT · %s" % v) if v != "" else "FIAT"


## items: [{name, detail, action: Callable, enabled (true), confirm (""), color (the name's), glyph ("")}].
## With `confirm` set, the first press arms the row and shows it; the second acts. `opaque` hides
## the game behind (the title screen, the lost camp); otherwise it dims it. `dock` (a Rect2 in the
## viewport, the rail's) makes the drawer; `picture` puts the title's painting behind (the title shape). `title` is a String, or an Array of forms, long to short, the first that fits shown.
func open(title, sub: String, items: Array, back := Callable(), opaque := false, dock := Rect2(), picture := false) -> void:
	assert(items.size() <= ROWS, "a menu holds five rows")
	_items = items
	_armed = -1
	_back = back
	_dock = dock
	_backdrop.visible = opaque
	_picture.visible = opaque and picture and _picture.texture != null     # the title alone stands on the painting; the lost camp's card is on the plain ground, its words up
	_shape = "title" if _picture.visible else ("drawer" if dock.size.x > 0.0 else "card")
	_column.visible = _shape == "title"
	_wordmark.visible = _shape == "title" and _wordmark.texture != null
	_foot_left.visible = _shape == "title"
	_foot_right.visible = _shape == "title"
	_dim.visible = not opaque
	UI.fit(_title, title if title is Array else [title])
	UI.wrap(_subs, sub)
	# the shapes: the title's column carries no panel (the rows sit on it); the drawer is the rail's
	# panel edged gold with a kicker; the card is the card
	match _shape:
		"title":
			_panel.add_theme_stylebox_override("panel", UI.box(Color.TRANSPARENT, 0))
			_row_x = 0
			_row_w = COLUMN_ROW_W
		"drawer":
			_panel.add_theme_stylebox_override("panel", UI.box(Pal.PANEL, 8, 1, Pal.ACCENT))
			_row_x = 0
			_row_w = int(dock.size.x)
		_:
			_panel.add_theme_stylebox_override("panel", UI.box(Pal.CARD, 12, 1, Pal.CARD_LINE))
			_row_x = PAD
			_row_w = ROW_W
	_title.visible = _shape == "card"
	for l in _subs:
		l.visible = _shape == "card"
	_kicker.visible = _shape == "drawer"
	_kicker_rule.visible = _shape == "drawer"
	if _shape == "drawer":
		var kick: String = str(title if title is String else title[0]).to_upper()
		_kicker.size.x = dock.size.x - 44
		UI.fit(_kicker, [kick + (" · " + sub.to_upper() if sub != "" else ""), kick])
		_kicker_rule.size.x = dock.size.x
	# a sub over more than one line pushes the rows down
	_rows_y = DRAWER_HEAD_H if _shape == "drawer" else (0 if _shape == "title" else maxi(ROWS_Y, SUB_Y + sub_lines() * SUB_H + 48))
	var stamps: bool = items.any(func(it): return it.get("glyph", "") != "")
	var first := -1
	for i in range(ROWS):
		var on := i < items.size()
		_rows[i].visible = on
		if not on:
			continue
		var it: Dictionary = items[i]
		_rows[i].disabled = not it.get("enabled", true)
		_names[i].text = it.get("name", "")
		_names[i].add_theme_color_override("font_color", it.get("color", Pal.TEXT) if not _rows[i].disabled else Pal.TEXT_3)
		var g: String = it.get("glyph", "")
		_stamps[i].visible = stamps
		_glyphs[i].visible = g != ""
		if g != "":
			_glyphs[i].texture = UI.glyph_texture(g)
			_glyphs[i].modulate = Pal.TEXT_2 if UI.glyph_mono(g) else Color.WHITE
		var tx := TEXT_X if stamps else TEXT_PLAIN_X
		for l in [_names[i], _details[i], _details2[i]]:
			l.position.x = tx
			l.size.x = _row_w - tx - 24
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


## The rows from _rows_y, each as tall as its detail needs, ruled between; the
## panel grows to hold them when it must (the title's column and the drawer are
## fixed; the card is at least PANEL_H).
func _lay_rows() -> void:
	var y := _rows_y
	for i in range(_items.size()):
		var b := _rows[i]
		b.position = Vector2(_row_x, y)
		var h: int = ROW_H if _details[i].text != "" else ROW_PLAIN_H
		if _details2[i].text != "":
			h += DETAIL_H
		b.size = Vector2(_row_w, h)
		_stamps[i].position.y = floorf((h - STAMP) / 2.0)
		# the name centred in a plain row, up with its detail under in a full one
		_names[i].position.y = floorf((h - 36) / 2.0) if _details[i].text == "" else 12
		_details[i].position.y = 48
		_details2[i].position.y = 48 + DETAIL_H
		_rules[i].position.y = h - 1
		_rules[i].size.x = _row_w
		_rules[i].visible = i < _items.size() - 1 or _shape == "card"
		y += h
	var rows_h := y + PAD
	match _shape:
		"title":
			_panel.size = Vector2(COLUMN_ROW_W, y)
		"drawer":
			_panel.size = _dock.size
		_:
			_panel.size = Vector2(PANEL_W, maxi(PANEL_H, rows_h))
	layout(get_viewport_rect().size if is_inside_tree() else Vector2(1920, 1080))


func layout(s: Vector2) -> void:
	_backdrop.size = s
	_picture.size = s
	_dim.position = Vector2.ZERO
	_dim.size = s
	var x0 := floorf((s.x - 1920.0) / 2.0)
	match _shape:
		"title":
			_column.position = Vector2(x0, 0)
			_column.size = Vector2(COLUMN_W, s.y)
			_wordmark.position = Vector2(x0 + COLUMN_X, WORDMARK_Y)
			_panel.position = Vector2(x0 + COLUMN_X, COLUMN_ROWS_Y)
			_foot_left.position = Vector2(x0 + COLUMN_X, s.y - 36 - FOOT_H)
			_foot_right.position = Vector2(x0 + COLUMN_X + COLUMN_ROW_W - 300, s.y - 36 - FOOT_H)
			# the build, then the window and the canvas as the game sees them: what the Deck is actually getting (8 Oct)
			var win := get_window()
			var ws: Vector2i = win.size if win != null else Vector2i.ZERO
			UI.fit(_foot_right, ["%s · %d×%d → %d×%d" % [_build_words(), ws.x, ws.y, int(s.x), int(s.y)], _build_words()])
		"drawer":
			_panel.position = _dock.position
		_:
			_panel.position = ((s - _panel.size) / 2.0).floor()


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
## two when it runs long. The row grows for the second (_lay_rows). The drawer
## carries names only (the rail's width), but an armed row's confirm still shows.
func _show_detail(i: int) -> void:
	var it: Dictionary = _items[i]
	var armed := i == _armed
	var words: String = it.get("confirm", "") if armed else ("" if _shape == "drawer" else it.get("detail", ""))
	UI.wrap([_details[i], _details2[i]], words)
	for l in [_details[i], _details2[i]]:
		l.add_theme_color_override("font_color", Pal.WARN if armed else Pal.TEXT_2)


## A row's look: nothing on the ground, the card ground with a gold bar when it
## has the focus (the lit row), the hover's wash under the mouse.
func _style(b: Button) -> void:
	for pair in [["normal", Color.TRANSPARENT], ["hover", Pal.RAIL_HOVER], ["pressed", Pal.CARD],
			["hover_pressed", Pal.CARD], ["disabled", Color.TRANSPARENT]]:
		b.add_theme_stylebox_override(pair[0], UI.box(pair[1], 0))
	var lit := UI.box(Pal.CARD, 0)
	lit.border_width_left = 4
	lit.border_color = Pal.ACCENT
	b.add_theme_stylebox_override("focus", lit)


## For tests/ui_check.gd.
func text_nodes() -> Array:
	var out: Array = []
	if _title.visible:
		out.append(_title)
		for l in _subs:
			if l.text != "":
				out.append(l)
	if _kicker.visible:
		out.append(_kicker)
	if _foot_left.visible:
		out.append_array([_foot_left, _foot_right])
	for i in range(ROWS):
		if _rows[i].visible:
			out.append_array([_names[i], _details[i], _details2[i]])
	return out


func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.size)


func shape() -> String:
	return _shape


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

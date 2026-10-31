extends Control
## The Armoury's screen - the first thing in the shell that isn't eight cards.
## Tarkov's layout in text: the body's slots down the left, the stash as a
## grid on the right, and under the grid a compare panel for whatever is
## selected against what's fitted in its slot, with Equip, Unequip and Sell.
## Fixed geometry inside the card grid's 1536 x 864, like everything else.
##
## A stash cell has no picture yet, so it carries the slot's short name, the
## item's headline figure, its tier, and its rarity as the border - the
## shape an icon will drop into later.

signal acted
signal bench(id)                   # the Bench's menu for this item

const Pal := preload("res://scripts/ui/palette.gd")
const Arm := preload("res://scripts/ui/arm.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const Words := preload("res://scripts/sim/words.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const Containers := preload("res://scripts/ui/containers.gd")
const Body := preload("res://scripts/ui/body.gd")
const PickPanel := preload("res://scripts/ui/pick_panel.gd")
const People := preload("res://scripts/ui/people.gd")
const RulesPanel := preload("res://scripts/ui/rules_panel.gd")

const BODY_W := Body.WIDTH                                    # 608
## The runner strip over the loadout (10 Oct, Runner-R A): the face, the level, HP with its bar, the damage, the
## armour and the pace - who this is, before what they wear.
const STRIP_H := 88
const BODY_Y := STRIP_H + 8                                   # 96: the loadout (654), then the rig
const CONTAINERS_Y := BODY_Y + Body.HEIGHT + 8                # 758: the rig under the loadout, to 916 (the pack's map went)
const GAP := 24
const GRID_X := BODY_W + GAP
const GRID_W := Inventory.WIDTH                                # 904
const GRID_H := Inventory.HEIGHT                               # 588
const PANEL_Y := GRID_H + GAP                                 # 612
const PANEL_H := Pal.ROOM_H - PANEL_Y                         # 304
const PANEL_PAD := 20
const PANEL_LINES := 6             # figure, what it takes, three affixes with their tiers, the swap word
const LINE_H := 26
@warning_ignore("integer_division")
const COL_W := (GRID_W - 3 * PANEL_PAD) / 2                   # each half of the compare panel
const RULES_W := 200
const LOADOUT_Y := 84               # under the empty panel's line
const LOADOUT_H := 150

var sim
var selected := {}                 # {"kind": "stash", "id": n} or {"kind": "slot", "slot": s}, or {}
var _body                          # the slots as boxes to drop on
var _inv                           # the stash grid
var _containers                    # the rig and the pack
var _pick                          # the pick panel (pick_panel.gd): the pick against the fitted, the buttons
var _actions: Array = []           # what the panel's buttons do, by index; _press follows the item after
var _shown := ""                   # what the screen last drew, so a refresh that changes nothing redraws nothing
var _strip: Panel
var _face: TextureRect
var _who: Label
var _hp: Label
var _hp_track: Panel
var _hp_fill: Panel
var _dps: Label
var _armour: Label
var _pace: Label
var _carry: Label
var rules_button: Button           # the loot filter's (24 Oct): on the stash's second bar, after Select
var rules_panel                    # rules_panel.gd, over the stash and the pick panel while it's open
var loadout_cards: Array = []      # the three loadouts (24 Oct, the endgame chase): in the pick panel while nothing's picked


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the runner strip: who, HP, damage, armour, pace
	_strip = UI.panel(self, Rect2(0, 0, BODY_W, STRIP_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_face = People.rect(_strip, Vector2(12, (STRIP_H - 64) / 2.0), 0.5)
	_who = UI.label(_strip, Rect2(90, 6, 230, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_hp = UI.label(_strip, Rect2(90, 26, 230, 32), "", "SemiBold", Pal.LINE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_hp_track = UI.panel(_strip, Rect2(90, 64, 220, 8), UI.box(Pal.BG, 4))
	_hp_fill = UI.panel(_hp_track, Rect2(0, 0, 0, 8), UI.box(Pal.GOOD, 4))
	_dps = UI.label(_strip, Rect2(330, 8, 150, 32), "", "SemiBold", Pal.LINE, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_armour = UI.label(_strip, Rect2(330, 44, 150, 24), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_pace = UI.label(_strip, Rect2(486, 12, BODY_W - 486 - 12, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_carry = UI.label(_strip, Rect2(486, 44, BODY_W - 486 - 12, 22), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	# the loadout: drag gear from the stash onto its card; drag it off to the stash
	_body = Body.new()
	_body.position = Vector2(0, BODY_Y)
	_body.picked.connect(_pick_slot)
	_body.equip.connect(_on_equip_drop)
	add_child(_body)
	# the rig and the pack, as grids: drag a med or a stack from the stash onto
	# the rig; drag a rig slot back; the pack is what a run brings home
	_containers = Containers.new()
	_containers.position = Vector2(0, CONTAINERS_Y)
	_containers.picked.connect(_on_rig_pick)
	_containers.take.connect(_on_take)
	add_child(_containers)
	_inv = Inventory.new()
	_inv.position = Vector2(GRID_X, 0)
	_inv.drag_src = "stash"
	_inv.stash_tabs = true                 # the shared tab and the class's own (21 Oct, the crew)
	_inv.moved_reads = true               # the Kit's arrows as "Swap, parts and all" would wear a piece (the fix round, 29 Oct)
	_inv.accepts = ["rig", "body"]
	_inv.picked.connect(_on_inv_pick)
	_inv.acted.connect(_on_inv_acted)
	_inv.dropped.connect(_on_stash_drop)
	add_child(_inv)
	_pick = PickPanel.new(GRID_W, PANEL_H)
	_pick.position = Vector2(GRID_X, PANEL_Y)
	add_child(_pick)
	for i in range(PickPanel.BUTTONS):
		_actions.append(Callable())
	# the loot filter: its button where Select-many's Sell goes (hidden while that shows), its panel over the right half
	var rx: float = _inv._many_button.position.x + Inventory.MANY_W + 6
	rules_button = UI.button(self, Rect2(GRID_X + rx, _inv._many_button.position.y, RULES_W, Inventory.BAR_H), false)
	rules_button.add_theme_font_size_override("font_size", 18)
	rules_button.pressed.connect(open_rules)
	rules_panel = RulesPanel.new()
	rules_panel.position = Vector2(GRID_X, 0)
	rules_panel.visible = false
	rules_panel.closed.connect(close_rules)
	rules_panel.changed.connect(func(): acted.emit())
	add_child(rules_panel)
	# the loadouts: three cards across the empty pick panel, between its line and its toggles
	var lw: float = (GRID_W - 2 * PANEL_PAD - 2 * 12) / 3.0
	for i in range(Data.LOADOUTS):
		var x: float = GRID_X + PANEL_PAD + i * (lw + 12)
		var card := UI.panel(self, Rect2(x, PANEL_Y + LOADOUT_Y, lw, LOADOUT_H), UI.box(Pal.BG, 8, 1, Pal.CARD_LINE))
		var c := {"panel": card}
		c["name"] = UI.label(card, Rect2(12, 6, lw - 24, 26), "", "SemiBold", Pal.CELL_TEXT + 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["state"] = UI.label(card, Rect2(12, 6, lw - 24, 26), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
		c["what"] = UI.label(card, Rect2(12, 34, lw - 24, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
		c["more"] = UI.label(card, Rect2(12, 56, lw - 24, 22), "", "Regular", Pal.CELL_TEXT - 1, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
		var bw: float = (lw - 24 - 8) / 2.0
		c["wear"] = UI.button(card, Rect2(12, LOADOUT_H - 12 - 38, bw, 38), true)
		c["wear"].add_theme_font_size_override("font_size", Pal.CELL_TEXT)
		c["wear"].text = Words.LOADOUTS["wear"]
		c["wear"].pressed.connect(_wear_loadout.bind(i))
		c["save"] = UI.button(card, Rect2(12 + bw + 8, LOADOUT_H - 12 - 38, bw, 38), false)
		c["save"].add_theme_font_size_override("font_size", Pal.CELL_TEXT)
		c["save"].text = Words.LOADOUTS["save"]
		c["save"].pressed.connect(_save_loadout.bind(i))
		card.visible = false
		loadout_cards.append(c)


## For the tests: the panel's buttons, and the idle toggles (the same buttons, with nothing picked).
@warning_ignore("unused_private_class_variable")
var _buttons: Array:
	get:
		return _pick._buttons
@warning_ignore("unused_private_class_variable")
var _toggles: Array:
	get:
		return [_pick._buttons[0], _pick._buttons[1], _pick._buttons[2]]
@warning_ignore("unused_private_class_variable")
var _head:
	get:
		return _pick._heads[0]


## The body's slots, in order, for the tests.
func row_names() -> Array:
	return Data.SLOTS.duplicate()


static func rarity_tone(it: Dictionary) -> String:
	return Pal.item_tone(it)


# ------------------------------------------------------------------ showing

func show_state(s) -> void:
	sim = s
	_inv.binning = true                 # Select-many bins (13 Oct); always (28 Oct, Matt: sales only at the Fence)
	_inv.show_items(sim, sim.stash, sim.stash_used(), sim.stash_cap(), "Stash")
	_body.selected = selected.get("slot", "") if selected.get("kind", "") == "slot" else ""
	_body.show_state(sim)
	_show_strip()
	_containers.selected = selected["id"] if selected.get("kind", "") == "rig" else -1
	_containers.show_state(sim)
	if rules_panel.visible and _inv.many:
		rules_panel.visible = false          # Select-many works from the bar the panel covers (the review)
	rules_button.visible = not _inv.many and not rules_panel.visible
	var n_on: int = sim.loot_rules.filter(func(r): return bool(r.get("on", true))).size() if sim.loot_rules_on else 0
	var rw: String = Words.LOOT_RULES["button"] % n_on if n_on > 0 else Words.LOOT_RULES["button_none"]
	if rules_button.text != rw:
		rules_button.text = rw
		UI.style_button(rules_button, false, "warn" if n_on > 0 else "")
	# main.gd refreshes ten times a second; rebuilding the buttons that often
	# hides and shows them under the mouse, which drops presses. Redraw only
	# when what's shown has changed.
	var sig := _signature()
	if sig == _shown:
		return
	_shown = sig
	_show_panel()


## The runner strip: the face, the past and the level, HP and its bar, the damage, the armour, the pace and the pack.
func _show_strip() -> void:
	People.show(_face, sim.cls)
	UI.fit(_who, ["%s · level %d" % [sim.cls if sim.cls != "" else "No past yet", sim.level()], "Level %d" % sim.level()])
	UI.fit(_hp, ["%d / %d HP" % [sim.hp_shown(), sim.max_hp_shown()], "%d HP" % sim.hp_shown()])
	var frac: float = clampf(sim.hp / maxf(sim.max_hp(), 1.0), 0.0, 1.0)
	_hp_fill.size.x = roundf(_hp_track.size.x * frac)
	(_hp_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Pal.GOOD if frac > 0.5 else (Pal.WARN if frac > 0.25 else Pal.BAD)
	var total: float = float(sim.damage_split()["total"])     # the hits and the dots together (16 Oct, item 14)
	UI.fit(_dps, ["%.0f dmg/s" % total, "%.0f" % total])
	UI.fit(_armour, ["%s stopped" % Fmt.pct(sim.mitigation()), Fmt.pct(sim.mitigation())])
	UI.fit(_pace, ["pace ×%.2f" % sim.pace(), "×%.2f" % sim.pace()])
	UI.fit(_carry, ["%d cells · %d pouches" % [sim.capacity(), sim.med_capacity()], "%d cells" % sim.capacity()])


## Everything the screen's look depends on, as one string.
func _signature() -> String:
	var parts := [str(sim.loadouts.get(sim.cls, [])), str(sim.skill_slots), str(sim.rig.size()), str(selected), str(sim.runner_busy()), str(sim.stash.size()), str(_inv.many), str(sim.auto_equip), str(sim.junk_upto), sim.junk_keep, _bin_arm.sig() + _save_arm.sig(), str(sim.level()), str(sim.book.size())]     # the level: a padlock comes off (15 Oct)
	var sel := _selected_item()
	if not sel.is_empty():
		parts.append(str(sel["affixes"]) + str(sel.get("ilvl", 0)) + str(sel["attachments"].keys()))   # the Bench changes these in place
	for slot in Data.SLOTS:
		parts.append(str(sim.equipped[slot]["id"]) if sim.equipped[slot] != null else "-")
	for it in sim.rig:
		parts.append("r" + str(it["id"]))
	for it in sim.stash:
		parts.append(str(it["id"]))
	return "|".join(parts)


## The compare panel (Pick-A): the pick on the left, what's fitted in its slot
## on the right laid the same, the verdict and the deltas at the foot, the
## buttons for what can be done with it. Sell is the Fence's.
func _show_panel() -> void:
	var it := _selected_item()
	if it.is_empty():
		_pick.show_empty("Select an item", ["A slot on the left, or a stash item on the right"])     # the rules read on their buttons (18 Oct: said twice)
		_show_loadouts()
		# the idle toggles and the junk rules (11 Oct) live where the buttons would be
		_pick.set_buttons([
			{"text": "Equip if better ✓" if sim.auto_equip else "Equip if better", "action": _toggle.bind(0), "enabled": true, "primary": false, "tone": "good" if sim.auto_equip else ""},
			{"text": "Sell when home: " + SELL_WORDS[sim.junk_upto + 1], "action": _toggle.bind(1), "enabled": true, "primary": false, "tone": "good" if sim.junk_upto >= 0 else ""},
			{"text": "Keep: " + KEEP_WORDS[sim.junk_keep], "action": _toggle.bind(2), "enabled": sim.junk_upto >= 0, "primary": false, "tone": ""}])
		return
	for c in loadout_cards:
		c["panel"].visible = false
	var buttons := []
	var tail = ""
	var extra = ""
	if Items.is_gun(it):
		tail = [Items.fitted_words(it), _rounds_clause(it)]
	elif Items.is_attachment(it) and not Items.is_socketable(it):
		tail = Items.att_words(it, true, true)
	elif Items.is_ammo(it):
		tail = "feeds %s" % ("the " + Items.base_of(it)["type"] if Items.base_of(it)["type"] != "smg" else "the SMG")
	elif Items.is_paper(it):
		var taught: String = sim.word_taught_by(str(it["base"]))
		# read on pickup (10 Oct, Matt: "where do they actually need to be learned?"): once read, say the word is known
		var read: bool = it["base"] in sim.book
		if sim.story_of(it) >= 0:
			tail = [["Kev's story: three together make its signal", "Kev's story: three make its signal", "Kev's story"]]     # not "no code" (16 Oct: true of the code, wrong of the paper)
		elif not sim.room_open("radio") and not Items.is_deeds(it):
			tail = "encrypted till the Radio's open"     # every paper alike, code or none (16 Oct, Matt: one said "from before")
		else:
			tail = [[("no code: a line of the before" if taught == "" else (("read · the Radio has %s" % taught.to_lower()) if read else ("the code for %s" % taught.to_lower()))) if not Items.is_deeds(it) else "what the Bank was holding"]]     # one clause, one chip
	if it.has("set"):
		# the set: whose, how many worn, what the next piece brings
		var st: Dictionary = Items.set_named(it["set"])
		var n: int = sim.set_count(it["set"])
		var next_words := ""
		for k in st["bonuses"]:
			if int(k) > n and next_words == "":
				next_words = st["bonuses"][k]["words"]
		var iss: int = sim.set_issued(it["set"])
		var iss_words: String = (" (%d issued)" % iss) if iss > 0 else ""
		var line: String = "%s · %d of %d worn%s" % [it["set"], n, st["pieces"].size(), iss_words]     # issued kit counts as a set piece: says so (the third review), in every form
		extra = [("%s · next: %s" % [line, next_words.to_lower()]) if next_words != "" else "%s · the full set" % line, line, "%d of %d worn%s" % [n, st["pieces"].size(), iss_words]]
	var where: String = {"stash": "in the stash", "rig": "in the rig", "slot": "fitted"}.get(selected["kind"], "")
	_pick.show_pick(it, sim, "The pick · " + where, tail, extra)
	if Items.is_mag(it):
		buttons = _show_magazine(it)
	elif Items.is_ammo(it):
		# a box (30 Oct): it stays in the stash and fills the rig's magazines at the gate
		var feeds := []
		for g in [sim.equipped["Primary"], sim.equipped["Secondary"]]:
			if g != null and Items.ammo_type(g) == Items.base_of(it)["type"]:
				feeds.append(g["base"])
		var lines: Array = [("Feeds both guns" if feeds.size() == 2 else "Feeds the %s" % Words.mid_base(str(feeds[0]))) if not feeds.is_empty() else "Nothing fitted fires it",
			["A box: it fills the rig's magazines at the gate", "Fills the rig's magazines"]]
		_pick.show_right_words("The rig", "%d of %d pouches filled" % [sim.rig_used(), sim.med_capacity()], lines)
		if Items.stacks(it):
			buttons.append(_split_button(it))
	elif Items.rig_item(it):
		buttons = _show_medical(it)
	elif Items.is_paper(it):
		var pl: Array = sim.paper_lines(it)
		_pick.show_right_words(pl[0], pl[1], [pl[2]])
	elif Items.is_attachment(it):
		if Items.is_socketable(it):
			_pick.show_right_words("The Workshop", "Fitted in the Workshop", [["Sockets view: into any socket", "Into any socket"], Items.socket_words(it).get_slice(": ", 1)])
		else:
			_pick.show_right_words("The Workshop", "Fitted in the Workshop", ["Goes on %s" % Items.mount_words(it["mount"])])
		buttons.append({"text": "Workshop", "action": func(): bench.emit(it["id"]), "enabled": not sim.runner_busy() and sim.room_open("workshop"), "primary": true})     # every Bench from the start (9 Oct)
		if Items.stacks(it):
			buttons.append(_split_button(it))
	else:
		var fitted = sim.equipped[it["slot"]]
		var from_stash: bool = selected["kind"] == "stash"
		if from_stash:
			if fitted == null:
				_pick.show_right_words("Fitted now", "Nothing fitted as %s" % it["slot"].to_lower(), ["Nothing worn there: equipping adds all of it"])
			else:
				# parts or socketables on either (29 Oct, the Compare board's layout A): the three readings in the fitted's place
				var rows: Array = sim.compare_readings(it)
				if not rows.is_empty():
					_pick.show_readings(fitted, sim, rows, "dmg/s" if Data.SLOT_SCORE.get(str(it["slot"]), "") == "dps" else "")
				else:
					var ftail = ""
					if Items.is_gun(fitted):
						ftail = [Items.fitted_words(fitted), _rounds_clause(fitted)]
					_pick.show_fitted(fitted, sim, "Fitted now", ftail)
				var mv: bool = sim.swap_moves(it)     # the swap's what Equip does here only when something moves (the fix round)
				var v: Array = PickPanel.verdict_for(sim, it, mv)
				_pick.set_verdict(v[0], v[1], PickPanel.deltas_for(sim, it, fitted, mv))
			var lock: int = sim.wear_lock(it)
			var swap: bool = from_stash and fitted != null and sim.swap_moves(it)
			if swap:
				buttons.append({"text": "Swap, parts and all", "action": func(): sim.swap_with_parts(int(it["id"])), "enabled": sim.can_swap_with_parts(int(it["id"])) and lock <= 0, "primary": true})     # what the verdict read (29 Oct); lit only when it can happen (30 Oct, the review's U4)
			buttons.append({"text": "Equip at level %d" % lock if lock > 0 else "Equip", "action": sim.equip_item.bind(it["id"]), "enabled": sim.can_equip_item(it["id"]), "primary": not swap})
			# the foot's hint: over the runner's level (15 Oct); else no rounds for it (the try-on counts it fed, 11 Oct),
			# no room for what comes off, or both
			var hints: Array = []
			if Items.is_gun(it) and not sim.has_rounds(it):
				hints.append("No rounds for it in the rig")
			if sim.away():
				hints.append(Words.REPEAT["shut_away"])     # the kit's with the runner (29 Oct)
			elif (not sim.can_equip_item(it["id"]) or (swap and not sim.can_swap_with_parts(int(it["id"])))) and not sim.on_mission():
				hints.append("No room in the stash for what comes off")     # the parts too, for the swap (30 Oct, the review's U4)
			if lock > 0 and fitted == null:
				_pick.set_hint_options(PickPanel.lock_hints(sim, it))     # with a piece worn the verdict says the level: said once (the review)
			elif not hints.is_empty():
				_pick.set_hint_options(_hint_forms(hints))
			if not it.has("unique") and not it.has("set") and not swap:     # the swap's in its place (29 Oct): the foot keeps room for the item's line
				buttons.append({"text": "Workshop", "action": func(): bench.emit(it["id"]), "enabled": not sim.runner_busy() and sim.room_open("workshop"), "primary": false})
		else:
			# fitted: a gun's parts, each with its figures, at the right; the stash's room under
			var lines := []
			for mount in it.get("attachments", {}):
				var a = it["attachments"][mount]
				if a == null or lines.size() >= 3:
					continue
				var figures: String = Items.att_words(a, true) if not Items.is_socketable(a) else Items.socket_words(a).get_slice(": ", 1)
				lines.append(["%s · %s" % [a["base"], figures], a["base"]])
			lines.append("Stash has %d of %d cells" % [sim.stash_used(), sim.stash_cap()])
			_pick.show_right_words("On the runner", "Fitted" if lines.size() > 1 else "Fitted, nothing on it", lines)
			buttons.append({"text": "Unequip", "action": sim.unequip.bind(it["slot"]), "enabled": not sim.runner_busy() and sim.stash_fits(it), "primary": true})
			if not strip_note_forms(it["slot"]).is_empty():
				_pick.set_hint_options(strip_note_forms(it["slot"]))
			if sim.parts_on(it["slot"]) > 1:
				buttons.append({"text": "Strip all parts", "action": _strip_all_press.bind(it["slot"]), "enabled": sim.can_strip_any(it["slot"]), "primary": false})     # every part off at once (28 Oct, Matt); off with no room for one (the review)
			if not it.has("unique") and not it.has("set") and buttons.size() < PickPanel.BUTTONS:
				buttons.append({"text": "Workshop", "action": func(): bench.emit(it["id"]), "enabled": not sim.runner_busy() and sim.room_open("workshop"), "primary": false})
	# the bin (13 Oct, Matt's playtest): anything in the stash but the deeds, gone for nothing (27 Oct); a unique or a set piece asks twice
	if selected.get("kind", "") == "stash" and sim.can_bin(it) and buttons.size() < PickPanel.BUTTONS:
		var precious: bool = it.has("unique") or it.has("set")
		var armed: bool = _bin_arm.holds(int(it["id"]))
		buttons.append({"text": (Words.ASK["again"] % "Bin it") if armed else "Bin", "action": _bin_press.bind(int(it["id"]), precious), "enabled": true, "primary": false, "tone": "bad" if armed else ""})
	# the deeds held (27 Oct): burned at home, asked twice
	if selected.get("kind", "") == "stash" and Items.is_deeds(it) and buttons.size() < PickPanel.BUTTONS:
		var armed_d: bool = _bin_arm.holds(int(it["id"]))
		buttons.append({"text": (Words.ASK["again"] % "Burn the deeds") if armed_d else "Burn", "action": _burn_press.bind(int(it["id"])), "enabled": not sim.on_mission(), "primary": false, "tone": "bad" if armed_d else ""})
	_set_buttons(buttons)


func _burn_press(id: int) -> void:
	if not _bin_arm.press(id):
		_keep_pick = true
		return
	_bin_arm.clear()
	sim.burn_deeds(id)


## Strip all (28 Oct, the review: with partial room it took some off and said nothing on screen): what was left on, kept
## to say so while the piece and the stash stand as the press left them.
var _strip_note: Array = []            # [slot, parts left on, stash cells used]
func _strip_all_press(slot: String) -> void:
	var r: Array = sim.strip_all(slot)
	_strip_note = [slot, sim.parts_on(slot), sim.stash_used()] if int(r[1]) > 0 else []


## The hint's forms for a Strip all that left parts on, or [] (for the tests too).
func strip_note_forms(slot: String) -> Array:
	if _strip_note.size() != 3 or str(_strip_note[0]) != slot or int(_strip_note[1]) != sim.parts_on(slot) or int(_strip_note[2]) != sim.stash_used():
		return []
	var n: int = int(_strip_note[1])
	return ["%d left on: no room in the stash" % n, "%d left on: no room" % n, "No room for %d" % n]


var _bin_arm := Arm.new()               # a unique or set piece's first Bin press: the second bins it (a while, or out of the room, disarms)


func _bin_press(id: int, precious: bool) -> void:
	if precious and not _bin_arm.press(id):
		_keep_pick = true                   # still picked: the button now says what it'll do
		return
	_bin_arm.clear()
	sim.bin(id)


## The panel's buttons, each through _press so the selection follows the item after.
func _set_buttons(buttons: Array) -> void:
	var items := []
	for i in range(buttons.size()):
		_actions[i] = buttons[i]["action"]
		var d: Dictionary = buttons[i].duplicate()
		d["action"] = _press.bind(i)
		items.append(d)
	_pick.set_buttons(items)


## "takes SMG rounds, 600 in the rig", shorter forms after it.
func _rounds_clause(gun: Dictionary) -> Array:
	var takes: String = Items.ammo_words(gun).to_lower().replace("smg", "SMG")
	var n: int = sim.rounds_for(gun)
	if Items.ammo_type(gun) == "":
		return [takes]
	return ["%s, %d in the rig" % [takes, n], "%s, %d" % [takes, n], takes]


## A magazine (30 Oct, the approved canvas): against the one of its type in the rig when there is one - the compare's
## foot (rounds, pouches, reload) and Swap into the rig; else "THE RIG": each gun's magazines and rounds, the meds, the
## rounds left in the stash. Take into the rig, or Leave in the stash. Returns the buttons.
func _show_magazine(it: Dictionary) -> Array:
	var buttons := []
	var other: Dictionary = sim.mag_rig_match(it) if selected["kind"] != "rig" else {}
	if not other.is_empty():
		_pick.show_fitted(other, sim, "In the rig")
		var cmp: Array = sim.mag_compare(it, other)
		_pick.set_verdict(cmp[0][0], cmp[0][1], cmp[1])
		buttons.append({"text": "Swap into the rig", "action": sim.mag_swap.bind(int(it["id"]), int(other["id"])), "enabled": sim.can_mag_swap(int(it["id"]), int(other["id"])), "primary": true})
	else:
		var lines: Array = sim.rig_card_lines()
		_pick.show_right_words("The rig", "%d of %d pouches filled" % [sim.rig_used(), sim.med_capacity()], lines.slice(0, PickPanel.LINES))
	if selected["kind"] == "rig":
		buttons.append({"text": "Leave in the stash", "action": sim.leave.bind(it["id"]), "enabled": not sim.runner_busy() and sim.stash_fits(it), "primary": true})
	elif other.is_empty():
		buttons.append({"text": "Take", "action": sim.take.bind(it["id"]), "enabled": not sim.runner_busy() and sim.rig_room(Items.size(it)), "primary": true})     # the compare's foot is the swap alone (the canvas): its deltas want the room
	return buttons


## A med or rounds: the rig on the right; Take into it, or Leave it in the stash. Returns the buttons.
func _show_medical(it: Dictionary) -> Array:
	var lines: Array = ["Thrown at everyone on you" if Items.is_grenade(it) else "Used under fire, over a few seconds"]     # a med or a grenade: a box or a magazine has its own panel
	if Items.is_cure(it):
		lines[0] = [sim.med_words(it), Words.CURE_CLEARS[Items.cure_of(it)] + ", at once"]     # a cure (28 Oct): what it stops
	var buttons := []
	if selected["kind"] == "rig":
		buttons.append({"text": "Leave in the stash", "action": sim.leave.bind(it["id"]), "enabled": not sim.runner_busy() and (sim.stash_fits(it) or sim._stack_room(it)), "primary": true})
	else:
		var room: bool = sim.rig_room(Items.size(it))
		if not room:
			lines.append("No rig fitted" if sim.med_capacity() == 0 else ("The rig is full" if Items.size(it) == 1 else "No room: it takes %d pouches" % Items.size(it)))
		buttons.append({"text": "Take", "action": sim.take.bind(it["id"]), "enabled": not sim.runner_busy() and room, "primary": true})
	if Items.stacks(it):
		buttons.append(_split_button(it))
	_pick.show_right_words("The rig", "%d of %d pouches filled" % [sim.rig_used(), sim.med_capacity()], lines)
	return buttons


## Split: half a stack off into its own, beside it (12 Oct).
func _split_button(it: Dictionary) -> Dictionary:
	return {"text": "Split", "action": func(): _keep_pick = sim.split_stack(it["id"]), "enabled": sim.can_split(it["id"]), "primary": false}


## Leaving the room shuts the rules panel: back in, the stash shows (the review).
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		_bin_arm.clear()                     # and the bin's and a kit's save's arms go (the second review)
		_save_arm.clear()
		_shown = ""
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and rules_panel != null and rules_panel.visible:
		rules_panel.visible = false
		_shown = ""


## The three loadouts' cards: the name and its state, what it holds, what's gone, Wear and Save worn.
func _show_loadouts() -> void:
	for i in range(loadout_cards.size()):
		var c: Dictionary = loadout_cards[i]
		c["panel"].visible = not rules_panel.visible     # under the rules panel they'd only take its clicks
		var e: Dictionary = sim.loadout(i)
		var st: String = sim.loadout_state(i)
		c["name"].text = Words.LOADOUTS["name"] % (i + 1)
		var states := {"empty": "", "worn": Words.LOADOUTS["worn_now"], "ready": Words.LOADOUTS["ready"], "short": ""}
		c["state"].text = states[st]
		c["state"].add_theme_color_override("font_color", Pal.ACCENT if st == "worn" else (Pal.GOOD if st == "ready" else Pal.TEXT_3))
		(c["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = Pal.ACCENT if st == "worn" else Pal.CARD_LINE
		if e.is_empty():
			UI.fit(c["what"], [Words.LOADOUTS["empty"], "Empty"])
			c["more"].text = ""
		else:
			var guns: Array = []
			for slot in ["Primary", "Secondary"]:
				if e["names"].has(slot):
					guns.append(str(e["names"][slot]))
			var sk: int = e["skills"].filter(func(x): return str(x) != "").size()
			UI.fit(c["what"], [" · ".join(guns), guns[0] if not guns.is_empty() else ""] if not guns.is_empty() else [""])
			var gone: Array = sim.loadout_missing(i)
			c["more"].add_theme_color_override("font_color", Pal.BAD if not gone.is_empty() else Pal.TEXT_3)
			var rest: Array = [Words.LOADOUTS["skill"] if sk == 1 else Words.LOADOUTS["skills"] % sk, Words.LOADOUTS["rig"] % e["rig"].size()]
			UI.fit(c["more"], [Words.LOADOUTS["short"] % ", ".join(gone), Words.LOADOUTS["short"] % ("%d" % gone.size())] if not gone.is_empty() else [" · ".join(rest), rest[0]])
		c["wear"].disabled = st == "empty" or st == "worn" or sim.runner_busy()
		c["wear"].tooltip_text = Words.LOADOUTS["wear_tip"]
		c["save"].disabled = sim.runner_busy() or sim.cls == ""
		var armed: bool = _save_arm.holds(i) and st != "empty"
		if armed:
			UI.fit_button(c["save"], UI.ask_forms(Words.LOADOUTS["save_sure"]))
		else:
			c["save"].text = Words.LOADOUTS["save"]
		UI.style_button(c["save"], false, "bad" if armed else "")


func _wear_loadout(i: int) -> void:
	_save_arm.clear()
	if sim.loadout_wear(i):
		acted.emit()
	show_state(sim)


## Saving over a kit asks twice: it's the one press here that loses something (the language pass).
var _save_arm := Arm.new()


func _save_loadout(i: int) -> void:
	if sim.loadout_state(i) != "empty" and not _save_arm.press(i):
		_shown = ""
		show_state(sim)
		return
	_save_arm.clear()
	if sim.loadout_save(i):
		acted.emit()
	_shown = ""
	show_state(sim)


## The loot filter's panel: open over the stash and the pick, shut back to them.
func open_rules() -> void:
	rules_panel.picked = 0 if not sim.loot_rules.is_empty() else -1
	rules_panel.show_state(sim)
	rules_panel.visible = true
	move_child(rules_panel, -1)              # over the loadouts' cards too
	_shown = ""
	show_state(sim)


func close_rules() -> void:
	rules_panel.visible = false
	_shown = ""
	show_state(sim)


## The junk rules' buttons: the rarity the Fence takes up to (off, then each rarity to Rare), and the kind kept.
const SELL_WORDS := ["off", "commons", "up to Uncommon", "up to Rare"]
const KEEP_WORDS := {"": "upgrades", "guns": "upgrades and guns", "body": "upgrades and body kit", "bags": "upgrades and bags", "parts": "upgrades and parts"}


## The rules in a line: what goes to the Fence when a run comes home.
static func junk_words(s) -> String:
	if s.junk_upto < 0:
		return "nothing's sold" + (", the best goes on" if s.auto_equip else "")
	var what: String = ["commons", "commons and uncommons", "everything to rare"][s.junk_upto]
	var keep: String = "" if s.junk_keep == "" else ", nor any %s" % ("body kit" if s.junk_keep == "body" else s.junk_keep)
	return "the Fence takes %s, never an upgrade%s" % [what, keep]


func _toggle(i: int) -> void:
	if i == 0:
		sim.auto_equip = not sim.auto_equip
	elif i == 1:
		sim.junk_upto = sim.junk_upto + 1 if sim.junk_upto < SELL_WORDS.size() - 2 else -1
	else:
		var keys: Array = sim.JUNK_KEEPS.keys()
		sim.junk_keep = keys[(keys.find(sim.junk_keep) + 1) % keys.size()]
	acted.emit()
	show_state(sim)


func _selected_item() -> Dictionary:
	if selected.is_empty() or sim == null:
		return {}
	if selected["kind"] == "slot":
		var it = sim.equipped[selected["slot"]]
		return it if it != null else {}
	if selected["kind"] == "rig":
		for it in sim.rig:
			if it["id"] == selected["id"]:
				return it
		return {}
	for it in sim.stash:
		if it["id"] == selected["id"]:
			return it
	return {}


# ------------------------------------------------------------------ acting

func _pick_slot(slot: String) -> void:
	selected = {"kind": "slot", "slot": slot}
	show_state(sim)


## A rig slot pressed.
func _on_rig_pick(id: int) -> void:
	selected = {"kind": "rig", "id": id}
	_inv.selected = -1
	show_state(sim)


## Drops: a stash item onto the rig takes it; a rig slot onto the stash leaves it.
func _on_take(id: int) -> void:
	if sim.take(id):
		selected = {"kind": "rig", "id": id}
	acted.emit()


func _on_leave(id: int) -> void:
	if sim.leave(id):
		selected = {"kind": "stash", "id": id}
	acted.emit()


func _on_stash_drop(data: Dictionary) -> void:
	if data.get("src", "") == "rig":
		_on_leave(int(data["id"]))
	elif data.get("src", "") == "body":
		var slot: String = data.get("slot", "")
		if sim.unequip(slot):
			selected = {"kind": "stash", "id": int(data["id"])}
		acted.emit()


## A stash item dropped on its slot's box.
func _on_equip_drop(id: int) -> void:
	for it in sim.stash:
		if it["id"] == id and sim.equip_item(id):
			selected = {"kind": "slot", "slot": it["slot"]}
			break
	acted.emit()


## The grid's pick: an id, or -1 when its bars changed or Select-many toggled.
func _on_inv_pick(id: int) -> void:
	_bin_arm.clear()                          # a new pick: a unique's bin asks twice again (the review)
	if id >= 0:
		selected = {"kind": "stash", "id": id}
	elif _inv.many or (selected.get("kind", "") == "stash" and _selected_item().is_empty()):
		selected = {}
	show_state(sim)


func _on_inv_acted() -> void:
	if _selected_item().is_empty():
		selected = {}
	acted.emit()


## For the tests: the k-th cell on the grid's page.
func _pick_cell(k: int) -> void:
	_inv._pick(k)


var _keep_pick := false                 # the pressed action leaves the pick where it is (a split)


func _press(i: int) -> void:
	var it := _selected_item()
	var was: Dictionary = selected.duplicate()
	_keep_pick = false
	if _actions[i].is_valid():
		_actions[i].call()
	if _keep_pick:
		selected = was                       # a split leaves the stack where it was, still picked
		acted.emit()
		return
	# follow the item: equipped, it's now in its slot; unequipped, it's in the
	# stash under its id; sold, it's gone
	if was.get("kind", "") == "stash" and not it.is_empty() and Items.rig_item(it):
		selected = {}
		for k in range(sim.rig.size()):
			if sim.rig[k]["id"] == it["id"]:
				selected = {"kind": "rig", "id": it["id"]}
	elif was.get("kind", "") == "rig" and not it.is_empty():
		selected = {"kind": "stash", "id": it["id"]}
		if _selected_item().is_empty():
			selected = {}
	elif was.get("kind", "") == "stash" and not it.is_empty() and sim.equipped.has(it["slot"]) \
			and sim.equipped[it["slot"]] != null and sim.equipped[it["slot"]]["id"] == it["id"]:
		selected = {"kind": "slot", "slot": it["slot"]}
	elif was.get("kind", "") == "slot" and not it.is_empty():
		if sim.equipped.get(it["slot"], null) != null and sim.equipped[it["slot"]]["id"] == it["id"]:
			selected = was                   # still fitted (the Bench, say): the slot stays picked
		else:
			selected = {"kind": "stash", "id": it["id"]}
			if _selected_item().is_empty():
				selected = {}
	elif _selected_item().is_empty():
		selected = {}
	acted.emit()


## For the tests: every label with text.
func line_pairs() -> Array:
	return _pick.line_pairs()


func text_nodes() -> Array:
	var out: Array = _pick.text_nodes()
	out.append_array(_containers.text_nodes())
	out.append_array(_body.text_nodes())
	out.append_array([_who, _hp, _dps, _armour, _pace, _carry])
	out.append_array(_inv.text_nodes())
	return out



## The foot's hints in forms long to short: alone, no rounds says why it matters; together, both on one line; then
## each cut to its first words.
static func _hint_forms(hints: Array) -> Array:
	var out: Array = []
	if hints.size() == 1 and str(hints[0]).begins_with("No rounds"):
		out.append(str(hints[0]) + ": it won't fire until it has some")
	out.append(" · ".join(hints))
	out.append(" · ".join(hints.map(func(h): return str(h).get_slice(" (", 0).replace(" for what comes off", "").replace(" for it in the rig", ""))))
	return out

extends Node
## Sound (13 Oct, docs/design/sound.md: the ElevenLabs pass). Everything follows the sim: the shell's refresh hands it
## the state and it works out what's happened since the last look - a shot at the gun's rate, a kill, a hit on you, a
## gang arriving, a crate opened, a find on the floor, a level, a building - and what should be under it all: the
## zone's place, the weather, the heartbeat, the watch, and the music (title, camp, fight, search).
##
## Files: art/sound_new/<id>.mp3, and its takes <id>_1, <id>_2, ... (one picked at random each time); where a sound has
## none yet, the old art/sound/<name>.wav it replaces, else nothing. Imported if the editor's seen them (an export
## carries those), else read straight off the disk. Nothing here changes the sim.

const Items := preload("res://scripts/sim/items.gd")
const Data := preload("res://scripts/sim/data.gd")

const NEW_DIR := "res://art/sound_new/%s.mp3"
const OLD_DIR := "res://art/sound/%s.wav"
const TAKES := 4                   # <id>_1 to <id>_4 looked for
const POOL := 10                   # one-shots that can play over each other
const FADE_S := 1.2                # a loop's crossfade
const MUSIC_XF := 2.5              # the music's own loop: the tail crossfades into the top (the files aren't seamless)

## Every sound the game asks for: its level, and the old placeholder it falls back to. The ids are the manifest's.
const SOUNDS := {
	# places and weather (loops)
	"amb_outskirts": {"db": -16.0, "old": "ambient_estate"}, "amb_estate": {"db": -16.0, "old": "ambient_estate"},
	"amb_town": {"db": -16.0, "old": "ambient_town"}, "amb_city": {"db": -16.0, "old": "ambient_city"},
	"amb_yard": {"db": -18.0}, "rain": {"db": -18.0, "old": "rain"}, "fog": {"db": -20.0}, "night": {"db": -20.0},
	# the fight
	"shot_improvised": {"db": -10.0, "old": "tick_improvised"}, "shot_pistol": {"db": -10.0, "old": "tick_pistol"},
	"shot_shotgun": {"db": -10.0, "old": "tick_shotgun"}, "shot_rifle": {"db": -10.0, "old": "tick_rifle"},
	"shot_smg": {"db": -11.0, "old": "tick_smg"}, "swing_melee": {"db": -9.0, "old": "tick_melee"},
	"swing_blade": {"db": -9.0, "old": "tick_melee"}, "incoming": {"db": -15.0}, "duck": {"db": -14.0},
	"dry_click": {"db": -8.0}, "reload": {"db": -10.0}, "hit_taken": {"db": -8.0}, "guard_break": {"db": -7.0},
	"kill": {"db": -9.0}, "gang_arrives": {"db": -6.0, "old": "sting"}, "head_door": {"db": -6.0, "old": "door"},
	"head_down": {"db": -5.0}, "burn": {"db": -11.0}, "bleed": {"db": -11.0}, "poison": {"db": -11.0},
	"shock": {"db": -11.0}, "frost": {"db": -11.0}, "grenade": {"db": -6.0}, "med_use": {"db": -9.0},
	"low_hp": {"db": -10.0}, "clock_warn": {"db": -12.0}, "way_out": {"db": -8.0}, "extract": {"db": -6.0},
	"death": {"db": -4.0},
	# the search
	"crate_cardboard": {"db": -8.0}, "crate_ammo_tin": {"db": -8.0}, "crate_jewellery": {"db": -8.0},
	"crate_toolbox": {"db": -8.0}, "crate_medicine": {"db": -8.0}, "crate_filing": {"db": -8.0},
	"crate_safe": {"db": -8.0}, "crate_military": {"db": -8.0}, "crate_locked": {"db": -8.0}, "crate_keys": {"db": -8.0},
	"search_tick": {"db": -14.0}, "picked_clean": {"db": -8.0}, "find_common": {"db": -12.0},
	"find_rare": {"db": -7.0, "old": "found"}, "find_unique": {"db": -4.0, "old": "found"}, "take": {"db": -10.0},
	"ditch": {"db": -10.0}, "no_room": {"db": -10.0}, "dog_sniff": {"db": -10.0},
	# the camp and the UI
	"ui_click": {"db": -16.0}, "ui_tab": {"db": -15.0}, "equip": {"db": -10.0}, "sell": {"db": -9.0}, "buy": {"db": -9.0},
	"craft": {"db": -8.0}, "build": {"db": -8.0}, "level_up": {"db": -6.0}, "point_spent": {"db": -10.0},
	"heal_clinic": {"db": -8.0}, "radio_on": {"db": -10.0}, "radio_code": {"db": -10.0}, "gate_open": {"db": -6.0},
	"the_end_burn": {"db": -6.0}, "the_end_sell": {"db": -6.0},
	# music (loops by crossfade)
	"music_title": {"db": -12.0}, "music_camp": {"db": -15.0}, "music_fight": {"db": -14.0}, "music_search": {"db": -15.0},
}
## What the sim's chronicle says happened, as a sound (the camp's moments).
const CHRON := {"equip": "equip", "level": "level_up", "train": "point_spent", "heal": "heal_clinic", "treat": "heal_clinic",
	"craft": "craft", "build": "build", "yard_rank": "build", "gamble": "buy", "open": "gate_open", "boss": "head_down",
	"word": "radio_code", "bin": "ditch", "contract": "sell"}
## The crates' keys to their sound.
const CRATE_SOUND := {"cardboard": "crate_cardboard", "ammo_tin": "crate_ammo_tin", "jewellery": "crate_jewellery",
	"toolbox": "crate_toolbox", "medicine": "crate_medicine", "filing": "crate_filing", "safe": "crate_safe", "military": "crate_military"}

var enabled := true                # the pause menu's Sound: the world and the UI
var music_on := true               # the pause menu's Music
var on_title := false              # the title's up: its music
var _streams := {}                 # path -> stream or null
var _takes := {}                   # id -> [streams]
var _pool: Array = []              # AudioStreamPlayers for one-shots
var _loops := {}                   # layer -> {"p": [two players], "on": 0 or 1, "id": what's meant to play, "db": its level}
var _last := ""                    # the last one-shot asked for (the tests)
var _cued: Array = []              # every one-shot asked for since the tests last cleared it
var _tick_at := 0.0                # the run's clock when the gun last went off
var _incoming_at := 0.0            # and when theirs last did
var _hit_at := -10.0
var _el_at := {}                   # element -> when its sound last played
var _run_seen := -1
var _seen := {}                    # what the last look saw of the run
var _chron_seen := -1
var _cash_seen := -1.0
var _buttons_hooked := false
var _ending_seen := ""              # the deeds' fate last heard: burned or sold sound once, as it happens (14 Oct)
var _dry_seen := false             # the gun was dry at the last look: rounds again is a reload
var _sim_seen = null               # the camp the counts are of: a load or a new camp starts them again


func _init() -> void:
	for k in range(POOL):
		_pool.append(_player())
	for layer in ["amb", "weather", "low_hp", "clock", "music"]:
		_loops[layer] = {"p": [_player(), _player()], "on": 0, "id": "", "db": -80.0}


func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p


func _ready() -> void:
	get_tree().node_added.connect(_hook_button)


# ------------------------------------------------------------------ the files

## A stream by path, imported or straight off the disk; cached, null when there's none.
func _load(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	elif FileAccess.file_exists(path):
		var bytes := FileAccess.get_file_as_bytes(path)
		if path.ends_with(".mp3"):
			var mp := AudioStreamMP3.new()
			mp.data = bytes
			s = mp if mp.get_length() > 0.0 else null
		else:
			s = _parse(bytes)
	_streams[path] = s
	return s


## The old placeholder by name (the tests, and the fallback).
func stream(nm: String) -> AudioStream:
	return _load(OLD_DIR % nm)


## A sound's takes: <id> and <id>_1.. from the new files, else the old placeholder it replaces, else none.
func takes(id: String) -> Array:
	if _takes.has(id):
		return _takes[id]
	var out: Array = []
	for nm in [id] + range(1, TAKES + 1).map(func(n): return "%s_%d" % [id, n]):
		var s := _load(NEW_DIR % nm)
		if s != null:
			out.append(s)
	if out.is_empty() and SOUNDS.get(id, {}).has("old"):
		var o := stream(str(SOUNDS[id]["old"]))
		if o != null:
			out.append(o)
	_takes[id] = out
	return out


## Whether a sound has anything to play, new or old.
func has_sound(id: String) -> bool:
	return not takes(id).is_empty()


static func _parse(b: PackedByteArray) -> AudioStreamWAV:
	if b.size() < 44 or b.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	var pos := 12
	var channels := 1
	var rate := 44100
	var bits := 16
	var data := PackedByteArray()
	while pos + 8 <= b.size():
		var id := b.slice(pos, pos + 4).get_string_from_ascii()
		var size := b.decode_u32(pos + 4)
		if id == "fmt ":
			channels = b.decode_u16(pos + 10)
			rate = b.decode_u32(pos + 12)
			bits = b.decode_u16(pos + 22)
		elif id == "data":
			data = b.slice(pos + 8, pos + 8 + size)
		pos += 8 + size + (size % 2)
	if bits != 16 or data.is_empty():
		return null
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = channels == 2
	s.data = data
	return s


## A copy that loops end to end (the places, the heartbeat, the watch - made seamless by the generator).
static func _looped(s: AudioStream) -> AudioStream:
	if s == null:
		return null
	var c: AudioStream = s.duplicate()
	if c is AudioStreamMP3:
		c.loop = true
	elif c is AudioStreamWAV:
		c.loop_mode = AudioStreamWAV.LOOP_FORWARD
		c.loop_begin = 0
		c.loop_end = c.data.size() / (4 if c.stereo else 2)
	elif c is AudioStreamOggVorbis:
		c.loop = true
	return c


# ------------------------------------------------------------------ playing

## A one-shot: a take at random, a touch of pitch, on a free player (the oldest if none is).
func cue(id: String, pitch_var := 0.04) -> void:
	_last = id
	_cued.append(id)
	if not enabled:
		return
	var ts := takes(id)
	if ts.is_empty():
		return
	var p: AudioStreamPlayer = null
	for q in _pool:
		if not q.playing:
			p = q
			break
	if p == null:
		p = _pool.pop_front()
		_pool.append(p)
	p.stream = ts[randi() % ts.size()]
	p.volume_db = float(SOUNDS.get(id, {}).get("db", -10.0))
	p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	if p.is_inside_tree():
		p.play()


## What a loop layer should be playing ("" for nothing): a change crossfades.
func set_loop(layer: String, id: String) -> void:
	var L: Dictionary = _loops[layer]
	if L["id"] == id:
		return
	L["id"] = id
	var old: AudioStreamPlayer = L["p"][L["on"]]
	old.set_meta("fade_to", -80.0)
	if id == "":
		return
	var ts := takes(id)
	if ts.is_empty():
		return
	L["on"] = 1 - int(L["on"])
	var p: AudioStreamPlayer = L["p"][L["on"]]
	p.stream = ts[0] if layer == "music" else _looped(ts[0])
	p.volume_db = -60.0
	L["db"] = float(SOUNDS.get(id, {}).get("db", -12.0))
	p.set_meta("fade_to", L["db"])
	if p.is_inside_tree():
		p.play()


func _process(dt: float) -> void:
	for layer in _loops:
		var L: Dictionary = _loops[layer]
		for p in L["p"]:
			if p.has_meta("fade_to"):
				var to: float = p.get_meta("fade_to")
				p.volume_db = move_toward(p.volume_db, to, dt * 60.0 / FADE_S)
				if to <= -80.0 and p.volume_db <= -59.0 and p.playing:
					p.stop()
		# the music's loop: near the end, the top comes in over the tail
		if layer == "music" and L["id"] != "":
			var cur: AudioStreamPlayer = L["p"][L["on"]]
			if cur.playing and cur.stream != null and cur.get_playback_position() > cur.stream.get_length() - MUSIC_XF:
				var id: String = L["id"]
				L["id"] = ""
				set_loop("music", id)


# ------------------------------------------------------------------ following the sim

## Called with the shell's refresh: everything follows the sim's state.
func follow(sim) -> void:
	on_title = false
	if not _buttons_hooked and get_parent() != null:
		_buttons_hooked = true
		_hook_all(get_parent())                # the shell's buttons as they are; new ones as they're added (_ready)
	if sim == null:
		_quiet_world()
		return
	_music(sim)
	if not enabled:
		_quiet_world()
		return
	_camp(sim)
	var m = sim.mission
	if m == null or m.get("dry", false):
		set_loop("amb", "amb_yard")
		for layer in ["weather", "low_hp", "clock"]:
			set_loop(layer, "")
		_run_seen = -1
		return
	_place(sim, m)
	if sim.runs_total != _run_seen:
		_run_seen = sim.runs_total
		_seen = _look(sim, m)
		_tick_at = sim.elapsed
		_incoming_at = sim.elapsed
		_hit_at = -10.0
		_el_at = {}
		_dry_seen = _dry(sim)
		var g0 = sim.equipped["Primary"]
		if g0 != null and Items.ammo_type(g0) not in ["", "none"] and not _dry_seen:
			cue("reload")                        # out with a loaded gun (14 Oct: the reload made, never played)
		return
	var now: Dictionary = _look(sim, m)
	_fight(sim, m, now)
	_search(sim, m, now)
	_seen = now


## The music for where the game is: the title, the camp, a fight (a head's too), the search.
func _music(sim) -> void:
	if not music_on:
		set_loop("music", "")
		return
	var want := "music_camp"
	var m = sim.mission if sim != null else null
	if m != null and not m.get("dry", false):
		var boss_on: bool = m.has("boss") and m["boss"]["started"] and m["boss"]["alive"]
		want = "music_fight" if int(m["remaining"]) > 0 or boss_on else "music_search"
	set_loop("music", want)


## The title's up (main.show_title): its music, the world quiet.
func title() -> void:
	on_title = true
	_takes.clear()                         # files the batch made since the last look are picked up here
	_streams.clear()
	_quiet_world()
	set_loop("music", "music_title" if music_on else "")


## The zone's place, the weather over it, the heartbeat low, the watch at the end.
func _place(sim, m: Dictionary) -> void:
	var zone: int = int(Data.TIERS[int(m["tier"])]["zone"])
	set_loop("amb", ["amb_outskirts", "amb_estate", "amb_town", "amb_city"][mini(zone, 3)])
	var w: String = sim.weather_of(int(m["tier"]))
	set_loop("weather", "rain" if w == "Rain" else ("fog" if w == "Fog" else ("night" if sim.is_night() else "")))
	set_loop("low_hp", "low_hp" if sim.hp < sim.max_hp() * 0.25 else "")
	var clock: float = float(m.get("clock", 999.0))
	set_loop("clock", "clock_warn" if clock > 0.0 and clock <= 10.0 else "")


## What a look at the run sees, to compare with the next.
func _look(sim, m: Dictionary) -> Dictionary:
	var boss: Dictionary = m.get("boss", {})
	var them := []
	for ty in ["fire", "poison", "bleed"]:
		if float(m.get("dots", {}).get(ty, 0.0)) > 0.5:
			them.append(ty)
	if float(m.get("chill_t", 0.0)) > 0.0:
		them.append("frost")
	if float(m.get("shock_t", 0.0)) > 0.0:
		them.append("shock")
	var cs: Array = m.get("crates", [])
	return {"kills": int(m["kills"]), "patrols": int(m.get("patrols", 0)), "hp": sim.hp, "guard": sim.guard(),
		"boss_on": bool(boss.get("started", false)), "boss_alive": bool(boss.get("alive", true)),
		"meds": int(m.get("meds_used", 0)), "way_out": bool(m.get("way_out", false)), "them": them,
		"searches": int(m.get("searches", 0)), "crate_i": int(m.get("crate_i", 0)), "crates": cs.size(),
		"passed": cs.filter(func(c): return c.get("passed", false)).size(), "done": sim.crates_done(m) if m.has("crates") else false,
		"floor": m.get("floor", []).map(func(it): return it["id"]), "ditched": m.get("floor", []).filter(func(it): return it.has("ditch_scrap")).map(func(it): return it["id"]),
		"found": m["found"].map(func(it): return it["id"]), "thrown": int(m.get("thrown", 0))}


## Whether the gun in hand takes rounds and has none.
func _dry(sim) -> bool:
	var gun = sim.equipped["Primary"]
	return gun != null and Items.ammo_type(gun) not in ["", "none"] and sim.rounds_for(gun) <= 0


func _fight(sim, m: Dictionary, now: Dictionary) -> void:
	var t: float = sim.elapsed                 # the camp's clock: always running while the run is
	if t < _tick_at or t < _incoming_at or t < _hit_at:     # the clock went back (a load): the stamps with it
		_tick_at = t - 10.0
		_incoming_at = t - 10.0
		_hit_at = t - 10.0
		_el_at = {}
	for ty in _el_at.keys():
		if float(_el_at[ty]) > t:
			_el_at.erase(ty)
	var fighting: bool = int(m["remaining"]) > 0
	# your gun at its rate (capped so it reads as shots, not a buzz); dry, the click
	var gun = sim.equipped["Primary"]
	if fighting and gun != null:
		var rof: float = maxf(0.3, minf(4.0, float(Items.base_of(gun).get("rof", 1.0)) * sim.pace()))
		if t - _tick_at >= 1.0 / rof:
			_tick_at = t
			cue("dry_click" if _dry(sim) else _gun_sound(gun))
	# dry, then rounds again: a reload (14 Oct)
	var dry_now: bool = _dry(sim)
	if _dry_seen and not dry_now and gun != null and Items.ammo_type(gun) not in ["", "none"]:
		cue("reload")
	_dry_seen = dry_now
	if now["thrown"] > int(_seen.get("thrown", 0)):
		cue("grenade")
	# theirs at you, now and then
	if fighting and t - _incoming_at >= randf_range(1.2, 2.6):
		_incoming_at = t
		cue("incoming", 0.08)
	if now["patrols"] > _seen["patrols"]:
		cue("gang_arrives")
	if now["boss_on"] and not _seen["boss_on"]:
		cue("head_door")
	if now["kills"] > _seen["kills"]:
		cue("kill")
	if now["hp"] < _seen["hp"] - sim.max_hp() * 0.04 and t - _hit_at > 0.4:
		_hit_at = t
		cue("hit_taken")
	if _seen["guard"] >= 1.0 and now["guard"] < 1.0:
		cue("guard_break")
	if now["meds"] > _seen["meds"]:
		cue("med_use")
	if now["way_out"] and not _seen["way_out"]:
		cue("way_out")
	for ty in now["them"]:
		if not (ty in _seen["them"]) and t - float(_el_at.get(ty, -10.0)) >= 2.0:     # not again for a pool flickering at the line
			_el_at[ty] = t
			cue({"fire": "burn", "poison": "poison", "bleed": "bleed", "frost": "frost", "shock": "shock"}[ty])


## The gun's sound: its type, a garage rifle by its rounds, a blade that bleeds by its edge.
func _gun_sound(gun: Dictionary) -> String:
	if Items.is_melee(gun):
		return "swing_blade" if float(Items.base_of(gun).get("conv_bleed_pct", 0)) >= 25.0 else "swing_melee"
	var kind: String = str(Items.base_of(gun).get("type", "improvised"))
	if kind == "improvised" and Items.ammo_type(gun) not in ["", "improvised", "none"]:
		kind = Items.ammo_type(gun)
	return "shot_" + kind if SOUNDS.has("shot_" + kind) else "shot_improvised"


func _search(sim, m: Dictionary, now: Dictionary) -> void:
	var cs: Array = m.get("crates", [])
	# the crates rolled at the clear, the Kennel's dog at them (14 Oct)
	if now["crates"] > 0 and int(_seen.get("crates", 0)) == 0 and sim.dog_sniffs():
		cue("dog_sniff")
	if now["passed"] > _seen["passed"]:
		cue("crate_locked")
	# a crate taken in hand: its own sound, and the keys first if it was locked
	if now["crates"] > 0 and (now["crate_i"] != _seen["crate_i"] or now["crates"] != _seen["crates"]) and now["crate_i"] < cs.size() and int(m["remaining"]) <= 0:
		var c: Dictionary = cs[now["crate_i"]]
		if c.get("locked", false):
			cue("crate_keys")
		cue(CRATE_SOUND.get(str(c["key"]), "crate_cardboard"))
	if now["searches"] > _seen["searches"]:
		cue("search_tick", 0.08)
	if now["done"] and not _seen["done"]:
		cue("picked_clean")
	# the floor: what's come up, by its worth; taken into the pack; ditched onto it
	var floor_items: Array = m.get("floor", [])
	for it in floor_items:
		if not (it["id"] in _seen["floor"]) and not it.has("ditch_scrap"):
			cue("find_unique" if it.has("unique") or it.has("set") else ("find_rare" if int(it.get("rarity", 0)) >= 2 else "find_common"))
	for id in now["found"]:
		if id in _seen["floor"] and not (id in _seen["found"]):
			cue("take")
			break
	for id in now["ditched"]:
		if not (id in _seen["ditched"]):
			cue("ditch")
			break
	# a rare off a kill, straight into the pack
	for it in m["found"]:
		if not (it["id"] in _seen["found"]) and not (it["id"] in _seen["floor"]) and (int(it.get("rarity", 0)) >= 2 or it.has("unique") or it.has("set")):
			cue("find_unique" if it.has("unique") or it.has("set") else "find_rare")


## The camp's moments, from the chronicle: a level, a building, a gamble... a run home or a death. And the Fence's
## money: cash up at home with nothing else to say for it is a sale.
func _camp(sim) -> void:
	var count: int = int(sim.chron_count)
	if _chron_seen < 0 or count < _chron_seen or sim != _sim_seen:
		_sim_seen = sim
		_chron_seen = count
		_cash_seen = sim.cash
		_ending_seen = sim.ending
		return
	var said := false
	if count > _chron_seen:
		said = true                            # anything the chronicle says explains the cash (a Yard move resets it)
		var n: int = mini(count - _chron_seen, sim.chronicle.size())
		for e in sim.chronicle.slice(sim.chronicle.size() - n):
			var k: String = str(e.get("k", ""))
			if k == "run":
				cue("death" if str(e.get("outcome", "")) == "Dead" else "extract")
				said = true
			elif k == "deeds":
				said = true                        # found: the find's own sound says it; the fire is for burning them (14 Oct)
			elif k == "open" and str(e.get("room", "")) == "radio":
				cue("radio_on")                    # the set comes on: static to a carrier, for the Radio's door
				said = true
			elif CHRON.has(k):
				cue(CHRON[k])
				said = true
		_chron_seen = count
	# the deeds' fate, as it's decided: burned, the fire; sold, a door shut quietly (14 Oct: the sale made, never played)
	if sim.ending != _ending_seen:
		if sim.ending == "burned":
			cue("the_end_burn")
			said = true
		elif sim.ending == "sold":
			cue("the_end_sell")
			said = true
		_ending_seen = sim.ending
	if sim.mission == null and not said and sim.cash > _cash_seen + 0.5:
		cue("sell")
	_cash_seen = sim.cash


func _quiet_world() -> void:
	for layer in ["amb", "weather", "low_hp", "clock"]:
		set_loop(layer, "")
	_run_seen = -1


## Every button's press clicks (the UI's own sound); the rail's rooms turn a page.
func _hook_all(n: Node) -> void:
	_hook_button(n)
	for c in n.get_children():
		_hook_all(c)


func _hook_button(n: Node) -> void:
	if n is BaseButton and not n.has_meta("sound_hooked"):
		n.set_meta("sound_hooked", true)
		var id: String = "ui_tab" if n.get_script() != null and str(n.get_script().resource_path).ends_with("rail_button.gd") else "ui_click"
		n.pressed.connect(func(): cue(id, 0.06))


func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		_quiet_world()
		for p in _pool:
			p.stop()


func set_music(on: bool) -> void:
	music_on = on
	if not on:
		set_loop("music", "")


## For the tests: what each layer means to play, the last one-shot.
func playing() -> Dictionary:
	return {"ambient": _loops["amb"]["id"], "weather": _loops["weather"]["id"], "rain": _loops["weather"]["id"] == "rain",
		"music": _loops["music"]["id"], "low_hp": _loops["low_hp"]["id"], "clock": _loops["clock"]["id"], "last": _last}


func cued() -> Array:
	return _cued


func clear_cued() -> void:
	_cued = []

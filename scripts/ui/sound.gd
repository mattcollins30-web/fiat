extends Node
## Sound: ambient by zone while the runner's out (rain over it when it
## rains), the gun's tick while the fight's on, a sting when a gang comes, the
## boss's door when the head comes out, a note when a rare lands. Files are
## art/sound/<name>.wav (tools/make_sounds.py makes placeholders); whatever
## is missing plays nothing. Read straight from the file, so no import step.

const Items := preload("res://scripts/sim/items.gd")
const Data := preload("res://scripts/sim/data.gd")

const DIR := "res://art/sound/%s.wav"
const AMBIENT_DB := -14.0
const RAIN_DB := -18.0
const TICK_DB := -10.0
const STING_DB := -6.0

var enabled := true                # the pause menu's toggle
var _streams := {}                 # name -> AudioStreamWAV, or null when there's no file
var _ambient: AudioStreamPlayer
var _rain: AudioStreamPlayer
var _tick: AudioStreamPlayer
var _one: AudioStreamPlayer        # stings, the door, the note
var _ambient_name := ""            # what's meant to be playing (the player may not be live in a headless test)
var _rain_on := false
var _tick_at := 0.0                # the clock when the gun last ticked
var _patrols_seen := 0
var _boss_seen := false
var _run_seen := -1                # runs_total of the run the stings have seen
var _found_seen: Array = []


func _init() -> void:
	_ambient = _player()
	_rain = _player()
	_tick = _player()
	_one = _player()


func _player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p


## A wav read by hand: RIFF, 16-bit mono or stereo, any rate. Cached; null when missing.
func stream(name: String) -> AudioStreamWAV:
	if _streams.has(name):
		return _streams[name]
	var path := DIR % name
	var out: AudioStreamWAV = null
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var bytes := f.get_buffer(f.get_length())
		f.close()
		out = _parse(bytes)
	_streams[name] = out
	return out


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


## Loop a stream from the start to its end.
static func _looped(s: AudioStreamWAV) -> AudioStreamWAV:
	if s == null:
		return null
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = s.data.size() / (4 if s.stereo else 2)
	return s


## Called with the shell's refresh: everything follows the sim's state.
func follow(sim) -> void:
	if sim == null or not enabled:
		_stop_all()
		return
	var m = sim.mission
	if m == null or m.get("dry", false):
		_stop_all()
		_run_seen = -1
		return
	# the ambient: the zone's, and the rain over it
	var zone: int = int(Data.TIERS[int(m["tier"])]["zone"])
	var want: String = ["ambient_estate", "ambient_estate", "ambient_town", "ambient_city"][mini(zone, 3)]     # the Outskirts on the estate's for now (12 Oct)
	if _ambient_name != want:
		_ambient_name = want
		_ambient.stream = _looped(stream(want))
		_ambient.volume_db = AMBIENT_DB
		if _ambient.stream != null:
			_ambient.play()
	var raining: bool = sim.weather_of(int(m["tier"])) == "Rain"
	if raining and not _rain_on:
		_rain_on = true
		_rain.stream = _looped(stream("rain"))
		_rain.volume_db = RAIN_DB
		if _rain.stream != null:
			_rain.play()
	elif not raining and _rain_on:
		_rain_on = false
		_rain.stop()
	# a new run: the stings start fresh
	if sim.runs_total != _run_seen:
		_run_seen = sim.runs_total
		_patrols_seen = 0
		_boss_seen = false
		_found_seen = []
	# the gun's tick while the fight's on, at the gun's rate (capped so it reads as a sound, not a buzz)
	if m["remaining"] > 0 and sim.equipped["Primary"] != null:
		var gun: Dictionary = sim.equipped["Primary"]
		var kind: String = "melee" if Items.is_melee(gun) else str(Items.base_of(gun).get("type", "improvised"))
		if kind == "improvised" and Items.ammo_type(gun) != "" and Items.ammo_type(gun) != "improvised":
			kind = Items.ammo_type(gun)          # a garage rifle sounds like a rifle
		var rof: float = maxf(0.3, minf(4.0, float(Items.base_of(gun).get("rof", 1.0)) * sim.pace()))
		var now: float = sim.elapsed
		if now - _tick_at >= 1.0 / rof:
			_tick_at = now
			var s := stream("tick_" + kind)
			if s != null:
				_tick.stream = s
				_tick.volume_db = TICK_DB
				_tick.pitch_scale = randf_range(0.94, 1.06)
				_tick.play()
	# a gang arriving
	if int(m.get("patrols", 0)) > _patrols_seen:
		_patrols_seen = int(m["patrols"])
		_play_one("sting", STING_DB)
	# the boss's door
	if m.has("boss") and m["boss"]["started"] and not _boss_seen:
		_boss_seen = true
		_play_one("door", STING_DB)
	# a rare landing
	for it in m["found"]:
		if not (it["id"] in _found_seen):
			_found_seen.append(it["id"])
			if int(it["rarity"]) >= 2 or it.has("unique") or it.has("set"):
				_play_one("found", STING_DB)


func _play_one(name: String, db: float) -> void:
	var s := stream(name)
	if s == null:
		return
	_one.stream = s
	_one.volume_db = db
	_one.pitch_scale = 1.0
	_one.play()


func _stop_all() -> void:
	for p in [_ambient, _rain, _tick]:
		p.stop()
	_ambient_name = ""
	_rain_on = false


func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		_stop_all()
		if _one.playing:
			_one.stop()


## For the tests.
func playing() -> Dictionary:
	return {"ambient": _ambient_name, "rain": _rain_on, "last": _one.stream != null}

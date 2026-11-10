extends RefCounted
## The slice's run log (10 Nov, Matt: "is there anything in the slice that records this info for you to read? If not
## let's build it"): a line a run ended, a JSON object, in docs/balance/slice_runs.jsonl beside the watcher's files
## (the folder git ignores) - the run's figures against the game's own fight for that runner at that level, and the
## test settings in force. Read after a play; nothing reads it in the game, and nothing here touches the camp.
const SliceBridge := preload("res://slice/bridge.gd")
const T := preload("res://slice/tuning.gd")

const ROUND := 9                      # the slice's round the line was played on
const FILE := "slice_runs.jsonl"
const DIR := "docs/balance"

static var dir := ""                  # a check's folder for the file; "": the project's docs/balance (below)
static var off := false               # the smoke's runs write no lines (it sets this as it starts)


## One run as a line: when (the machine's own time), who, where, the settings, the run's figures, the game's, and you over the game's (cleared).
static func entry(world, outcome: String, stats: Dictionary, game: Dictionary) -> Dictionary:
	var ctx: Dictionary = world.ctx
	var shots: int = int(stats.get("shots", 0))
	var e := {
		"at": Time.get_datetime_string_from_system(), "round": ROUND, "outcome": outcome,
		"class": str(ctx.get("class_name", "")), "level": int(ctx.get("level", 0)), "fixture": bool(ctx.get("fixture", false)), "camp_level": int(ctx.get("camp_level", 0)),
		"site_level": int(game.get("level", 0)), "seed": int(ctx.get("seed", 0)), "hp_max": int(ctx.get("hp_max", 0)),
		"guns": (ctx.get("guns", []) as Array).map(func(g): return "%s (%s)" % [str(g.get("name", "")), str(g.get("kind", ""))]),
		"gang_hp_x": float(ctx.get("man_hp_x", T.MAN_HP_X)), "gang_damage_x": SliceBridge.their_x(ctx),
		"time_s": snappedf(float(stats.get("time_s", 0.0)), 0.1), "hp_lost": int(stats.get("damage_taken", 0)),
		"kills": int(stats.get("kills", 0)), "headshots": int(stats.get("headshots", 0)), "shots": shots,
		"hits": int(stats.get("hits", 0)), "sight_shots": int(stats.get("sight_shots", 0)), "loop": stats.has("gangs_beaten"), "gangs_beaten": int(stats.get("gangs_beaten", 0)), "crates_opened": int(stats.get("crates_opened", 0)), "prize": bool(stats.get("prize", false)), "accuracy": snappedf(float(stats.get("hits", 0)) / shots, 0.001) if shots > 0 else 0.0,
		"damage_done": int(stats.get("damage_done", 0)), "finds": (stats.get("haul", []) as Array).size(),
		"game_time_s": snappedf(float(game.get("time_s", 0.0)), 0.1), "game_hp_lost": int(round(float(game.get("hp_lost", 0.0)))),
	}
	var gang = world.gang
	if gang != null:
		e["gang_reached"] = int(gang.gang_i) + 1
		e["men_left"] = int(gang.alive)
		e["searches"] = int(gang.searches)
	var r = world.runner
	if r != null:
		e["hp_end"] = int(r.hp)
		e["last_legs_used"] = bool(r.last_legs_used)
	if outcome == "cleared" and float(game.get("time_s", 0.0)) > 0.0 and float(game.get("hp_lost", 0.0)) > 0.0:
		e["time_x"] = snappedf(float(stats.get("time_s", 0.0)) / float(game["time_s"]), 0.001)
		e["hp_lost_x"] = snappedf(float(stats.get("damage_taken", 0)) / float(game["hp_lost"]), 0.001)
	return e


## Where the file goes: a check's folder; else the project's docs/balance - the project run from its folder, or the
## game's .exe sat in it; else the game's own folder (user://). "" with the log off or in a headless run, no folder
## given: the smoke plays runs to their end and writes none of them.
static func path() -> String:
	if dir != "":
		return dir.path_join(FILE)
	if off or DisplayServer.get_name() == "headless":
		return ""
	var project := ProjectSettings.globalize_path("res://")
	if project != "" and DirAccess.dir_exists_absolute(project):
		DirAccess.make_dir_recursive_absolute(project.path_join(DIR))     # a fresh clone has no docs/balance yet
	return resolve([project, OS.get_executable_path().get_base_dir()])


## The first of `bases` with a docs/balance in it takes the file; none, the game's own folder.
static func resolve(bases: Array) -> String:
	for base in bases:
		if str(base) != "" and DirAccess.dir_exists_absolute(str(base).path_join(DIR)):
			return str(base).path_join(DIR).path_join(FILE)
	return "user://" + FILE


## The line added to the file's end. False when nothing was written.
static func write(e: Dictionary) -> bool:
	var p := path()
	if p == "":
		return false
	var f := FileAccess.open(p, FileAccess.READ_WRITE) if FileAccess.file_exists(p) else FileAccess.open(p, FileAccess.WRITE)
	if f == null:
		push_warning("the slice's run log could not be opened: %s" % p)
		return false
	f.seek_end()
	f.store_line(JSON.stringify(e))
	f.close()
	return true

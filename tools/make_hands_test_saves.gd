extends SceneTree
## The hands test saves (17 Oct, Matt: "a save file with the new items in a stash so i can load in and test each on
## the Parade"). Every gun base in the stash with its rounds, a camp with the Parade open - too many for one stash (91
## cells; 284 for the guns alone), so a save a kind: rifles, shotguns, SMGs, improvised, melee and pistols. Written to
## docs/test_saves/<kind>.save; copy one over a slot (%APPDATA%\Fiat\fiat_slot2.save or 3 for the exported
## build, %APPDATA%\Godot\app_userdata\Fiat for the editor's) and load it.
##   godot --headless --path . -s tools/make_hands_test_saves.gd

const Sim := preload("res://scripts/sim/sim.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const OUT := "res://docs/test_saves/"
const SAVE_VERSION := 3          # main.gd's


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var groups := {"rifles": [], "shotguns": [], "smgs": [], "improvised": [], "melee_and_pistols": []}
	for slot in ["Primary", "Secondary"]:
		for b in Data.BASES[slot]:
			var t: String = str(b["type"])
			var g: String = {"rifle": "rifles", "shotgun": "shotguns", "smg": "smgs", "improvised": "improvised", "melee": "melee_and_pistols", "pistol": "melee_and_pistols"}.get(t, "improvised")
			groups[g].append([slot, str(b["name"])])
	for g in groups:
		var sim = Sim.new()
		sim.start()
		sim.set_class("Drifter")
		sim.xp = Data.xp_for_level(6)
		# the Outskirts and the Streets cleared, the Gamekeeper down: the Parade open at depth 1
		for i in range(Data.OUTSKIRTS_SITES + 2):
			sim.best_depth[i] = 1
		sim.best_tier = Data.OUTSKIRTS_SITES + 1
		sim.bosses_beaten[0] = true
		if not ("clinic" in sim.unlocked):
			sim.unlocked.append("clinic")
		sim.cash = 5000.0
		sim.stash.clear()
		var types := {}
		var left: Array = []
		for pair in groups[g]:
			var it: Dictionary = sim._plain(pair[0], pair[1])
			if not sim.stash_put(it):
				left.append(pair[1])
				continue
			var at: String = Items.ammo_type(it)
			if not (at in ["", "none"]):
				types[at] = true
		for at in types:
			for a in Data.BASES[Data.AMMO]:
				if str(a["type"]) == at and int(a["tier"]) == 1:
					var box: Dictionary = sim._plain(Data.AMMO, str(a["name"]))
					Items.set_stack(box, Items.stack_cap(box))
					sim.stash_put(box)
					break
		var f := FileAccess.open(OUT + g + ".save", FileAccess.WRITE)
		f.store_string(JSON.stringify({"version": SAVE_VERSION, "saved": Time.get_unix_time_from_system(), "sim": sim.to_dict()}))
		f.close()
		print("%s: %d guns, %d cells of %d%s" % [g, groups[g].size() - left.size(), sim.stash_used(), sim.stash_cap(), (" - no room for " + ", ".join(left)) if not left.is_empty() else ""])
	quit()

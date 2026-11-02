extends SceneTree
## The fingerprint (15 Oct, the refactor's safety net, docs/status.md item 2): three bot builds played for a few
## simulated hours on fixed dice, every run's outcome, kills, loot, tins, XP and time, and each build's end state,
## hashed. A refactor that moves nothing leaves the hash as it was; anything that moves a number changes it.
##   godot --headless --path . -s tests/fingerprint.gd -- [hours] [out file] [live]
## `live` plays with fast_memo off, the shell's own path (1 Nov, BUILD43: the stat memo the game reads must hand back
## what a fresh read would, so its hash is the same before and after a speed-only change).
## Everything random the sim does goes through sim.rng, but for the arrays' shuffles (the global dice), so both are
## fixed: Sim.fixed_seed for the camp's dice (a new camp, a Yard's move), seed() for the shuffles.

const Sim := preload("res://scripts/sim/sim.gd")
const Bot := preload("res://tests/bot.gd")
const Items := preload("res://scripts/sim/items.gd")

## The fourth plays by hand (finds on the floor, left there) and goes through a save and a load every eighth run:
## the two paths the bot's own way never takes (the review, 15 Oct).
const BUILDS := [["Doorman", "physical", false], ["Drifter", "fire", false], ["Scrapper", "shock", false], ["Paramedic", "poison", true]]
const SEED := 20261015
var live := false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var hours: float = float(args[0]) if args.size() > 0 else 2.0
	var out: String = args[1] if args.size() > 1 else ""
	live = args.size() > 2 and args[2] == "live"
	var lines: Array = []
	for b in BUILDS:
		lines.append_array(_build(str(b[0]), str(b[1]), hours, bool(b[2])))
	var text := "\n".join(lines)
	var ids := RegEx.create_from_string("\"id\":\\d+,?")
	text = ids.sub(text, "", true)        # ids aren't play: how many a dry run hands out isn't the game's
	var h := text.sha256_text()
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(text + "\n" + h + "\n")
		f.close()
	print("FINGERPRINT%s %s %d lines, %.1f h a build" % [" live" if live else "", h, lines.size(), hours])
	quit()


func _build(cls: String, element: String, hours: float, by_hand: bool) -> Array:
	seed(SEED)
	Items._next_id = 1
	Sim.fixed_seed = SEED
	Sim._seed_n = 0
	var sim = Sim.new()
	sim.loot_by_hand = by_hand
	sim.start()
	sim.set_class(cls)
	sim.fast_memo = not live
	sim.odds_runs_max = 24
	var bot = Bot.new()
	bot.element = element
	bot.cls = cls
	var lines: Array = []
	var n := 0
	while sim.elapsed < hours * 3600.0:
		var t: int = bot.step(sim)
		if t >= 0:
			n += 1
			var r: Dictionary = sim.last_report
			lines.append("%s %d t%d %s k%d l%d left%d c%.2f x%.2f %.2f" % [cls, n, t, str(r.get("outcome", "")), int(r.get("kills", 0)), int(r.get("loot", 0)),
				int(r.get("left", 0)), float(r.get("cash", 0.0)), float(r.get("xp", 0.0)), sim.elapsed])
			bot.tidy(sim)
			if by_hand and n % 8 == 0:
				sim.load_dict(JSON.parse_string(JSON.stringify(sim.to_dict())))     # a save and a load, as a player's quit
	var worn: Array = []
	for s in sim.equipped:
		var it = sim.equipped[s]
		worn.append("%s=%s" % [s, JSON.stringify(it) if it != null else "-"])
	lines.append("END %s lv%d cash%.2f scrap%d notes%d stash%d tree%s best%s yard%s" % [cls, sim.level(), sim.cash, int(sim.scrap), int(sim.notes),
		sim.stash.size(), str(sim.tree), str(sim.best_depth), str(sim.yard_picks)])
	lines.append("WORN %s %s" % [cls, ";".join(worn)])
	return lines

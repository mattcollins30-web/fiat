extends SceneTree
## The live stat memo's check (1 Nov, BUILD43): the fingerprint's builds played with fast_memo off - the shell's own
## path - and Sim.memo_check on, so every memo hit is read fresh as well. Any hit that differs is a stat the memo kept
## past a change: printed by key, and the run fails. The hash at the end is the live fingerprint's.
##   godot --headless --path . -s tests/memo_check.gd -- [hours]

const Sim := preload("res://scripts/sim/sim.gd")
const Bot := preload("res://tests/bot.gd")
const Items := preload("res://scripts/sim/items.gd")
const BUILDS := [["Doorman", "physical", false], ["Drifter", "fire", false], ["Scrapper", "shock", false], ["Paramedic", "poison", true]]
const SEED := 20261015


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var hours: float = float(args[0]) if args.size() > 0 else 1.0
	Sim.memo_check = true
	var stale := 0
	for b in BUILDS:
		stale += _build(str(b[0]), str(b[1]), hours, bool(b[2]))
	print("MEMO CHECK %s: %d stale hits" % ["clean" if stale == 0 else "STALE", stale])
	quit(0 if stale == 0 else 1)


func _build(cls: String, element: String, hours: float, by_hand: bool) -> int:
	seed(SEED)
	Items._next_id = 1
	Sim.fixed_seed = SEED
	Sim._seed_n = 0
	var sim = Sim.new()
	sim.loot_by_hand = by_hand
	sim.start()
	sim.set_class(cls)
	sim.fast_memo = false
	sim.odds_runs_max = 24
	var bot = Bot.new()
	bot.element = element
	bot.cls = cls
	var n := 0
	while sim.elapsed < hours * 3600.0:
		var t: int = bot.step(sim)
		if t >= 0:
			n += 1
			bot.tidy(sim)
			if by_hand and n % 8 == 0:
				sim.load_dict(JSON.parse_string(JSON.stringify(sim.to_dict())))
	var by := {}
	for s in sim.memo_stale:
		var k: String = "%s %s" % [str(s[0]).get_slice("/", 0) + ("/" + str(s[0]).get_slice("/", 1) if str(s[0]).contains("/") else ""), "run" if s[4] else "camp"]
		by[k] = int(by.get(k, 0)) + 1
	print("MEMO %s: %d runs, %d stale %s" % [cls, n, sim.memo_stale.size(), str(by)])
	for s in sim.memo_stale.slice(0, 6):
		print("MEMO   ", str(s).left(300))
	return sim.memo_stale.size()

extends RefCounted
## Everything the game says that isn't a number: the people's lines, the
## sites' lines, the papers, the uniques' pasts, the deeds, and a line for
## every item. The voice is docs/design/narrative.md's: British, flat, dry;
## the money words everywhere; nobody explains the collapse; the worst
## things said shortest. Words only - no rules live here.


# ------------------------------------------------------------------ the story (12 Oct, docs/design/lore.md)

## The opening: a new camp's first lines in the log, before the Yard is set. Said once.
const OPENING := [
	"The money went on a Tuesday. The cards first, then the machines. By the Thursday nobody would take the notes.",
	"By the Friday the Fence was the only one still open, and he paid in tins. Nobody asked what money meant any more.",
	"The crews kept the notes anyway. Nobody knows what for.",
]

## The opening's scenes (14 Oct, docs/design/intro.md - Matt's script): the year, the scene's name, its lines in
## turn, its picture (art/intro/<art>.png). A line in `radio` is the loop's own, said in its colour. `voice`: Matt's
## reading of it (art/intro/voice/<voice>.mp3); `cues`: when in it each line starts, in seconds (read off the takes'
## word timings) - the lines come up as they're said.
const OPENING_SCENES := [
	{"year": "2028", "title": "Somewhere else", "art": "scene_1", "voice": "2028", "cues": [3.82, 7.34, 14.50], "lines": [
		"The wars were always somewhere else.",
		"Other people's wars. Their reasons, their profits, our money. We watched them on the news.",
		"We felt them at the till."]},
	{"year": "2029", "title": "The bills", "art": "scene_2", "voice": "2029", "cues": [3.74, 7.48, 13.80], "lines": [
		"Then the petrol went up, and up again.",
		"The heating went off in the flats. The boats kept coming; where they came from was worse.",
		"Bread doubled. The reservoirs didn't fill."]},
	{"year": "2031", "title": "The machines", "art": "scene_3", "voice": "2031", "cues": [3.92, 10.32, 16.52], "lines": [
		"They said the machines would do the work. For a while the money said so too.",
		"Fields of servers, drinking the rivers, burning the power we couldn't afford.",
		"The jobs went first. The money went after them."]},
	{"year": "2032", "title": "The money", "art": "scene_4", "voice": "2032", "cues": [3.40, 6.28, 13.26, 16.48], "lines": [
		"It didn't crash. It stopped.",
		"The cards stopped. The banks shut for a day, then a week. The pound was paper.",
		"Then the radio broadcasts:"],
		"radio": "This is a recorded message. Remain in your homes. Cash withdrawals are limited to fifty pounds a day."},
	{"year": "2033", "title": "Let it be done", "art": "scene_5", "voice": "2033", "cues": [4.04, 9.60, 16.00, 20.14], "lines": [
		"Nobody fired a shot. The lights just went out one town at a time.",
		"The council stopped coming. The lorries stopped coming. The police stopped coming.",
		"People kept to their own. The estate kept the estate.",
		"A new currency was promised. Its value is as stated. Let it be done."]},
	{"year": "Now", "title": "The Pitch", "art": "scene_6", "voice": "now", "cues": [2.52, 7.50, 13.46, 17.58, 20.80], "lines": [
		"You keep a camp. A few vans, a fire, a fence of pallets.",
		"You don't go out. Somebody does – whoever's willing, for a share of what comes back.",
		"Tins are money now. What's in a tin is worth something.",
		"Send them out. Bring back what you can.",
		"When a place is picked clean, or someone wants it more than you do, you move on."]},
]

## On the air (14 Oct, docs/design/on_the_air.md): the campaign's close, the endgame's door - the Quartermaster's set
## comes home and Kev, on it, says what's out there. The opening's player: a heading (a frequency, a name), Kev's lines on
## his takes' cues (art/intro/voice/air_N.mp3, read off them; he doesn't read the headings).
const AIR_SCENES := [
	{"year": "Channel 19", "title": "The set", "art": "air_1", "voice": "air_1", "cues": [0.0, 7.56], "lines": [
		"Kev here. Properly, this time. That's a military set you've got – it hears a long way.",
		"I've had two years listening from the other end. You'd better hear what I hear."]},
	{"year": "Long wave", "title": "Everywhere else", "art": "air_2", "voice": "air_2", "cues": [0.0, 8.84, 14.06], "lines": [
		"Swansea's gone quiet. Bristol's one big checkpoint. Nobody's answered from London since the spring.",
		"It isn't just the UK. Everywhere else has gone dark too.",
		"The only ones still moving are the army. Their lorries run every night, and nobody knows what's in them."]},
	{"year": "The codes", "title": "Deeper", "art": "air_3", "voice": "air_3", "cues": [0.0, 6.90, 12.70], "lines": [
		"Those papers you keep finding. The codes on them aren't codes – they're frequencies.",
		"Somebody wrote them down so the right people could listen. Tune one in and it tells you where to dig.",
		"The deeper you go, the more you'll hear. Go carefully. Somebody's always listening back."]},
]

## The rooms' first visits (14 Oct, docs/design/room_intros.md): who speaks (a portrait's slug, or "" for the
## narrator), the line under the name, their lines, three tiles naming the screen's parts, the take's name in
## art/intro/rooms/ and its cues (read off Matt's takes, 14 Oct; with no take the lines go on the clock). Keyed by the room's code key, which a save keeps.
const ROOM_INTROS := {
	"map": {"room": "The Map", "face": "", "title": "Where the runner goes", "voice": "map", "cues": [0.0, 5.64], "lines": [
		"The town, from the ring road in. Every site on it was somebody's once.",
		"Pick one. Send the runner. They come back with what they carry, or they don't."],
		"tiles": [["Sites", "Where to go, and the odds"], ["Zones", "Each opens at its level"], ["The heads", "Each one opens a room"]]},
	"kit": {"room": "The Kit", "face": "", "title": "What the runner takes", "voice": "kit", "cues": [0.0, 3.58], "lines": [
		"What the runner takes out is all they've got.",
		"What stays behind is the stash. What's worn out there can be lost out there."],
		"tiles": [["The body", "What's worn"], ["The rig", "Pouches for meds and rounds"], ["The stash", "What's kept back"]]},
	"stats": {"room": "Stats", "face": "", "title": "The runner, on paper", "voice": "stats", "cues": [0.0], "lines": [
		"The runner, on paper. What they hit for, what they can take, what they've done."],
		"tiles": [["Attack", "What they hit for"], ["Defence", "What they can take"], ["The record", "What they've done"]]},
	"training": {"room": "Training", "face": "", "title": "The caravan at the back", "voice": "training", "cues": [0.0, 7.22], "lines": [
		"The caravan at the back. Whoever runs for you sleeps here, and gets better here.",
		"Their past decides what they can learn. The Pitch's tree stays when they don't."],
		"tiles": [["Their past", "What they were, before"], ["Their trees", "What they can learn"], ["The crew", "Pick who goes out"]]},
	"clinic": {"room": "The Clinic", "face": "medic", "title": "The medic", "voice": "clinic", "cues": [0.0, 4.60, 7.58, 12.74], "lines": [
		"Sit down. Don't bleed on that, it's the only clean one.",
		"Resting on the Pitch heals, slowly.",
		"I'm quicker, I cost tins and I'm the only one that can heal a lasting wound.",
		"Meds go in the rig. Your runner takes them first when it gets bad out there."],
		"tiles": [["Treatment", "Wounds and HP, for tins"], ["The shelf", "Meds to buy, new each run"], ["Your meds", "In the rig, used under fire"]]},
	"fence": {"room": "The Fence", "face": "fence", "title": "The Fence", "voice": "fence", "cues": [0.0, 5.44, 9.10], "lines": [
		"Everything's for sale. That's the one thing that hasn't changed.",
		"You bring, I price. The price is the price.",
		"Notes, tins, scrap. I'll change any of it. At a price."],     # the exchange (28 Oct): was the contracts' line - the voice wants recording again
		"tiles": [["The stash", "Yours to sell, for tins"], ["The shelf", "His stock, and sealed lots"], ["The exchange", "Notes, tins, scrap, at his rate"]]},
	"workshop": {"room": "Workshop", "face": "", "title": "The bench", "voice": "workshop", "cues": [0.0, 6.46], "lines": [
		"The armourer's roll, laid out on the bench. Proper tools, for once.",
		"Guns get better here, part by part."],
		"tiles": [["Guns", "Gun parts, fitted"], ["Sockets", "What fits in a socket"], ["Craft", "Affixes, sockets, levels"]]},
	"yard": {"room": "The Pitch", "face": "", "title": "Yours, on paper", "voice": "pitch", "cues": [0.0, 4.84], "lines": [
		"The deeds say it's yours. Paper's about all anyone still agrees on.",
		"Build on it. What's built here comes with you when you move."],
		"tiles": [["The buildings", "What's been built"], ["Ranks", "Each building, better"], ["The purse", "What the Pitch holds"]]},
	"radio": {"room": "Radio", "face": "", "title": "Kev", "voice": "radio", "cues": [0.0, 5.34, 11.14], "lines": [
		"Kev here. Well, you know that. You've got a set now.",
		"Everything worth hearing comes over this. Most of it isn't worth hearing.",
		"Keep listening anyway."],
		"tiles": [["The decoder", "Three papers make a signal"], ["Signals", "A site to run, once"], ["The Dial", "Points from your reach"]]},
}
const ROOM_INTRO_FIRST := ["map", "kit", "stats", "training"]     # open from the start; an old save has met them

## The radio: three voices on the air, a line after every few runs home (RADIO_EVERY), the first unheard one whose
## gate is open: a zone open ("zone"), or lorries beaten ("lorries"). The official loop wears down, a pirate comes on in
## the town, the army's net crackles in the city; the notes' story runs through all three and closes on the loop.
## A save keeps the lines heard by their place here ("voice/index"): add new lines at the end, never reorder.
const RADIO_VOICES := {"loop": "The emergency loop", "kev": "Kev, on the pirate frequency", "net": "The army net", "medic": "The Clinic, on the CB", "fence": "The Fence, on the CB"}
const RADIO_SHORT := {"loop": "The loop", "kev": "Kev", "net": "The army net", "medic": "The medic", "fence": "The Fence"}
## Out of time (16 Oct, Matt's playtest): where the lost kit went, and the gun that ran dry.
const TIME_OUT_LOOSE := ["It's out there now: a gang may be wearing it in a few runs. Clear the site they turn up on and it comes home.",
	"They're out there now: a gang may be wearing them in a few runs. Clear the site they turn up on and they come home."]
const TIME_OUT_DRY := "The %s ran dry."
## Kev's papers (16 Oct): his line on the Radio's pile, and the log's when one's bought.
const KEV_PILE := "\"People bring me paper. Receipts, tickets, logbooks. Bring me notes and I'll see what's in the pile.\""
const KEV_SOLD := "Off Kev's pile:"
## Signals (15 Oct): Kev on what a fix tells him, one a signal; and the Radio's log lines.
const SIGNAL_LINES := [
	"Same three lorries, twice this week, both times nights. Whatever's in them, they don't want it seen in the day.",
	"That's a convoy's call sign on a council frequency. Somebody's lending them the masts.",
	"They stop there to fill up. Diesel, and something that needs keeping cold.",
	"Four on the road, three came back. I'd like to know where the fourth went.",
	"Army net, plain as day. They don't even bother with the code any more.",
	"The fix is old, a week maybe. Whoever was there might still be.",
	"They changed the route. Means somebody's been watching it. Means us, probably.",
	"Every one of these papers came out of a lorry's cab. They're writing it all down.",
]
## The radio line's traffic (16 Oct, item 6): what's on the air under what you can hear, garbled on the strip; once
## the Radio's open a word or two comes through in the voice's colour. Nothing to read in it, and nothing in the sim.
const RADIO_TRAFFIC := [
	{"voice": "net", "text": "All call signs hold for the second route out"},
	{"voice": "net", "text": "Convoy six loading at the depot before first light"},
	{"voice": "loop", "text": "Remain where you are the route is closed"},
	{"voice": "kev", "text": "Anyone still listening on this band say something"},
	{"voice": "net", "text": "Paper count confirmed twice signed and sealed"},
	{"voice": "loop", "text": "Withdrawals are suspended until further notice"},
	{"voice": "kev", "text": "Lorries on the ring road again heading north"},
	{"voice": "net", "text": "Masts on the council roof are ours from tonight"},
]
const RADIO_QUIET := ["Nothing on the air yet: the Quartermaster holds the set.", "The papers you find are kept. Most carry a code, unreadable till the Radio's open."]
## Kev's story (15 Oct): a beat's line when its paper comes home, when its signal's made, and when it's beaten.
const STORY := [
	{"found": "%s: one of Kev's. The route's in it somewhere (%d of 3).", "made": "Kev: \"Three of them, and they say the same thing. They run a route. Here's where it goes.\"",
		"won": "Kev: \"Same lorries, same road, every week. Not looters. Somebody's running this. Find me who.\""},
	{"found": "%s: army paper. Kev will want it (%d of 3).", "made": "Kev: \"It's the army's. Still giving orders, still feeding men. The Garrison. Go and ask them.\"",
		"won": "Kev: \"The Garrison, and they answer to somebody at the end of the road. A depot. That's where the load goes.\""},
	{"found": "%s: the depot's. One more step (%d of 3).", "made": "Kev: \"That's the depot. The convoy's due. Stop it and we see what they've been moving all along.\"",
		"won": "Kev: \"So that's the load. All of it, all this time. Keep the radio on. There'll be more of them.\""},
]
## The rebuild (18 Oct, docs/design/rebuild.md): Kev's last line opens it; the places and the order in his words.
const REBUILD := {
	"open": "Kev: \"Someone has to put it back together. Might as well be the people who know where everything went.\"",
	"first_material": "%s. Kev says someone used to want that.",
	"built": "%s rebuilt: rank %d. The town's worth is %d.",
	"opened": "%s is open on the map, under the order.",
	"material": "Brought home: %s",
	"note": "The first true FIAT note. Its value is as stated. The mint pays double from here.",
	"order_lost": "%s is still standing.",
	"order_won": "%s is down. The order is one short.",
}
const PINNACLE_WORDS := {
	"grid": "Kept the lights on for the order's people only.",
	"archive": "Decides who was born, who owns, who's owed.",
	"mint": "Prints the money nobody believes in. \"Its value is as stated.\"",
}
## The County's places (25 Oct): a line each on its card.
const COUNTY_WORDS := {
	"toll_plaza": "The barriers are down again. Everything that moves on the road pays here.",
	"distribution": "Where the lorries were loaded. They load them for the Issuer now.",
	"truck_stop": "The Bailiff keeps the drivers' cafe. He keeps their keys too.",
	"container_port": "Stacks of boxes, every one stamped. Nobody opens one without a form.",
	"ferry_terminal": "The boats still come in. What's on them is declared or it's gone.",
	"customs_shed": "The Auditor counts what comes through, and what you carry out.",
	"golf_club": "The members kept their club. Their staff carry guns now, not bags.",
	"gated_close": "Six houses and a gate. The gate is the point.",
	"manor": "The Collector lives where the debts end up. Most of the county owes him.",
	"counting_house": "Clerks at long tables, counting what the County is said to be worth.",
	"bullion_vault": "There's no gold in it. There are guards on it anyway.",
	"treasury": "The Treasurer makes the money stick. She is the last of the Issuer's people.",
}
const COUNTY := {
	"title": "The County", "tab": "The County", "kicker": "THE ISSUER'S PEOPLE",
	"sub": "Past the City, where the new money's made to stick. Each zone wants issued kit worn.",
	"not_yet": "Not before the Issue", "zone_shut": "%s first", "place_shut": "Take %s first",
	"want": "Wear %d issued pieces (%d worn)", "want_short": "Wear %d issued",
	"taken": "%s is taken.", "again": "%s, taken again. It'll be harder next time.", "lost": "The County keeps %s.",
	"zone_opens": "The road's open to %s. It wants %d issued pieces worn.",
	"remix": "The Treasurer's down. The Radio picks up both maps now: the remix is open.",
	"head_down": "%s is down. Found: %s.", "let_go": "The Bailiff lets your %s go.",
	"chip_owed": "Owed: +%d%% taken", "chip_tax": "Skills taxed ×1.5", "chip_seized": "Seized: %s",
	"want_how": "Issued kit: the Issuer, at the Fence; or stamp your own at the Bench",
	"slots_head": "ISSUED KIT WORN · %d OF %d · THE %s WANTS %d", "slots_short": "ISSUED KIT WORN · %d OF %d",
	"to_issuer": "The Issuer, at the Fence  ›", "to_issuer_short": "The Issuer  ›", "to_bench": "Stamp your own, at the Bench  ›", "to_bench_short": "Stamp your own  ›",
	"shut_kicker": "SHUT", "shut_line": "Take %s (%s) first, then wear %d issued pieces.",
	"key": {"safe": "Safe", "risky": "Risky", "bad": "A bad idea", "shut": "Shut", "taken": "Taken"},
	"mech": {"bailiff": "He seizes your best piece till he's under half.", "auditor": "He taxes your skills ×1.5 and stamps one shut.",
		"collector": "His bill grows while he's out; drop a debtor to cut it.", "treasurer": "He shields, and prints men to stand in front."},
	"level": "Level %d", "beaten": "Taken %d", "head": "Its head: %s", "odds_reading": "Reading the odds",
	"drops_head": "The host's crew and drops, paid in fiat", "drops_issued": "Issued kit off the head",
	"progress": "%d of 12 taken",
	"remix_issued": "Off the signal: %s.",
}
const SIGNAL_MADE := "A signal: a fix on %s, level %d"
const SIGNAL_BINNED := "The signal on %s, binned"
const SIGNAL_REACH := "A signal beaten at level %d: your reach is level %d"
const SIGNAL_LOST := "The signal's gone with the run"
const SIGNAL_PAPERS := "Off the signal, for the Radio: %s"
const PILE_FULL := "The papers are at %d, the cap: the lowest one was burnt"     # the Radio's pile at its cap (23 Oct; the language pass: mechanics, one sentence, the panel's name)
const TOPPED_UP := "Topped up: %d rounds and %d meds from the stash into the rig"     # the rig at the gate (23 Oct)
const TOP_UP := {"leave": "Leave it", "fill": "Top up", "best": "Best grades only"}     # the rig at the gate, the Map's button (23 Oct; "Top up" as the log's "Topped up", the language pass)
const TOP_UP_MID := {"leave": "leave it", "fill": "top up", "best": "best grades only"}     # after the button's colon: sentence case
const TOPPED_UP_MEDS := "Topped up: %d meds from the stash into the rig"     # meds alone
const BOX_FOUND := [["A box: it fills your magazines at home", "Fills magazines at home"], ["Rounds go in the rig as magazines", "Not loose in the rig"]]     # a box found on a run (28 Oct)
const FILLED_MAGS :="The magazines filled: %d rounds from the stash"     # the rig's magazines at home, the mode Leave it (28 Oct)
## The cures (28 Oct): what each stops, as a log line and a card say it; the chips for frost and shock on you.
const CURE_WORD := {"bleed": "the bleeding", "fire": "the burns", "poison": "the poison", "frost": "the chill", "shock": "the shock"}
const CURE_CLEARS := {"bleed": "Stops a bleed", "fire": "Stops burns", "poison": "Stops poison", "frost": "Stops a chill", "shock": "Stops a shock"}
const ON_YOU_AIL := {"frost": ["Chilled: fire %d%% slower", "Chilled"], "shock": ["Shocked: %d%% more taken", "Shocked"]}
const PACK_EMPTY := "Nothing found yet. What the run turns up lands here; pick a cell to read it."     # the run's pack card, empty (23 Oct)
const PACK_PICK := "Pick a cell for its figures; Select ditches several at once"
const TOP_UP_SHORT := {"leave": "Leave it", "fill": "Top up", "best": "Best only"}
const TOP_UP_TINY := {"leave": "As is", "fill": "Top up", "best": "Best"}     # a third of the card's foot, beside the skills (24 Oct)
const TOP_UP_TIP := "The rig at the gate, before every run. Top up: every grade of the worn guns' rounds, then the meds, the best first, into the pouches left. Best grades only: the top grade of each, nothing lower. Leave it: the rig goes as packed. Press to change; it stays set."
const RADIO_READ := "The Radio reads the papers you hold: %d new to the drawer"     # the Radio open (15 Oct): the papers held, read at once
const RADIO_LEAD := "On the radio: "     # a heard line in the log (13 Oct, Matt: no speaker; the radio has its own voice)
const RADIO := [
	{"voice": "loop", "zone": 0, "text": "This is a recorded message. Remain in your homes. Cash withdrawals are limited to fifty pounds a day."},
	{"voice": "loop", "zone": 0, "text": "This is a recorded message. Remain in your homes. Cash withdrawals are limited to."},
	{"voice": "loop", "zone": 1, "text": "This is a recorded. Remain. Limited to."},
	{"voice": "kev", "zone": 1, "text": "Kev here, on whatever this is. If you can hear me, you've got batteries. Look after them."},
	{"voice": "kev", "zone": 1, "text": "Someone on the Parade's buying old tenners. Paying in tins. Make of that what you like."},
	{"voice": "loop", "zone": 2, "stopped": true, "text": "The loop's stopped. It's just the tone now."},
	{"voice": "kev", "zone": 2, "text": "The Bank crew are taking notes by the bin bag. Not spending them. Counting them. Twice."},
	{"voice": "kev", "zone": 2, "text": "A request, from a lady in the flats: could whoever took her bins bring the bins back. Keep the rest."},
	{"voice": "net", "zone": 3, "text": "Convoy four, convoy four. Load is paper. Destination withheld. Acknowledge."},
	{"voice": "kev", "zone": 3, "text": "The army's on the air. They don't say much. They say 'paper' a lot."},
	{"voice": "net", "zone": 3, "text": "All call signs. The lorry is not to be stopped. Repeat, not to be stopped."},
	{"voice": "kev", "lorries": 1, "text": "Somebody stopped the lorry. It was notes, baled. Somebody else signed for them at the other end. I'd like to know who."},
	{"voice": "net", "lorries": 2, "text": "Collection resumes on the second route. The holders are to be registered. Out."},
	{"voice": "kev", "lorries": 3, "text": "Rumour is the Mint never stopped. Llantrisant. The lights on all night and nobody going in."},
	{"voice": "net", "lorries": 4, "text": "Exchange to commence on a date to be announced. Old notes at par from registered holders only."},
	{"voice": "kev", "lorries": 5, "text": "Registered holders. That's the crews. That's who they were holding it all for. Not for them. For whoever comes back."},
	{"voice": "loop", "lorries": 6, "text": "This is a recorded message. A new currency will be issued. Its value is as stated. By order. Let it be done."},
	# the gates (13 Oct, Matt: a line before each room opens and one after; "gate": the head and when - never in the turn)
	{"voice": "medic", "zone": 0, "gate": "The Gamekeeper/before", "text": "Anyone near Top Farm: the keeper there has a vet's bag. I can work with that. I can't work with nothing."},
	{"voice": "medic", "zone": 0, "gate": "The Gamekeeper/after", "text": "Got the bag. The Clinic's open. Come in hurt, not dead; I can't do anything about dead."},
	{"voice": "kev", "zone": 1, "gate": "The Carpet Man/before", "text": "The Carpet Man's got his fitter's kit at the warehouse. Knives, kicker, staple gun. That's a workshop, that is."},
	{"voice": "kev", "zone": 1, "gate": "The Carpet Man/after", "text": "Somebody's got the Carpet Man's tools. There's a bench going on the Pitch."},
	{"voice": "fence", "zone": 2, "gate": "The Manager/before", "text": "The Carpet Man banked his book with the Manager. Bring me that book and I'll open up shop."},
	{"voice": "fence", "zone": 2, "gate": "The Manager/after", "text": "The book's here. I'm open. Tins only, and don't ask me where any of it came from."},
	{"voice": "kev", "zone": 2, "gate": "The Manager/before", "text": "The Bank's got deeds in the vault. Every house on the estate. Somebody could set up somewhere with those."},
	{"voice": "kev", "zone": 2, "gate": "The Manager/after", "text": "Somebody's got the deeds out of the Bank. Somebody's got themselves a pitch."},
	# the deeds' fate (27 Oct, Matt): a line for each, in the turn once it's decided ("deeds")
	{"voice": "kev", "zone": 2, "deeds": "burned", "text": "Somebody burned the deeds. Nobody on the estate owes a penny. The Bailiff's going to hate that."},
	{"voice": "kev", "zone": 2, "deeds": "held", "text": "Whoever's got the deeds, hang on to them. Money comes and goes. Bricks don't."},
	{"voice": "kev", "zone": 2, "deeds": "sold", "text": "The deeds went to the Fence, and the Fence sold them on. Somebody up the County will come for what's owed."},
	{"voice": "net", "zone": 3, "gate": "The Quartermaster/before", "text": "Quartermaster to all stations: the set stays in stores. Nobody signs them out."},
	{"voice": "kev", "zone": 3, "gate": "The Quartermaster/after", "text": "There's an army set on this frequency now. Hello, whoever you are."},
	# the Clinic's and the Fence's own (13 Oct, Matt): in the turn once their room is open ("room")
	{"voice": "medic", "zone": 0, "room": "clinic", "text": "Bandages are boiled, not new. Don't ask."},
	{"voice": "medic", "zone": 0, "room": "clinic", "text": "If it's bleeding, bring it in. If it's stopped, bring it in faster."},
	{"voice": "medic", "zone": 0, "room": "clinic", "text": "I had a shift pattern once. Now I have a queue."},
	{"voice": "medic", "zone": 0, "room": "clinic", "text": "Whoever took the paracetamol off the shelf: that was the shelf."},
	{"voice": "fence", "zone": 1, "room": "fence", "text": "Buying: anything. Selling: what you sold me last week."},
	{"voice": "fence", "zone": 1, "room": "fence", "text": "Tins only. Notes go to the radio man, not me."},
	{"voice": "fence", "zone": 1, "room": "fence", "text": "Somebody brings me the same kettle every Tuesday. I keep buying it."},
	{"voice": "fence", "zone": 1, "room": "fence", "text": "Prices are what they are. Complain to the Bank."},
]

## The heads' things (13 Oct): what each is, on its card.
## The heads' things as keepsakes (15 Oct, Matt: the vet's bag "goes to the medic" felt odd): in the pack at the drop,
## then in the drawer, with what they opened.
const KEEPSAKE := "A keepsake: it opened %s"
const GATE_ITEMS := {
	"The vet's bag": "The keeper's, for the dogs. Everything a vet carries, and the medic says that's most of what a doctor does.",
	"The Carpet Man's ledger": "Who bought what, and who paid. The Carpet Man banked it with the Manager. The Fence will want this more than anyone.",
	"A military radio": "Army issue, the set the lorry never delivered. It reaches further than Kev does.",
	"The fitter's kit": "Knives, a knee kicker, a staple gun and a tin of tacks, in the Carpet Man's own roll. A workshop, near enough.",
}

## A room opening, in the log (13 Oct): the head's thing home, the room with it.
const GATES := {
	"clinic": "The vet's bag's come home. The Clinic's open.",
	"fence": "The Fence has seen the ledger. He's open for business.",
	"yard": "The deeds are the Pitch's. Build on it.",
	"radio": "The set's in and working. The Radio's on the air.",
	"workshop": "The fitter's kit goes on the bench. The Workshop's open.",
	"shut": {"clinic": "the Gamekeeper's vet's bag", "fence": "the ledger in the Manager's vault", "yard": "the Manager's deeds", "radio": "the Quartermaster's military radio", "workshop": "the Carpet Man's fitter's kit"},
}

## The gangs (12 Oct, now they have faces): a name a zone, and a line as one arrives, in turn.
## A harder gang (B9): the next zone's crew come in, or the City's past the last.
const GANG_IN_FROM := "in from %s"
const GANG_HARD_CORE := "the hard core"
const GANGS := [
	{"name": "The field lads", "arrive": ["Wellies, a billhook, a dog somewhere behind.", "They come over the hedge, not round it.", "Mud to the knee. They've been waiting."]},
	{"name": "The Parade boys", "arrive": ["Hoods up.", "One of them's filming it.", "They knew you were coming. Somebody always says."]},
	{"name": "The High Street lot", "arrive": ["They smell of petrol before you see them.", "A bottle with a rag in it, lit.", "They've done this outside every shop on the street."]},
	{"name": "The Garrison", "arrive": ["They come in pairs, covering.", "Somebody's still giving orders.", "Greatcoats, and the discipline to go with them."]},
]

## The traits: what the runner's like, said when they turn up.
const TRAITS := {
	"Lucky": "Found a twenty in a hedge once. Hasn't stopped looking since.",
	"Heavy-handed": "Doesn't do anything gently. Doors, mostly.",
	"Wary": "Sits facing the door. Every door.",
	"Greedy": "Counts the take twice and the cuts once.",
	"Tough": "Has been hit by worse. Says so.",
	"Light": "Gone before you finish the sentence.",
	"Careful": "Packs the kit the same way every time. Unpacks it the same way too.",
	"Nosy": "Opens every drawer. Reads every letter.",
}


# ------------------------------------------------------------------ the people

## The Fence. `visit` lines rotate by how often you've been; the rest fire
## on the action and show in the pick panel.

## A name mid-sentence (the caps pass, 8 Oct): "The Parade" stands alone; "to the Parade" in a line.
## A name not yet known, glyph for glyph, the spaces kept: the same name scrambles the same way every time (20 Oct,
## the Radio's glyphs; moved here from Fmt so the sim's log lines can scramble too).
const SCRAMBLE := "ΞЖ§¤ØÞðƷΔΣΠΩψλξζЯЮЩЦФБДЛ¶†‡※∆∑∏≈≠±÷×◊#%&@"


static func scramble(text: String) -> String:
	var out := ""
	for i in range(text.length()):
		var ch: String = text[i]
		out += ch if ch == " " else SCRAMBLE[absi(hash(text + str(i))) % SCRAMBLE.length()]
	return out


static func mid(name: String) -> String:
	return ("the " + name.trim_prefix("The ")) if name.begins_with("The ") else name


## An item base mid-sentence (18 Oct, the style guide): its first letter lower, its acronyms kept ("army SMG").
static func mid_base(base: String) -> String:
	if base.length() > 1 and base.substr(0, 2) == base.substr(0, 2).to_upper():
		return base                          # "SMG ...", "AK ...": an acronym leads
	return base.substr(0, 1).to_lower() + base.substr(1)


## "a farmer's shotgun", "an old revolver": a base with its article.
static func a_thing(base: String) -> String:
	var b := mid_base(base)
	var first: String = b.substr(0, 1)
	var acronym: bool = b.length() > 1 and b.substr(0, 2) == b.substr(0, 2).to_upper()
	var an: bool = (first in "AEFHILMNORSX") if acronym else (first in "aeiou")     # "an SMG", "an AR-pattern rifle"
	return ("an " if an else "a ") + b

const FENCE := {
	"visit": [
		"Everything's for sale. That's the one thing that hasn't changed.",
		"I pay in tins. Don't ask where I get them.",
		"You bring, I price. The price is the price.",
		"The crew in the Bank buy off me too. Different prices.",
		"I knew your last one. Didn't know them long.",
		"Nothing's worth what it was. Some things are worth more.",
	],
	"sold": ["That'll do.", "I've had worse through here.", "Someone will want that.", "Tins. Count them if you like."],
	"bought": ["It's yours. It was someone's.", "No returns.", "Mind how you go with that."],
	"shelf": "More shelf. Same stock, more of it.",
	"exchange": ["Done. Count it if you like.", "That's the rate. Don't look at me like that.", "Pleasure. Mostly mine.", "Rates move. Mine don't go down."],     # the exchange (28 Oct)
	"gamble": ["He had one. Don't ask where.", "That's what came. No returns.", "Sealed when I got it. Sealed when you did."],
	"insured": "I'll hold the paper on it. If they don't come back, the kit does.",
	"paid_out": "Insured. The Fence held the paper; the kit's back on the Pitch. The runner isn't.",
	"mate": ["He doesn't come in. He sends them with me. Don't ask.", "Notes. He still thinks they're money. So do the crews."],
	"town": "You've been past the Retail Park, then. The Bank's got a crew. They'll know your name before you know theirs.",
	"deeds": "I'll find a buyer. Someone always wants to be owed.",
	"papers": "Someone collects these. Don't ask me why.",
}

## The medic.
const MEDIC := {
	"visit": [
		"Sit down. You're letting the cold in.",
		"I stayed on when the pay stopped. Somebody had to.",
		"The Clinic's a caravan. It was a caravan before.",
		"I don't ask what they were doing. I can usually tell.",
	],
	"treated": ["Hold still.", "That's the third time with that arm.", "You'll do.", "Keep it dry. Nothing round here is dry."],
	"fit": "Nothing wrong with you that I can charge for.",
	"hurt": "Lie down before you fall down.",
	"wound": {"head": "Look at me. No, at me. Follow the finger.", "chest": "Breathe in. Now don't. That's the rib.", "legs": "Walk it off? Not on that leg."},
	"wounds": ["", "Two of them now. You're collecting.", "Three of them. Sit down before you fall down."],
	"new_runner": "Another one. The last one didn't listen either.",
	"shelf": "More on the shelf. It won't be enough.",
	"supplies": "Proper dressings. Where did you find these? Don't tell me.",     # supplies handed in (28 Oct)
}
## Medical supplies to the medic (28 Oct): the log's line, each step's line, the Clinic's strip.
const SUPPLIES_IN := "To the medic: %d medical supplies, %d all told"
const SUPPLIES_STEP := ["The Clinic's shelf: a tier up", "The Clinic's shelf: two tiers up", "The Clinic's shelf: some meds Magic now",
	"The Clinic's shelf: some meds Rare now", "The Clinic's shelf: three tiers up, more of it Rare"]
const SUPPLIES_NEXT := ["A tier up on her shelf", "Two tiers up", "Magic meds on her shelf", "Rare meds on her shelf", "Three tiers up, more Rare"]

## What the runner was, before: a line each, and how they turn up at the Yard.
const PASTS := {
	"Poacher": {"was": "Kept the village in rabbits when the shops shut. Knows where everything hides.",
		"arrives": "A poacher turns up at the Pitch, rifle wrapped in a coat. Doesn't say where from.",
		"wall": "Knew where everything hid. Not this."},
	"Doorman": {"was": "Worked the door of a club that closed the week after. Still stands like it's open.",
		"arrives": "A doorman turns up at the Pitch. Big, polite, looks at your hands first.",
		"wall": "Stood in the doorway to the end. Nobody got past while he did."},
	"Paramedic": {"was": "Was a student paramedic when the ambulances stopped. The doctor taught her the rest.",
		"arrives": "A paramedic turns up at the Pitch, still in the green. Asks where the kit is.",
		"wall": "Stayed with the last one. Always did."},
	"Scrapper": {"was": "Stripped the estate's own cars for copper. Knows what everything's worth, to the penny.",
		"arrives": "A scrapper turns up at the Pitch with a trolley. Prices the Pitch before saying hello.",
		"wall": "Knew what everything was worth. The Fence got the trolley."},
	"Recruit": {"was": "Joined up for the meals. Still folds his kit square.",
		"arrives": "A recruit turns up at the Pitch with a kit bag and a box he won't open in front of you.",
		"wall": "Folded his kit square and went first."},
	"Drifter": {"was": "Walked in from somewhere worse. Doesn't say where; doesn't plan to stay.",
		"arrives": "A drifter turns up at the Pitch. Light pack, good boots, already looking at the road.",
		"wall": "Kept walking. Not far enough."},
}


# ------------------------------------------------------------------ the places

## A line a depth on every site - what you learn by going further in - and
## the line the log gives the first clear. Index by tier, then depth − 1
## (the last line holds for every depth past it).
const SITES := {
	# the Outskirts (12 Oct)
	"The Allotments": {
		"depths": [
			"Council plots off the ring road. The sheds were somebody's whole weekend.",
			"Every water butt's been tipped for what was in it.",
			"Someone's still growing potatoes here. They'll fight you for them.",
			"The polytunnel's a house now. The bonfire's a kitchen.",
			"Nothing's grown here in a year but the fence, and the people behind it.",
		],
		"cleared": "The plots are quiet. The beans came up anyway.",
	},
	"The Garden Centre": {
		"depths": [
			"Big glasshouse, bigger car park. The trolleys are still where they were left.",
			"The cafe's been stripped down to the sign for scones.",
			"Compost bags make good walls. Someone worked that out.",
			"The aquatics end smells. Nobody goes to the aquatics end.",
			"Whoever runs it now has the tills open and nothing in them.",
		],
		"cleared": "The garden centre's yours for an hour. The roses don't mind.",
	},
	"Top Farm": {
		"depths": [
			"Up the lane past the cattle grid. The dogs went first, then the farmer.",
			"The barn's full of feed nobody's feeding to anything.",
			"The shotgun cabinet's open and empty. That's the farm's story.",
			"There's diesel in the tank and a quad in the yard. Everybody wants both.",
			"The farmhouse light's on every night. Somebody's keeping it on.",
		],
		"cleared": "Top Farm's quiet. Even the crows have moved down to the town.",
	},
	"Ransacked Streets": {
		"depths": [
			"The first streets off the ring road. Doors open, curtains gone.",
			"Someone's taken the copper out of the walls.",
			"A car on bricks with a child seat still in it.",
			"They've started on the roof tiles.",
			"Nothing left here but the people who stayed. They're the ones with guns.",
		],
		"cleared": "The streets are quiet. They'll fill again; they always do.",
	},
	"The Parade": {
		"depths": [
			"Six shops and a chippy. The chippy went first.",
			"The bookmaker's shutters are the only ones still down.",
			"Someone's living in the launderette. Someone else wants to.",
			"The off-licence has been emptied twice. The second time by its owner.",
			"The post office safe is open. It was empty when the money went.",
		],
		"cleared": "The Parade's yours for an hour. Nobody's shop now.",
	},
	"The Retail Park": {
		"depths": [
			"Big sheds, big car park, nothing in the car park.",
			"The DIY place is the armoury round here. It's where the nail guns came from.",
			"The supermarket's freezers went off in the first week. Nobody's been in since.",
			"There's a crew in the carpet warehouse. They've got the carpet.",
			"The petrol station's forecourt is a market on Sundays. Not this Sunday.",
		],
		"cleared": "The Retail Park's cleared. The road to the Town is open, which is not the same as safe.",
	},
	"The Pleasure Park": {
		"depths": [
			"The wheel still turns when the wind's right.",
			"Somebody kept the arcade's generator going for the lights. Then for the heat.",
			"The log flume's a reservoir now. They guard it.",
			"The ghost train's where they keep what they take.",
			"The man who ran the park is still here. He's the one up on the wheel.",
		],
		"cleared": "The park's quiet. The wheel keeps turning; nobody's on it.",
	},
	"Shopping Centre": {
		"depths": [
			"Two floors and a food court. The escalators are stairs.",
			"The jeweller's was done the first night. Nobody wanted the watches.",
			"The upper floor is a camp. The children's clothes shop, for the children.",
			"The Bank's crew come here for stock. They pay in paper.",
			"The security office has the tapes from the night it happened. Nobody's watched them.",
		],
		"cleared": "The centre's cleared. The camp upstairs didn't come down to look.",
	},
	"The Services": {
		"depths": [
			"A motorway services. The lorries stopped here when the diesel did, and so did the drivers.",
			"The lorry park is a town now. Every trailer's a house; every cab's a shop.",
			"The fuel's long gone. What's in the tanks is what they fight over.",
			"The drivers kept the CB sets. They heard your pitch before they saw it.",
			"The last lorry in was the army's. It isn't here any more. They know where it went.",
		],
		"cleared": "The Services are quiet. The trailers are still houses; nobody's opening the doors.",
	},
	"The Hospital": {
		"depths": [
			"The Hospital kept going longer than anything. Then it kept going without the lights.",
			"A&E is the gate. They triage who comes in, and they're not doctors any more.",
			"The pharmacy was emptied by the staff, by rota, to be fair about it.",
			"Theatres on the third floor. Someone's still operating. Not on who you'd think.",
			"The paramedic's old crew are here. They kept the ambulances. They kept the uniforms.",
		],
		"cleared": "The Hospital's cleared. It still smells of what it was.",
	},
	"The Barracks": {
		"depths": [
			"The depot the lorries never reached. The gate's open; the gatehouse isn't.",
			"The armoury's been issued. The Quartermaster signs for everything, still.",
			"They drill. Properly, in the mornings. Then they go out and take things.",
			"The stores are full of what the town's been missing. He's rationing it.",
			"He's got the lorry. It's in the shed with the engine running, every day, for the heater.",
		],
		"cleared": "The Barracks are cleared. The stores are open. He signed nothing.",
	},
	"The Bank": {
		"depths": [
			"A branch like any other. Steel shutters, a hole in the wall for cash.",
			"The crew call themselves staff. Some of them were.",
			"They've got the tills running off a generator. Nothing to put through them.",
			"The vault's behind the Manager's office. The Manager's behind the vault.",
			"They're not guarding money.",
		],
		"cleared": "The Bank's taken. The vault was never locked.",
	},
}


# ------------------------------------------------------------------ the papers

## Found lying about: a line of the before, one cell each, worth pennies to
## the Fence. The only place the old world speaks. "code": where the radio code is written on it, for the papers that
## carry one (13 Oct, Matt: codes, not words; Data.WORDS' "paper").
const PAPERS := [
	{"name": "A council tax reminder", "value": 2, "words": "Final notice. The council it's from doesn't exist.", "code": "A code pencilled in the payment box."},
	{"name": "A P45", "value": 2, "words": "Someone's last day at the sorting office. Signed, dated, kept.", "code": "A code on the back, in sorting-office stamps."},
	{"name": "A betting slip", "value": 3, "words": "An accumulator on the football. Four of the five came in.", "code": "A code where the stake should be."},
	{"name": "A pawn ticket", "value": 3, "words": "A wedding ring, for a week's shopping. Never collected.", "code": "A code scratched under the ticket number."},
	{"name": "A bank statement", "value": 2, "words": "In credit, to the penny, the week before.", "code": "A code ringed among the transactions."},
	{"name": "A food bank voucher", "value": 2, "words": "Three days' worth. Stamped by the church.", "code": "A code under the church's stamp."},
	{"name": "A mortgage offer", "value": 3, "words": "Approved. Fixed for five years.", "code": "A code in the margin of the small print."},
	{"name": "A school report", "value": 2, "words": "'Tries hard.' The school's in the Shopping Centre now.", "code": "A code in the teacher's comments, in green."},
	{"name": "A lottery ticket", "value": 4, "words": "Unchecked. The draw was the Saturday after.", "code": "A code where the numbers should be."},
	{"name": "A wage slip", "value": 2, "words": "A month's wages. The number means nothing; the name's been underlined.", "code": "A code in the deductions column."},
	{"name": "An eviction notice", "value": 3, "words": "Fourteen days. They stayed.", "code": "A code on the back, in marker."},
	{"name": "A boarding pass", "value": 4, "words": "One way. The flight went; the ticket didn't.", "code": "A code over the barcode, in biro."},
	{"name": "A parking ticket", "value": 2, "words": "Issued the morning of. The car's still there.", "code": "A code where the plate goes."},
	{"name": "A Christmas list", "value": 3, "words": "In a child's hand. Most of it's in the Retail Park.", "code": "A code at the bottom, in a grown-up's hand."},
	# the Outskirts' and the City's (12 Oct, the lore pass): found only at their own sites
	{"name": "A seed order", "value": 2, "words": "Broad beans, onion sets, a dozen seed potatoes. Paid by cheque. Delivered after."},
	{"name": "An allotment waiting list", "value": 2, "words": "Eleven years for a plot. Every name on it has one now."},
	{"name": "A loyalty card", "value": 2, "words": "The garden centre's. Nine stamps of ten. The free coffee's still owed."},
	{"name": "A milk quota letter", "value": 3, "words": "The dairy's last offer, per litre. Less than the water costs. The cows went first."},
	{"name": "A delivery note", "value": 4, "words": "Forty bales, paper, on pallets. Signed for at the Services by someone who printed their name."},
	{"name": "A drug chart", "value": 3, "words": "Bed nine, four-hourly. The last dose is signed for. Nobody's signed the page after."},
	{"name": "A leave pass", "value": 3, "words": "Seventy-two hours, from the Monday. He went home. The barracks marked him absent anyway."},
	{"name": "A tachograph disc", "value": 6, "words": "Eleven hours on the road, two stops, the same two as last week. Kev's story: where they go."},
	{"name": "A route card", "value": 6, "words": "Junction numbers in pencil, a circle round the Services. Kev's story: where they go."},
	{"name": "A fuel receipt", "value": 6, "words": "Four hundred litres of diesel, paid in notes, the old ones. Kev's story: where they go."},
	{"name": "A movement order", "value": 8, "words": "Signed by a major who should be dead. Three lorries, nights only. Kev's story: whose they are."},
	{"name": "A ration chit", "value": 8, "words": "Forty men, fourteen days, from stores. Somebody's still feeding an army. Kev's story: whose they are."},
	{"name": "A signals log", "value": 8, "words": "Call signs, times, and Kev's frequency, circled. Kev's story: whose they are."},
	{"name": "A gate pass", "value": 10, "words": "Valid for the depot, one vehicle, the bearer and his load. Kev's story: the depot."},
	{"name": "A loading manifest", "value": 10, "words": "Crate after crate, and at the bottom, in a different hand: the load. Kev's story: the depot."},
	{"name": "A depot plan", "value": 10, "words": "The yard, the sheds, the gate, and an X where the lorries stop. Kev's story: the depot."},
	{"name": "A requisition", "value": 4, "words": "For the vault: one safe, Chubb, to hold currency, used. Approved. Underlined twice."},
	# the deep ones
	{"name": "A ration book", "value": 4, "words": "Printed after. Someone tried to run it properly, for a while.", "code": "A code on the inside cover."},
	{"name": "A council minute", "value": 4, "words": "The last meeting. Item nine, the lights. There's no item ten.", "code": "A code as item ten, in pencil."},
	{"name": "A bus timetable, amended", "value": 4, "words": "In biro over the print: 'when he's up'.", "code": "A code among the times."},
	{"name": "A letter to the Bank", "value": 5, "words": "'I would like to withdraw.' Posted. The Bank's the one you cleared.", "code": "A code under the signature."},
	{"name": "A list of names", "value": 5, "words": "Chalked, then written, then typed. The typed ones are crossed out.", "code": "A code against one of the names."},
	{"name": "The Manager's note", "value": 6, "words": "'Back in five.' Pinned to the inside of the vault.", "code": "A code on the back of the note."},
]
## The drawer in the Caravan: the papers found, in the order found, are the
## story of the estate; nobody else is telling it.
const BOOK := {
	"empty": "Nothing in the drawer yet. Papers come off the sites.",
	"count": "%d of %d found",
	"deep": "The rest are deeper than you've been.",
	"gap": "Not found yet.",
	"gap_site": "Not found yet: only at %s.",
	"gap_deep": "Not found yet: from a level %d signal.",
}
## The radio's log in the Caravan (12 Oct).
const HEARD := {
	"empty": "Nothing heard yet. A new line comes on every few runs home.",
}
## The map at thirty-six (7 Oct).
const MAP := {
	"head_start": "%s at full strength: the Dial gains a point.",
	"empty": "Pick a node above. The points come from your reach: each signal beaten at your reach or past it is a point.",
	"empty_short": "A point for each new reach.",
	"needs": "Needs %s first",
	"column_count": "%d of %d ranks",
}

const MYTHIC_FOUND := "A mythic: %s"


const SHELF := {
	"empty": "Nothing on the shelf yet. Heads carry most of them; some sites keep their own.",
	# the chase (endgame part 3): a gap a thing the shelf waits for, and where it is
	"own_gap": "%s, from a level %d signal on. It drops nowhere else.",
	"head_gap": "%s at full strength, on a level %d signal at his site. The charm only he carries.",
	"lorry_gap": "Kev's last beat: the depot's convoy. The pack it comes home with.",
	"order_gap": "%s, at %s: the order's. Only they carry it.",
	"own_found": "Only %s has it. It drops nowhere else.",
	"own_note": "Level %d signal: %s, only here",
}

## The deeds: what the Bank was holding. Dropped once, when the Bank is
## first cleared; two cells; what you do with them is yours.
const DEEDS := {
	"name": "The deeds", "value": 5000,
	"words": "Every mortgage on the estate, in a fire box. The crew held the Bank for this.",
	"found": "In the vault: a fire box. The paper on every house on the estate.",
	"burned": "Burned on the Pitch. Nobody on the estate owes anybody. Let it be done.",
	"sold": "Sold on. Someone, somewhere, is owed the estate now. Let it be done.",
	"held": "The Pitch holds the paper on every house on the estate. Let it be done.",
	# the Bailiff reads the deeds' fate (27 Oct, Matt: "what can we do with the options we already have")
	"void": "The Bailiff reads his warrant twice. The paper behind it is ash. He has nothing on you.",
	"seized": "The Bailiff wants the deeds, not your kit. He holds them till you make him let go.",
	"taken": "The Bailiff kept the deeds. Someone up the County owns the estate now.",
	"back": "In the Bailiff's case: the deeds, sold on and come round again.",
}


# ------------------------------------------------------------------ the bosses

## The crews' heads: a line when they come out, a line when they go down.
const BOSSES := {
	"The Gamekeeper": {"armed": "The dogs hear you before he does. Then he does.", "out": "He comes along the hedge with the gun broken over his arm. He closes it.", "down": "The dogs sit. They were never his; he only fed them."},
	"The Carpet Man": {"armed": "Word goes to the warehouse that you're coming. He puts the kettle on.", "out": "He's brought the whole warehouse.", "down": "The warehouse crew go quiet. Somebody else will have the car park by morning."},
	"The Manager": {"armed": "The branch is told to expect you. He has the staff tidy the counters.", "out": "He's in a suit. It fits.", "down": "The staff stop. Nobody's told them what to do next, and he isn't going to."},
	"The Quartermaster": {"armed": "The depot's gate is left open for you. That's not a kindness.", "out": "He signs for you.", "down": "The depot's unlocked. Nobody's counting any more."},
	# the County's (25 Oct): the Issuer's people
	"The Bailiff": {"out": "He has a clipboard and a warrant with your name on it. He takes your best piece before you've said a word."},
	"The Auditor": {"out": "He wants it all accounted for. Every skill you use is a line on his sheet, and he charges for the line."},
	"The Collector": {"out": "He sends his debtors in first. The longer he's out, the more you owe."},
	"The Treasurer": {"out": "She stands behind the glass and has another man printed for every one you put down."},
}


# ------------------------------------------------------------------ the uniques

## Who they were.
const UNIQUES := {
	"The Keeper's Twelve-Bore": "For the vermin, he said, and he meant it about everyone. It's been cleaned every night for forty years.",
	"The Keeper's Wax Jacket": "Waxed till it's armour. Thorns, teeth and the shoot's own lead have all been off it.",
	"Grandad's Shotgun": "Sixty years in a cupboard under the stairs. He kept it for rabbits. He never said whose grandad.",
	"The Postman's Bag": "He kept the round going for a year after the last letter. People gave him things to carry.",
	"The Doorman's Jacket": "The club shut; he stood on the door of the Shopping Centre instead. Nobody told him to.",
	"Lucky Cap": "Covered in stickers from every site it's been on. It outlasted three owners. That's the luck.",
	"The Van's Spare": "The Carpet Man's. Under the driver's seat for the one time, which was you.",
	"Underlay": "His own jacket, lined with the good underlay, the kind people paid extra for. Stops a lot.",
	"The Manager's Coat": "A good coat over a better vest. He wore it to the vault every morning. He had standards.",
	"The Branch Pistol": "The pistol from under the counter at the Bank, kept for a robbery that never came. Then everything was one.",
	"The Quartermaster's Rifle": "Issued to himself, signed for by himself. Zeroed every Sunday.",
	"Issue Webbing": "The last set the depot issued, to the last man who signed for it. The pouches are full of paperwork.",
	"The Lineman's Lamp": "He wore it up the poles when the lights went off for everyone but them. It still finds the live wire first.",
	"The Registrar's Satchel": "Births, deeds, debts: she carried the town's paperwork about with her in case anyone asked. Nobody did.",
	"The Issuer's Robes": "Cut for a man who signs money into being. Heavy, because it has to be.",
	"The Lineman's Tool Bag": "Insulated pliers, a tester, a roll of tape. Everything he needed to decide whose street stayed lit.",
	"The Registrar's Stamp": "Rubber, red ink, a worn handle. Three of anything and the third went through without her reading it.",
	"The Issuer's Revolver": "He never fired it. He never had to. Whatever it was pointed at got paid for twice.",
	"The Van Keys": "The Carpet Man's. The van's long gone, but the keys were in his pocket, and they're the kind that start anything.",
	"The Manager's Pen": "His own, not the counter's. Everything he signed, he signed with this, right up to the last day. It still works.",
	"The Quartermaster's Ledger": "Every round, every blanket, every name, in his hand. What's signed for is yours. He'd say so himself, now.",
	"The Lorry's Load": "What the convoy was carrying, in the end. Not food. Notes, baled, and the tarp they were under. Nobody said what for.",
	"The Council's Weed Burner": "Parks department. A gas bottle on a frame and a lance with a roar in it. It was for the pavements. It still is, in a way.",
	"Jump Leads": "Red and black, from a boot. Clip them to the right thing and the first one they touch passes it on.",
	"The Rat Man's Bag": "The council's rat man had a bag, and whatever's in the bottom of it never came out. It's in everything you put in there now.",
	"The Butcher's Steel": "Not the knife, the steel: the rod he ran the knife down. Anything cut with what it's touched doesn't close.",
	"The Gritter's Hopper": "The yellow hopper off the back of the gritter, cut down and strapped on. Everyone near you is standing in January.",
	"The Sparky's Gloves": "Rubber, to the elbow, tested and stamped. He never got a belt in thirty years. Neither will you.",
	"The Milkman's Gloves": "Fingerless, from the dairy's last round. He was done by seven every morning and never once ran.",
	"The Safecracker's Gloves": "Thin kid leather, the fingertips sanded. He opened the Bank's old vault in them, the story goes, and closed it again.",
	"The Quartermaster's Manual": "Every piece of kit the army ever issued, and how to use it, in a binder. He'd read it. Now so have you.",
	"A Blue Plaque": "Off a wall in town: somebody lived here. It makes you a listed building. Nothing on you works but the listing.",
	"The Lollipop Lady's Sign": "STOP, on a pole, scratched. She held it up for forty years and nobody went through. They still don't.",
	"The Bookie's Pencil": "Short, flat, chewed. He used it to work out who'd lose. Twice as lucky, half as paid.",
	"The Float": "The milk float's keys and the battery to run it. Quiet, quick, carries anything, and there's no room on it for a first aid kit.",
	"Nan's Cardigan": "Knitted. It stops nothing and it fixes everything, which is what it did before.",
	"The Dinner Lady's Ladle": "Stainless, the size of a face. One serving, one at a time, and you feel better for every one. Don't ask her for a plaster.",
	"A Traffic Warden's Hat": "Nobody liked him. People see the hat and one of them goes home. The rest of them pay the fine.",
	"The Vicar's Thermos": "Tea, strong, always. Whatever's burning on you he'd call warmth. Don't stand near the fire for long, mind.",
	"The Scout Leader's Whistle": "One blast and everyone falls in; two and they go home. The gangs have heard it before.",
	"The Sergeant's Whistle": "Everyone comes at once, which was the point, and you hit like a section because that was the point too.",
	"The Electrician's Tester": "A screwdriver with a bulb in it. Touch something and it stays lit until it's dead. The bulb's not bright.",
	"The Gamekeeper's Flask": "Sloe gin, with something in it for the pheasants. What they give you, you give back.",
	"The Caretaker's Keys": "Every door on the estate on one ring. Something's always open and something's always happening.",
	"The Lorry Driver's Log": "Hours, miles, stops, in biro. It's worth notes to the right people, and the Fence insures anyone who's got one, for free, because he wants it.",
	"The Arsonist's Rig": "Every pouch smells of petrol. Whatever you reach for in it, something near you catches.",
	"The Gritter's Keys": "The council's gritting lorry, and the man who drove it all one winter. The cold does what he says.",
	"The Rat Man's Overalls": "The pest man's, stiff with what he sprayed. Nothing that gets poisoned near him stops being poisoned.",
	"The Substation Key": "A key to a box no one should open. Everyone it touches touches everyone else.",
	"The Butcher's Apron": "Chainmail under a rubber apron. The butcher never stopped at one cut.",
	"The Starting Pistol": "From the school sports day, rebored. Everyone used to wait for it. Everyone still does, for about a second.",
	"The Miner's Lamp": "Off the last shift at the pit, the battery rewired. It finds the seam before you've looked.",
	"The Paramedic's Bum Bag": "Off an ambulance that stopped coming. Plasters, a foil blanket, and a habit of being there when you go down.",
	"The Plumber's Belt": "Wrenches, PTFE tape, a blowtorch. Whatever he fixed stayed fixed. Whatever he broke stayed broken.",
	# the mythics (16 Oct)
	"The Last Orders": "Called at every pub in the borough on the same night. Nobody who heard the bell went home sober, or whole.",
	"The Spare Key": "Under the mat, behind the meter, in the drainpipe. It opens everything, and it never waits its turn.",
	"The Headmaster's Cap": "He knew every lesson in the building and taught them all at once. Put it on and so do you.",
	"The Bomb Disposal Suit": "Forty kilos of the army's best idea. Whatever goes off near you, you walk out of it slowly.",
	"The Crash Bag": "Off the last ambulance in the county. However much you take out of it, it's full again by the next corner.",
	"The Removal Van": "Seven and a half tonnes and it still has room. Whatever you find goes in, and comes out better.",
	"The Freedom of the Borough": "A scroll and a key from the Town Hall. The gangs read it, stand aside, and pay you for the privilege.",
}


# ------------------------------------------------------------------ the items

## A line for every base: what it is, where it came from, in the one voice.
const ITEMS := {
	# the start
	"Hand-me-down nail gun": "Somebody's before it was yours, and somebody's before that. Fires when it feels like it.",
	"Claw hammer": "From the shed. It's put up shelves and taken down a fence. It'll do.",
	"Work jacket": "A donkey jacket with the council's name half off the back. Warm. That's the whole of it.",
	"Plastic bag": "A bag for life, one of them. Holds nine things and the shape of the rain.",
	# improvised
	"Nail gun": "From the DIY place. Takes nails; makes holes. The estate's first gun, and most people's last.",
	"Bolt gun": "A captive-bolt from the abattoir, filed down to fire free. One at a time, and it means it.",
	"Pipe shotgun": "Two lengths of pipe and a nail for a firing pin. Shells go in one end; nobody's sure about the other.",
	"Crossbow": "A sports-shop crossbow with a car-spring limb. Quiet, slow, and the bolts come back.",
	"Garage-built rifle": "Someone with a lathe and time on their hands. The second one they built; the first is in them.",
	"Workshop carbine": "The garage got good. A proper receiver, a proper magazine, a stock off a chair.",
	"Tooled-up garage rifle": "The best thing the workshop ever made. Signed under the handguard, which was a mistake.",
	# shotguns
	"Farmer's shotgun": "A side-by-side from a farm that had one for the foxes. The farm's gone; the foxes are fine.",
	"Sawn-off": "The same gun, cut to fit under a coat. Worse at everything but the thing it's for.",
	"Pump shotgun": "A clay-pigeon club's. The club's membership fees were the last money anyone paid willingly.",
	"Riot shotgun": "Police issue, from the night they stopped issuing. Short, black, no questions.",
	"Semi-auto shotgun": "A wildfowler's gun with the plug taken out. Five shells, fast, from a man who liked ducks.",
	"Drum shotgun": "Someone fitted a drum to a security shotgun. It feeds when it feels like it; when it does, that's that.",
	"Automatic shotgun": "An army gun, the kind the news used to show. It arrived with the crew in the Bank.",
	# rifles
	"Semi-auto .22": "A plinking rifle from a garden shed. It's killed more rabbits than people, but not by much now.",
	"Old .303": "A service rifle from a war two wars ago, kept oiled by a man who talked about it. Still hits what it's pointed at.",
	"Stalking rifle": "A deer rifle, walnut and blued, from an estate with a different meaning of the word.",
	"Army bullpup": "The army's own, with the army's own problems. It came off a lorry that never reached the Barracks.",
	"AR-pattern rifle": "Built from parts that came in the post, before the post. Light, fast, hungry.",
	"Battle rifle": "A full-calibre service rifle. Heavy, loud, and nothing it hits gets up to argue.",
	"Scoped .308": "A target rifle with a glass on it. The man who owned it shot paper on Sundays. Then he didn't.",
	"Sniper rifle": "The real thing, from somewhere that shouldn't have lost it. Whoever had it before you didn't miss.",
	# SMGs and carbines
	"Workshop SMG": "A box magazine, a tube, and a trigger. The workshop's bestseller, which tells you about the market.",
	"Police carbine": "An armed-response carbine, from a response that never arrived.",
	"Army SMG": "A soldier's close-quarters gun. Compact, quick, and someone's unit patch is still on the sling.",
	"Belt-fed SMG": "Someone's idea of a joke that worked. A belt in a bag, a gun on a strap, and nothing left standing.",
	"Security guard's carbine": "Issued to the Shopping Centre's night man, who was told he would never need it. He left it in the office.",
	"Courier's SMG": "Under the seat of a van that did the Bank run. The courier kept the van.",
	"Armoured car gun": "The gun the armoured car's guard was meant to have and never got, found in the depot it came from.",
	"Riot squad's SMG": "The riot squad's own, with the squad's number scratched off. Kept in the same cupboard as their shotguns.",
	# secondaries
	"Converted blank-firer": "A starting pistol with the barrel drilled out. It fires. Roughly where you point it.",
	"Flare pistol": "From a lifeboat station. One shot, very bright, and whatever it hits stays lit.",
	"Air pistol": "A target pistol from a bedroom. Pellets, not bullets, which is not nothing at the range you'll use it.",
	"Service pistol": "Police issue. The holster still has the officer's number inside the flap.",
	"Old revolver": "A six-shot from under a pub counter, where it had been since before the landlord was born.",
	"Compact pistol": "Small enough for a handbag, which is where it was. Fast to draw, forgettable to fire.",
	"Machine pistol": "A pistol that thinks it's an SMG. It empties itself before you've decided.",
	"Big revolver": "A hunting revolver, the kind magazines wrote about. Six shots and your wrist.",
	"Tactical pistol": "A modern service pistol with a rail and a light. The light's dead; the rest isn't.",
	"Automatic pistol": "A machine pistol built properly, by people who meant it. Twenty rounds as a sentence.",
	# helmets
	"Hard hat": "Off a building site. Stops a brick; stops a bottle. Stops people looking at your face.",
	"Cycle helmet": "Light, bright, and better than nothing by about the width of the foam.",
	"Riot helmet": "A police helmet with the visor cracked. The crack is at eye height, which is instructive.",
	"Fire helmet": "A fireman's helmet. Heavy, hot, and it's been through worse than you.",
	"Army helmet": "Issue, with a cover in a camouflage for a country this isn't.",
	"Visored helmet": "A riot helmet with the visor intact. You can see out; they can't see in.",
	"Ballistic visor": "A helmet with a plate of glass that stops rounds. It was for a job. It's for this now.",
	"Full-face helmet": "A helmet and a mask in one, from a unit that didn't come back for it. Nothing gets to your face.",
	# armour
	"Stab vest": "A security guard's. Stops a knife. Slows a bullet down enough to think about it.",
	"Padded jacket": "A work jacket with the padding doubled. Warm, and that counts for more than you'd think.",
	"Police body armour": "Issue, from a station that was. The name's been picked off the chest; the shape of it's still there.",
	"Motorbike leathers": "Armoured at the shoulders and elbows, for coming off at sixty. Good for the rest of it too.",
	"Army plates": "A carrier and two plates, from the lorry the bullpup came off. Heavy, and the weight is the point.",
	"Ceramic plates": "The good plates. One hit and they're done; you aren't.",
	"Riot suit": "Shin to shoulder in hard plastic. You can't run in it. You won't need to.",
	"Ballistic vest": "A vest that stops pistol rounds and most of what comes after. From somewhere with a budget.",
	"Full plate carrier": "Front, back and sides, pouches, the lot. The crew in the Bank wear these. Now so do you.",
	"Light plates": "The thin plates, the slim carrier, the kind you wear under a coat. For people who need to move.",
	# rigs
	"Bum bag": "Three pockets round your waist. It's where people kept their money. It's where you keep what matters.",
	"Fishing vest": "Twelve pockets, half of them for flies. A kit here, a box there; you'll stop noticing the hooks.",
	"Paramedic's rig": "Green, reflective, and laid out so the hands know where the kit is before the head does.",
	"Chest rig": "Pouches across the chest, army surplus from when there was an army to be surplus to.",
	"Webbing": "A belt and straps, worn light. Everything to hand and nothing in the way.",
	"Medic's harness": "A full harness with the pouches for the job. The last one to wear it is why the Clinic has a shelf.",
	"Plate rig": "A rig with a plate behind the pouches. The crew's own pattern; you'll be the second owner.",
	# packs
	"School bag": "A child's rucksack with a cartoon on it. It holds what it holds. Nobody's laughing.",
	"Carrier bags": "Bags for life. Two in each hand. Light, quick, and everything in them is a decision.",
	"Hiking pack": "A walker's pack from a shop that sold the outdoors to people who lived indoors.",
	"Holdall": "A gym bag, a kit bag, a getaway bag. It's been all three.",
	"Bergen": "An army rucksack, built for a man to carry a week. It's carried worse.",
	"Framed pack": "An expedition pack on a frame, for mountains. The frame takes the weight; you take the frame.",
	"Expedition pack": "The biggest pack the shop sold, for a trip nobody took. It takes everything, slowly.",
	"Cargo frame": "A frame and straps, no bag: you tie things to it. People, once.",
	# medical
	"Painkillers": "From a bathroom cabinet. Takes the edge off; the edge comes back.",
	"Petrol bomb": "A milk bottle, a rag, a splash of unleaded. Thrown underarm, like at the match.",
	"Nail bomb": "A tin of nails round something that goes bang. Everyone near it keeps bleeding.",
	"Bottle of something": "Nobody knows what. It was under the sink. They breathe it and go green.",
	"Dry-ice bag": "A carrier bag of the stuff from the ice-cream van. It bursts, and they stop moving.",
	"Wired battery": "A car battery with the terminals wired wrong. Thrown, it finds everyone standing in the wet.",
	"Bandage": "A roll of it. Pressure, time, and don't look.",
	# the cures and the Clinic's supplies (28 Oct)
	"Tourniquet": "A strap and a stick. Tighter than you'd think, and note the time.",
	"Burn gel": "A sachet of something cold. On the burn, not near it.",
	"Activated charcoal": "Black, gritty, horrible. Whatever you swallowed, it swallows.",
	"Hot flask": "Tea, still hot, in a dented flask. The shakes stop by the second cup.",
	"Smelling salts": "One sniff and you're back, whether you wanted to be or not.",
	"Medical supplies": "Dressings, gloves, sealed things with dates on. The medic will want these.",
	"First aid kit": "A green box from a kitchen wall. Most of what's in it is plasters. The rest is what you want.",
	"Field dressing": "Army issue, vacuum packed. Tear, press, hold. It's quicker than it sounds.",
	"Trauma kit": "A paramedic's bag with the good things in it. Clotting, splints, a mask for the worst of it.",
	"Surgeon's kit": "What the Clinic would use, in a roll. If you're using it yourself, it's that bad.",
	# ammo
	"Nails": "A box from the DIY place. The gun doesn't care which end goes first.",
	"Hardened bolts": "Bolts someone's tempered on a forge. They go through what nails bounce off.",
	"Shells": "Birdshot, mostly, from a cabinet with the key still in it.",
	"Slugs": "One lump of lead a shell, for things bigger than birds. Everything's bigger than birds now.",
	"Rifle rounds": "Mixed calibres in a biscuit tin. Enough of them fit.",
	"Match rounds": "Target ammunition, boxed and counted by someone careful. They fly straighter; so will you.",
	"SMG rounds": "Boxed 9mm, the most common round in the country. It's why there are so many SMGs.",
	"SMG hollow point": "Police issue 9mm. They open up inside. That's the whole description.",
	"Pistol rounds": "A bag of mixed pistol ammunition from a drawer that had a pistol in it once.",
	"Pistol hollow point": "The expensive ones. Fewer, better, and you'll know when you've used one.",
	# the city
	"Armourer's carbine": "Built by the depot's armourer from parts off three guns. Better than any of the three.",
	"Assault shotgun": "A military combat shotgun with a drum. The sort of thing the news said nobody had.",
	"Marksman rifle": "The army's long rifle. The glass alone was worth a house, back when a house was worth something.",
	"Section gun": "A light machine gun off the lorry, belt-fed, and the section it was issued to are the crew who have it.",
	"Duty pistol": "The army's sidearm. Clean, boring, and it works every time, which is the point of it.",
	"Composite helmet": "A modern army helmet, light and hard. It arrived with the lorry, with a name written inside.",
	"Stab plates": "The army's own plates in the army's own carrier. The lorry was full of them. He issues them to people he likes.",
	"Police marksman's rifle": "The firearms squad's own rifle, from the one armoury nobody got into until now. Nothing out here is this good.",
	"Riot squad's shotgun": "The riot squad's own, drum-fed, for crowds. It was made for exactly this.",
	"Officer's revolver": "An officer's revolver, kept clean by someone who expected an inspection. Heavy, slow, final.",
	"Army machine pistol": "A section's machine pistol, out of the lorry. Short bursts, if you can manage them.",
	"Welder's mask": "A welder's flip-down mask. The fire comes off it; so does most of what you'd want to see.",
	"Station helmet, visored": "A fire crew's helmet with the thick visor down. It took heat for a living.",
	"Bomb-squad helmet": "The bomb squad's helmet, with the thick visor. Heavy as a bucket of sand and good for the same reason.",
	"Fireman's tunic": "A station's turnout tunic, the reflective stripes gone grey. Fire is the one thing it was made for.",
	"Lineman's rubber coat": "A lineman's rubber coat, cracked at the elbows. Everything the substation throws goes to ground somewhere else.",
	"Cold-store parka": "The parka from the cold store at the depot, for standing in minus twenty all day. The cold stops at it.",
	"Hazmat suit": "A sealed suit from the works, taped at the wrists. Whatever's in the bottles stays outside it.",
	"Butcher's chainmail": "A butcher's chainmail glove, worked into a vest. Blades slide; nothing goes in.",
	"Bomb suit": "The bomb squad's suit, every plate of it. Nothing moves fast in it, and nothing gets through it either.",
	"Bomb-disposal rig": "The bomb squad's harness, with a pouch for every tool and a few for the hands that shook.",
	"Full bergen": "A soldier's bergen, the big one, frame and all, full. It carries a week; it carries you slower.",
	"Mayor's chain": "The chain of office, out of the Town Hall. Worth a fortune to the Fence and it looks it.",
	"Assault rig": "A soldier's rig, every pouch meant for something. You'll find things to put in them.",
	"Patrol pack": "An army day sack, built for a day that lasts a week. Everything stays dry, which nothing else does.",
	"Hospital kit": "The Hospital's own crash bag. Everything in it is real and most of it is out of date. It still works.",
	"Belt links": "Linked rounds for the section gun, in a tin from the lorry. They don't fit anything else.",
	"Depot rounds": "The army's rifle ammunition, boxed and dated. Better than anything the garage ever loaded.",
	"Incendiary shells": "Shells with something in the wad that keeps burning. What they hit, they set alight.",
	"Incendiary SMG rounds": "Tracer that was never meant for the range. Every third one goes in burning.",
	"Salted rounds": "Rifle rounds dipped in the gritter's salt, the way the rat man said. The hit goes cold.",
	# attachments - optics
	"Red dot": "A dot in a tube. It's where the round goes, give or take the shake.",
	"Torch": "A torch on a rail. They see you first; you see what you're shooting.",
	"Holo sight": "A sight that floats a ring in the air. Fast on the first shot, which is the one that matters.",
	"Telescopic sight": "A glass for distance. Slow up close; patient at range.",
	"Thermal sight": "It sees heat. People are warm; so is the generator they're standing by.",
	"Night optic": "Army night vision, on a mount that fits. The night's been theirs. Not any more.",
	"Laser module": "A laser on the rail. The dot's where the round goes, and they can see it coming.",
	# attachments - muzzle
	"Flash hider": "Keeps the muzzle flash off your night eyes. It doesn't keep the noise off anyone.",
	"Choke": "Tightens a shotgun's spread. Fewer pellets miss.",
	"Compensator": "Ports in the muzzle that fight the climb. Loud for whoever's beside you.",
	"Oil-can silencer": "An oil filter on a thread. It works for a magazine or two, then it's an oil filter.",
	"Muzzle brake": "A proper brake. The gun stays put; your shoulder wishes it hadn't.",
	"Suppressor": "A real suppressor, army issue. The gangs come later, because they heard less.",
	# melee - no rounds, in among them
	"Spiked bat": "A bat from the sports shop with roofing nails through the fat end. The estate's second gun, and the quieter one.",
	"Machete": "From a garden centre, meant for brambles. Light, quick, and it goes through a coat.",
	"Pipe wrench": "A Stillson from a plumber's van. Heavy at the wrong end, which is the right end.",
	"Fire axe": "Off the wall of a stairwell, behind glass that's gone. Made for doors; works on anything.",
	"Bayonet on a stick": "A bayonet from the Barracks on a broom handle, taped. Reach, and a point. Whoever made it had been shown.",
	"Sledgehammer": "Fourteen pounds. Slow, and it only needs the once.",
	"Breaker bar": "A metre of hardened steel from a tyre place. Balanced, somehow; it swings faster than it should.",
	"Knife": "A kitchen knife with the handle taped. Everyone's got one. Most people have used it.",
	"Knuckle duster": "Brass, old, somebody's grandad's. Doesn't look like much until it's in a fist.",
	"Cosh": "A sock with a padlock in it, or a proper one, leather and lead. Quiet. Ends things early.",
	"Tape": "Gaffer tape round the grip. It doesn't slip when your hands are wet, and they will be.",
	"Cord wrap": "Paracord wound tight. Sits in the hand like it was made for it.",
	"Lanyard": "A loop for the wrist. You don't drop it, and you swing freer for knowing you won't.",
	"Nails through it": "Roofing nails, through and bent over. It leaves a mess, and they keep bleeding.",
	"A blade on it": "A length of hacksaw blade bolted along the edge. An afternoon's work, and it shows in them.",
	"Lead in it": "Lead poured into the head. Slower to swing, and nobody's stood up from it yet.",
	# socketables - what the world adds that no gun part can. Fire, frost,
	# poison, shock, salt, wire: things found in a shed, going in a socket.
	"Lighter fluid": "A tin of it. A share of what you put into them goes in burning, and it keeps burning after.",
	"Antifreeze": "From a garage, blue. A share of what you put into them goes in cold. They slow down.",
	"Rat poison": "Council issue, from under a sink. A share of what you put into them stays in them, and it builds.",
	"Car battery": "Still holds a charge. A share of what you put into them goes in live, and while they're twitching everything hurts more.",
	"Road salt": "A bag off a gritter. Packed into the plate's gaps it stops what gets through. Stings in the rain.",
	"Copper wire": "Stripped from the walls, a reel of it. It's money anywhere, so you go home with more of it.",
	"Ported brake": "A competition brake from a sport nobody plays. Flat shooting, every shot.",
	# charms - the one cell kept for luck. What's found with it is rarer,
	# and worth more, and nobody will say why.
	"Lucky penny": "A penny, which is to say nothing. Kept because it was found the day something went right.",
	"Rabbit's foot": "On a keyring. It wasn't lucky for the rabbit, and everyone says so, and everyone keeps it.",
	"St Christopher": "The saint of travellers, on a chain, from a neck. He got whoever it was this far.",
	"Horseshoe nail": "Bent into a ring, from a yard that had horses. The money people's luck, picked up second-hand.",
	"Wedding ring": "Gold, which the Fence would take, worn, which is why it isn't sold. Someone's still coming back for it.",
	"Dog tag": "A name, a number, a blood group. Whoever it was isn't using them. The number holds.",
	"Casino chip": "Five hundred, from the place in town, the night they stopped paying out. Still feels like money in the hand.",
	"Bank's own pen": "On a chain, from the counter. Everything that ever changed hands in the town was signed with one of these.",
	# attachments - magazine
	"Extended magazine": "More rounds before the pause. The pause is when they get you.",
	"Quick magazine": "A magazine with a pull-tab and a taped spare. Out, in, on.",
	"Drum magazine": "Fifty rounds in a drum that jams when it's cold. It's always cold.",
	"Belt box": "A hundred rounds in a box on the side, and the weight of a hundred more.",
	"Hundred-round drum": "The drum that doesn't jam. Someone paid for it with more than money.",
	# attachments - handguard
	"Foregrip": "A handle under the barrel. Steadier, and your hand's not on the hot bit.",
	"Rail handguard": "Rails all round for things to bolt to. Lighter than it looks.",
	"Heat shield": "A shield over a shotgun's barrel. Keeps the heat off, keeps the shots coming.",
	"Bipod": "Two legs for the rifle to rest on. Set up, wait, don't move.",
	"Angled grip": "A grip set forward at an angle. For moving and shooting, which is all you do.",
	# attachments - stock
	"Folding stock": "A stock that folds. Shorter in the car, in the stairwell, in the doorway.",
	"Wire stock": "A wire frame off something improvised, on something improvised. It fits.",
	"Heavy stock": "A solid stock that soaks the kick. Slower to bring up; steadier when it's there.",
	"Cheek riser": "A pad on the stock that puts your eye behind the sight the same way every time.",
	"Recoil pad": "Rubber on the butt. The hundredth shot feels like the first.",
	"Precision stock": "An adjustable stock from a target rifle. Everything set to you. Nobody else can use it now.",
	# the deep bases (10 Oct): what the places past the campaign kept back
	"Security service SMG": "From a government building's gun cupboard, the inventory sheet still taped inside the door.",
	"Close protection SMG": "Carried by people who walked behind people who mattered. Short, quiet, and very well looked after.",
	"Special forces SMG": "Nobody admits it was ever in the country. It's in your hands now, suppressor and all.",
	"Range rifle": "A competition rifle from a club that kept its armoury locked right to the end. Absurdly accurate.",
	"Service rifle": "The army's current rifle, not the one they let cadets touch. Every part of it is somebody's job.",
	"Anti-materiel rifle": "Made for engine blocks. Someone thought a person would do.",
	"Breaching shotgun": "Short, heavy, and made for hinges. It does the same to whatever is behind the door.",
	"Entry shotgun": "A team's door gun, drum-fed. The team didn't make it through the last door.",
	"Combat shotgun": "The military's own, gas-run, and it does not stop until you do.",
	"Bolt-action garage rifle": "A real barrel in a garage-made action. Someone very patient built this, and it shows.",
	"Workshop gauss": "Coils, capacitors and a car battery. Fires nails at something close to the speed of sound. Mostly.",
	"The engineer's piece": "Every good part off every gun the engineer ever stripped, made into one. They signed it.",
	"Demolition bar": "A wrecking bar from a demolition crew, a yard of hardened steel with a claw at each end.",
	"Rescue axe": "A fire crew's rescue axe for getting through cars. It gets through other things.",
	"Door ram": "The riot van's door ram. Two handles, a lot of steel, and the door is never the problem afterwards.",
	"Close quarters pistol": "A compact service pistol from a protection unit. Small, sure, and it always goes off.",
	"Bodyguard's pistol": "Worn under a good suit for twenty years and drawn once. Once was enough.",
	"Special issue pistol": "Not on any list. The serial number was never there to file off.",
	"Legation machine pistol": "From an embassy's strongroom. Technically you're on foreign soil when you fire it.",
	"Embassy PDW": "A personal defence weapon from the same strongroom. The case had a crest on it.",
	"Protection squad PDW": "What the protection squad carried when the cars stopped coming. Small enough to hide, quick enough not to need to.",
	"High-cut helmet": "A modern combat helmet cut high over the ears, rails down the sides. Nobody here makes these.",
	"Special forces helmet": "Lighter than it looks and stronger than anything else you've worn. The mount for the goggles is empty.",
	"CBRN helmet": "A helmet with the respirator built in, from the people who planned for worse than this.",
	"Command helmet": "The heavy one, with the radio built into the shell. The radio's dead; the helmet isn't.",
	"Full EOD helmet": "A bomb tech's full helmet, the visor thick as a door. You hear your own breathing and nothing else.",
	"Military plate carrier": "The army's current carrier, plates front, back and sides. It fits like it was measured for you.",
	"Turnout coat": "A fire crew's coat, the new kind. Made to walk into a burning building and back out.",
	"Special forces plates": "Plates that stop what the others don't, in a carrier that weighs less than it should.",
	"CBRN suit": "A sealed suit for chemical work, taped at every seam. The filter still has days in it.",
	"Heavy armour suit": "Plate on plate on plate. Doors are a problem. Bullets aren't.",
	"Full EOD suit": "The whole bomb suit, not just the jacket. Walking is a decision.",
	"Special forces rig": "Pouches exactly where your hands go, before you know you want them.",
	"Breacher's rig": "Low-slung and quick, made for people who go through doors first.",
	"Command rig": "A rig with a map case and a pouch for everything. It carries more than you'd think a rig could.",
	"Assault pack": "A day pack from the regiment, square and tight, nothing swinging.",
	"Long-range bergen": "Made to carry a fortnight's kit across hills. It'll carry the estate.",
	"Mountain-troop bergen": "A big framed bergen from the mountain troop, built to carry a man's weight again.",
	"Special forces bergen": "The biggest pack there is, and it sits on you like it isn't there.",
	"Signet ring": "A heavy gold signet ring with a crest worn smooth. Someone's family had this for three hundred years.",
	"Regimental medal": "A medal for a war nobody here remembers, polished every Remembrance Sunday until this one.",
	"Gold sovereign": "One gold sovereign, kept for the end of the world. This is it, so it's yours.",
	# the itemisation's (29 Oct): a line for every new base
	"Lump hammer": "A builder's lump hammer, short in the handle and heavy at the business end. Slow to lift, and it doesn't need lifting twice.",
	"Billhook": "For laying hedges, before. A hooked blade on a short handle that opens what it catches.",
	"Bike chain": "Off a bike in the canal, wrapped in tape at one end. It goes where it's swung and takes some of them with it.",
	"Meat cleaver": "From the back of a shut butcher's. Square, heavy at the front, and quick for what it is.",
	"Hot poker": "A fireside poker kept in the coals. It comes out red at the end and nobody wants it near them.",
	"Platelayer's maul": "A railway maul for driving spikes, off the old sidings. Two hands and a long breath between swings.",
	"Cattle prod": "From the mart. A rod with two prongs and a battery in the handle; the cattle knew what it was for.",
	"Cavalry sabre": "Off a regimental wall, the brass still bright. Curved, light, and made for doing this from a horse.",
	"Collier's pick": "A pit pick off a colliery's wall. It went through rock for forty years. Men are softer.",
	"Felling axe": "The forestry's long axe, the edge kept like a razor. One swing to a tree, and the same to anything else.",
	"Civic mace": "The council's mace, carried in front of the mayor on the big days. Silver over steel, and the steel's what counts.",
	"Court sword": "A dress sword from the Lord Lieutenant's case, sharpened since. It was for parades. It isn't now.",
	"Speargun": "From the dive shop by the marina. A rubber band and a steel shaft, and it doesn't care that it's dry.",
	"Compound bow": "A hunting bow with pulleys on the ends, from a sports shop. Draws heavy, holds easy, loses nothing.",
	"Converted air rifle": "An air rifle with a steel liner and a chamber cut for real rounds. It wasn't built for it and it knows.",
	"Slam-fire shotgun": "Two tubes that slide together; the shell meets the pin when you shove. Simple, and nothing to jam.",
	"Punt gun": "A gun for the duck flats, built to sit in a punt, cut down to carry. It fires a handful of shells at once.",
	"Paintball gun": "From the paintball place off the bypass, loaded with ball bearings instead. The hopper holds a lot of them.",
	"Arc-welder gun": "A welder's set wired to a barrel. The rods go out hot and live, and something of the mains goes with them.",
	"Lathe-bored rifle": "A barrel bored out on a works lathe from a length of axle. Slow to load, and each one counts.",
	"Chain-driven repeater": "A bike chain and a motor turn the bolt. It fires as long as the battery does and it isn't quiet about it.",
	"Bench-made autocannon": "Made on a bench over a winter by someone who'd seen one. Big rounds and a kick to match.",
	"Prototype rifle": "From a locked room at the works: drawings, a test rig, and this. It was never finished. It works.",
	"Four-ten": "A light single-barrel for rabbits, the gun a farm lad learns on. Small shells, quick to swing.",
	"Goose gun": "A long-barrelled gun for geese on the estuary. It kicks like a horse and reaches the far bank.",
	"Over-and-under": "A clay gun from the shooting ground, the barrels one over the other. More to fit to it than most.",
	"Ten-bore": "An old ten-bore from a gun room, the bore as wide as a thumb. It doesn't fire so much as land.",
	"Magnum pump": "Magnum shells and a long barrel for the marsh at dawn. Slow, and nothing gets back up.",
	"Pigeon gun": "What the pigeon men used over the decoys. It empties a tube before you've counted.",
	"Rifled slug gun": "A deer gun, the barrel rifled for slugs. It throws one heavy thing a long way and hard.",
	"Marine shotgun": "Stainless, from a ship's locker, built to stand salt water. Heavy shells and a heavy action.",
	"Dragon's-breath gun": "Loaded with the shells that throw fire. The display team used them for the cameras.",
	"Siege shotgun": "For walls that need a door in them. Every shell the size of a jam jar.",
	"Lever-action rifle": "A lever gun from a collector's cabinet. A long tube under the barrel holds more than a bolt gun's box.",
	"Self-loading rifle": "An old service self-loader from a cadet hut. It does the work between shots for you.",
	"Vermin rifle": "A farmer's rifle for crows and foxes, with a long magazine for a long day.",
	"Regimental rifle": "The regiment's own, the one on the recruiting posters. Reliable, quick, and it doesn't ask questions.",
	"Big-game rifle": "A double rifle from a country house, made for things that charge. Heavy rounds and a heavy kick.",
	"Heavy-barrel rifle": "A target rifle with a barrel like a scaffold pole. It doesn't move, so neither does what it hits.",
	"Castle guard rifle": "From the guard at the castle in the city. Polished for the gate; loaded for this.",
	"Wartime SMG": "Stamped steel from a war three wars ago, out of a loft. Slow for an SMG and heavy for its size.",
	"Unmarked SMG": "Made in a garage behind the chip shop. Light rounds, a long magazine, and no serial number at all.",
	"Customs SMG": "The port's customs team kept two in a safe. Heavier rounds than most, and it walks slower.",
	"Navy SMG": "Off a boarding team's rack in the docks. Big rounds for a small gun.",
	"Briefcase SMG": "From a building with no name on the door. It came in a briefcase.",
	"Spiral-mag SMG": "The magazine's a spiral along the top. Fifty rounds before you think about it.",
	"Ministerial SMG": "Carried in the minister's convoy, when there were ministers. Gold on the selector; heavy rounds in the mag.",
	"Derringer": "A little pocket thing from a costume box that turned out to be real. Hold it close.",
	"Pocket pistol": "Small enough for a coat pocket, kept in one for years. Small rounds, quick to fire.",
	"Target pistol": "From the gun club's cabinet. A long barrel, a light trigger, and small rounds that go where they're sent.",
	"Police revolver": "Old issue, kept in a station drawer after the rest went to the automatics. Heavy rounds.",
	"Polymer pistol": "Plastic frame, steel slide, nothing to it. It shoots every time and quickly.",
	"Long-slide pistol": "From the back counter of the gun shop, a long slide and a magazine that sticks out of the grip.",
	"Hunting revolver": "A long revolver made for deer, a scope rail on the top strap. Heavy rounds, each a brick.",
	"Competition pistol": "From the regional final, the trigger worked over by someone who cared. Quick and flat.",
	"Cavalry revolver": "The cavalry's, for when the horse wouldn't do. Heavy rounds and a lanyard.",
	"Ambassador's revolver": "Engraved, cased, given as a gift and never fired at the embassy. It's been fired since.",
	"Field marshal's revolver": "From a glass case in the regimental museum, the provenance on a card. Still oiled.",
	"Broomhandle pistol": "A wartime pistol that fires as long as you hold it, from a souvenir drawer. Small rounds, lots of them.",
	"Stockless SMG": "A small SMG with its stock gone. Slower than the pistols that do this, and heavier rounds.",
	"Three-round pistol": "It fires three at a time, then thinks. A police armoury had a few.",
	"Compact PDW": "A short gun firing small quick rounds, the sort a security firm buys. It's empty in a breath.",
	"Select-fire pistol": "A service pistol with a switch for full auto and a long magazine to feed it.",
	"Folding PDW": "It folds into a box the size of a book. Unfolded, it isn't a book.",
	"Escort PDW": "The escort team's, from the convoy's lead car. Short and heavy for its size.",
	"Consular PDW": "From the consulate's strongroom, still in its foam. Never once fired in there.",
	"Overcoat machine pistol": "Carried under a good coat in a city that had envoys. The coat's gone.",
	"Crown PDW": "The protection officers' own, for when the car stopped where it shouldn't. Gilt on the case.",
	"Catapult": "A forked stick and a bit of rubber, the kind every lad had. Ball bearings now, not stones.",
	"Screwdriver": "A long flat-head from the van, ground to a point. Quick in and out.",
	"Bike lock": "A D-lock, the heavy kind, swung by the shackle. It kept a bike for ten years. It'll keep you.",
	"Hatchet": "A camping hatchet from the outdoor shop's last shelf. Light, and it bites.",
	"Zip gun": "A pipe, a block of wood, a rubber band and a nail. Crude, loud, and you'll want to be near.",
	"Extendable baton": "Flicks out to three times its length. The security firm's, when there was a firm.",
	"Commando dagger": "A thin double-edged dagger from a veteran's drawer. It was made for close, and it is.",
	"Wheel brace": "The cross-shaped wheel brace from a garage wall. Four ends and every one of them hurts.",
	"Pen gun": "A fountain pen that fires a pistol round. Someone made it for a reason and kept it in a drawer.",
	"Spring gun": "A keeper's spring gun, the kind set on a tripwire for poachers, cut down to hold. Heavy bolts and no bang.",
	"Beekeeper's hat": "From the allotments' hives. The veil keeps the stings out; it keeps out the spray too.",
	"Caving helmet": "From the caving club's store: a light on the front and a strap that holds. Searches go quicker with your hands free.",
	"Scrum cap": "Padded, from the rugby club's lost property. It stops the cuts more than the knocks.",
	"Comms headset": "A padded headset off a security desk, still picking up the town. You hear them before they turn up.",
	"Bump helmet": "A light shell with rails for a lamp. No good against a round, all right against a cupboard door.",
	"Thermal headset": "A thermal monocle on a strap mount. Warm bodies show white a street away.",
	"Respirator helmet": "A helmet with a mask built in, from a works that made something it shouldn't have. Filters still good.",
	"Night-sight helmet": "Night sights on a swing arm. The dark corners of a site stop being dark.",
	"Ghillie hood": "A hood of hessian strips over a light shell. They walk past what they can't see.",
	"Arctic helmet": "From the cold-weather troop, lined and sealed. Nothing gets in at the neck.",
	"Search-team helmet": "A search team's, with a camera and a lamp. Every corner gets a proper look, and quickly.",
	"Surveillance helmet": "Sensors front and back, and an earpiece that never stops. Nothing comes at you unannounced.",
	"Spraying overalls": "Rubberised overalls from the farm's spray store. Whatever they put on the fields runs off them.",
	"Slash-proof jacket": "A cut-resistant lining under a plain coat, what the security guards got issued. Blades skid off it.",
	"Foundry coat": "Silver and stiff, from the foundry. It was made to stand next to molten steel.",
	"Low-profile vest": "Thin plates under a shirt, the kind you'd never know was there. Light enough to run in.",
	"Prison officer's vest": "Soft armour from the prison, worn under the white shirt. It goes under anything.",
	"Skeleton carrier": "A plate carrier stripped to the frame: plates, straps, nothing else. Nothing to slow you.",
	"Arctic smock": "A padded white smock over plates, from the cold-weather store. The wind doesn't find a way in.",
	"Plainclothes vest": "What the detectives wore under their jackets. Light, flat, and it stops the lot.",
	"Tailored body armour": "Armour sewn into a suit by a tailor who asked no questions. It fits like it was made for you; it wasn't.",
	"State protection vest": "The protection officers' vest, the best there was, made to be worn all day without anyone knowing.",
	"Chainmail shark suit": "Steel mesh from the aquarium's dive store, made so a shark bites and gives up. Blades do the same.",
	"Gardening apron": "A canvas apron with deep pockets, from the allotments. Whatever's in it comes out quick.",
	"Body warmer": "A padded gilet from a market stall. It takes a bit of the first knock before you do.",
	"Lifeguard's vest": "From the leisure centre pool, shut. Built for getting things out quick.",
	"Tweed waistcoat": "A shooting waistcoat, tweed thick as a carpet. The first of each lot spends himself on it.",
	"Door staff vest": "From the club door: a padded vest with a radio clip. It's taken a few nights' first swings.",
	"Quick-release rig": "A chest rig with pull tabs on every pouch. A med's out before you've looked for it.",
	"Public order rig": "Padded panels and pouches from the riot van, made for a night of things being thrown.",
	"Load carrier": "A wide chest rig with pouches two deep. Holds more than you'd want to carry.",
	"Slick rig": "Flat pouches on a low frame, nothing sticking out. Every med sits under your hand.",
	"Air ambulance vest": "From the helicopter crew, built round getting things out quickly. It still smells of the hangar.",
	"Pathfinder rig": "The forward team's light rig, everything where the hand falls on it.",
	"Counter-terror rig": "A black rig with plates behind the pouches. The first rounds of a fight go into it.",
	"Hostage-rescue rig": "Built for minutes that count. The pouches open themselves, near enough.",
	"Shield-team rig": "The shield man's rig, armoured where the shield doesn't reach.",
	"Desert patrol rig": "From the long-range desert troop, made to carry water and get at it quickly. Meds now.",
	"Royal escort rig": "The escort's rig, plated, crested, worn on the long drives. It takes the first of anything.",
	"Feed sack": "A woven feed sack off the farm, carried over the shoulder. You stuff more in it than it looks.",
	"Tartan shopper": "Somebody's nan's, the wheels long gone. Bottomless, as she'd tell you.",
	"Daysack": "A small army daysack, everything to hand. A search goes quicker with less to dig through.",
	"Dumpy bag": "A builders' bulk bag, cut down and given straps. Takes a tonne, they say.",
	"Messenger bag": "A courier's bag that opens with one hand. In, out, gone.",
	"Sailor's bag": "A navy sea bag, the long canvas tube kind. Everything goes in the top.",
	"Mule pack": "A framed load-carrier made for the hills, with a waist belt that takes the weight.",
	"Sniper's drag bag": "A long padded bag made to drag through grass. It opens flat and shows the lot.",
	"Swag bag": "A burglar's bag, black, soft, and bigger inside than the job needed.",
	"Search-and-rescue pack": "The rescue team's pack: lights, straps, and everything in a pocket you can find blind.",
	"Security van bag": "From an armoured van. Made to carry the takings; it'll carry anything worth taking.",
	"Clamshell pack": "It opens down the back like a suitcase. Searching's quick when the bag's already open.",
	"Ingot sack": "A canvas sack the bars went in at the depot, stitched to take weight.",
	"Alpine pack": "A climber's pack, narrow and light, made to sit high and get out of the way.",
	"Strongroom bag": "From a safe-deposit room, the bag the boxes were emptied into. Bigger than you'd think.",
	"Freefall pack": "Made to be jumped with from a plane. It goes wherever you do and doesn't argue.",
	"Wax-sealed bag": "A red bag sealed with a crown in wax. Nothing taken out of it was ever counted twice.",
	"Box of matches": "Half full, the striker worn smooth, kept dry in a breast pocket for years.",
	"Old spark plug": "Out of his first car. He kept it on the dashboard of every car since.",
	"Gold tooth": "A gold crown, the tooth long gone. It's paid for itself twice over at the pawnbroker's.",
	"Barber's razor": "A barber's razor, folded in a horn handle. His grandfather's.",
	"Pocket watch": "A railwayman's watch, still keeping time. It'll fetch something at the pawnbroker's.",
	"Brass canary": "A brass canary from a pub's mantelpiece, where the pit's last one used to hang. It knew the air before the men did.",
	"Gold cufflinks": "Initials not yours. Good gold, and the Fence knows it.",
	"Ice-hockey puck": "Signed, from the rink in the city, the night they won the league. Cold to the touch still.",
	"Dragon brooch": "A red dragon in enamel, from a coat lapel at the rugby. Worn to every international.",
	"Diamond tiepin": "One stone on a gold pin, from a board member's tie. Worth more than the board.",
	"Glass insulator": "Green glass off an old telegraph pole. It kept the wire off the pole for a hundred years.",
	"Gold cigarette case": "Engraved, from an officers' mess, nothing in it but the smell. Solid, and it'll fetch.",
	"Sword knot": "The gold tassel off an officer's sword, kept when the sword was handed in.",
	"Uncut diamond": "A rough stone the size of a fingernail, from a safe in the city. It looks like glass, until it doesn't.",
	"Apothecary's vial": "A stoppered blue bottle from the old chemist's back shelf, the label in Latin. Don't open it.",
	"Gardening gloves": "Rubber-palmed, from the allotment shed. Nothing slips out of them.",
	"Woolly gloves": "Knitted by somebody's mam. Warm hands are nimble ones.",
	"Work gloves": "Canvas and leather, from a building site. The trigger finger's worn through.",
	"Rigger gloves": "Thick hide, from the scaffold yard. Nothing slips in them.",
	"Cycling mitts": "Fingerless, padded at the palm, from the bike shop. Light as anything.",
	"Driving gloves": "Thin leather with holes at the knuckles. A light touch on the trigger.",
	"Leather gloves": "Good black leather from a shut department store. They hold what they're given.",
	"Goalkeeper gloves": "From the club shop, big in the palm and light on the hand.",
	"Shooting gloves": "From the shooting ground, the trigger finger bare. Every shot a touch quicker.",
	"Roofer's gloves": "Rubber-dotted, for slates in the rain. A magazine's easier than a slate.",
	"Racing gloves": "Fireproof, from the track's pit lane. Light, and made for a quick change.",
	"Tactical gloves": "Black, knuckle-padded, from a surplus shop. A thin palm and a quick finger.",
	"Cut-resistant gloves": "Steel thread through the weave, from the glass works. They grip and they don't tear.",
	"Fell-runner's gloves": "Thin and windproof, for the hill races. You forget they're on.",
	"Armourer's gloves": "Thin and oil-stained, from the armoury bench. Fingers that know where everything is.",
	"Riot gauntlets": "Armoured on the back, grippy in the palm. The shield squad's.",
	"Pilot's gloves": "Thin flame-proof leather from an aircrew locker. Made for small switches and quick ones.",
	"Stalker's gloves": "Light and thin, the palm textured, for a long wait and a quick finish.",
	"Firefighter's gloves": "Heavy, heatproof, and they hold onto a hose under pressure. A magazine's nothing.",
	"Paratrooper's gloves": "Made to jump in. Light, tight, and they never come off.",
	"Close-combat gloves": "Padded knuckles and a bare-feeling trigger finger. For close, and quick.",
	"Flight-deck gloves": "From an aircraft carrier's deck crew, made to grip in the wet and the wind.",
	"Abseiling gloves": "Leather-palmed, for the rope down the side of a building. Every move quicker for it.",
	"Counter-sniper gloves": "From the rooftop team. They fire on the breath out, and they don't wait for the next.",
	"EOD gauntlets": "The bomb squad's: thick on the back, fine in the fingers.",
	"Dress uniform gloves": "White cotton from the parade ground. They've never been dirty and they're quick.",
	"Special forces gloves": "The best there is, made for the trigger and nothing else.",
}


# ------------------------------------------------------------------ the Yard's own

## The log's words for the moments the sim marks.
## The sets' pieces: whose they were.
const SET_PIECES := {
	"Council hi-vis": "Orange, with the crest and a name in marker on the back. He was in Highways. He's not now.",
	"Council hard hat": "Yellow, the council's, with the sticker of the last inspection. It passed.",
	"Council rucksack": "Issued for the tools, used for the sandwiches. There's a tin of something under the lining.",
	"Council lanyard": "The pass still works, if there's anywhere left to swipe it. The crews treat it like it does.",
	"Ambulance rig": "Green, with the pouches in the order they teach you. Whoever wore it had the order by heart.",
	"Green overalls": "Ambulance green, one knee gone. Somebody got up because of these.",
	"Crew helmet": "White, with the trust's name on it, scratched through where someone took it off a wall.",
	"Branch blazer": "Navy, with the pin. They're still staff, in their heads. In this, so are you.",
	"Cashier's pen": "His own, from his own till. He counted everything twice. So will you.",
	"Branch holdall": "The bag the cash went to the van in. It's seen more money than anyone alive.",
	"Station tunic": "The tunic from the last station that answered a call. The name tape is still on it.",
	"Station helmet": "A fire helmet with the station's number on the front, scorched to the edges.",
	"Breathing set": "A breathing set with the cylinder and the mask, the one thing in town that keeps bad air out.",
	"Issue helmet": "Issued to a name, and the name's still on the band. He signed for it.",
	"Issue carrier": "Plates in, straps right, a blood group on the shoulder. It did its job once.",
	"Issue bergen": "The big one, packed by the book. The book's in the top pocket.",
	"Issue rifle": "Zeroed, cleaned, signed for. The Quartermaster would want it back. He can ask.",
	"Carpet knife": "The fitter's own, blade snapped back fresh. He never cut a straight line in his life.",
	"Fitter's knee pads": "Forty years on his knees, and a pair of these. They go on over anything.",
}

## What happens on a run, once in a while.
const EVENTS := {
	"convoy": "A convoy comes through. Lorries, and a crew riding on them. They stop.",
	"convoy_notes": "They're carrying notes. For now.",
	"trapped": "Someone under a fallen ceiling, alive. You get them out. They say they'll look you up if you're ever short a runner.",
	"cache": "A locked cabinet, council green. It gives to a crowbar.",     # not the Bench's tools: it opens with the Workshop shut (13 Oct)
	"cache_shut": "A locked cabinet, council green. Nothing on you opens it. Another time.",
}

## The odds to clear a fight, in the Yard's words: the headline on a site's
## card, the figure small beside it. Bands from the top down.
const FIRST_GUN := "Behind the till, wrapped in a bin bag: %s, and a box of %s."     # the Garden Centre's first clear (17 Oct)
const ODDS := [[0.9, "Safe"], [0.75, "Likely"], [0.6, "Risky"], [0.4, "A coin toss"], [0.2, "Long odds"], [0.0, "A bad idea"]]


static func odds_words(odds: float) -> String:
	for band in ODDS:
		if odds >= float(band[0]):
			return band[1]
	return ODDS.back()[1]


const SKY := {
	"night": "night", "day": "day", "rain": "rain", "fog": "fog", "clear": "clear",     # nouns, all four (the language pass: "fog down" was flavour among values)
	"fresh": "Fresh",
	# a site's crates kept between runs (27 Oct): what's left, the best named; picked clean and the next crate's wait
	"left": "%d crate%s left", "left_top": "%s +%d", "clean": "Picked clean · a crate in %s", "clean_short": "Clean · %s", "clean_tiny": "Clean",
}
## The first ten minutes: what's next, in the voice, on the Runner card and
## in the log when it changes. Nobody says objective.
const NEXT := {
	"past": "The runner's waiting in Training. Ask what they were, before.",
	"first": "The Allotments are out past the ring road. Go and see what's left.",
	"supplies": "There's medical supplies in the stash. The Clinic's medic wants them: hand them in.",     # 28 Oct, Matt: as a ready contract's
	"site": "%s hasn't been cleared. That's where the next lot are.",
	"head": "%s is behind %s. Arm him from the site's card when the odds hold.",
	"lot": "The %s's done with. %s is open, if you're asking.",
	"done": "The town's yours. The Radio's the game now: three papers make a signal.",
	"level": "The next area opens at level %d. The sites you have still pay the XP.",     # not named: it isn't known yet (20 Oct)
}
const NEXT_SHORT := {
	"past": "Pick a past in Training",
	"first": "Next: the Allotments",
	"supplies": "Supplies for the Clinic",
	"site": "Next: %s",
	"head": "Arm %s on the Map",
	"done": "The Radio's the game now",
	"level": "Next area at level %d",
}
const NOTES := {
	"zones": "Heads down open the next",
	"zones_done": "Deepest clear on each",
	"patch": "The runner's patch",
	"generator": "Keeps the Pitch going while you're gone",
}

## The estate recycles: what was lost turns up on someone, and comes off him.
const RECYCLE := {
	"wearing": "One of them has %s's %s.",                # who, the piece
	"has": "One of them has %s. The Fence said someone would want it.",   # the unique
	"off": "The %s came off him. %s's, by the name in the collar.",         # the piece, who
	"off_unique": "%s came off him. Sold once, found twice.",           # the unique
	"listed": "Someone on the estate will be wearing it by the week's end.",
}

## The crew (21 Oct): a class swapped at camp.
## The broken builds' one line a run, the first stack (21 Oct): something's catching, never what or why.
const COMBOS := {
	"embers": "The fire's catching on itself.",
	"clean_kills": "The cold's doing the work now.",
	"flatline": "The heart's going again.",
	"opened_for_good": "They're not closing up.",
	"live_load": "The current's building.",
	"drilled": "The drill's taking over.",
}


const CREW := {
	"swap": "The %s stands down; the %s goes out next, at level %d.",
}
## A class arrives (24 Oct, milestone 8: skills.md §6 and §11): who unlocks them, the log's line and the card's tag
## until then.
const OPENS_AFTER := "Opens after"     # a locked class's card, over the head that opens it (24 Oct)
## A class's card when it opens (25 Oct, Matt: "a story beat for every class unlock"): two lines in their own voice, back
## at camp after the head falls (the Drifter after Kev's first story). The takes are Matt's (art/intro/classes/<voice>.mp3,
## docs/design/class_cards.md); "cues" go in with them, the lines on the clock till then.
## The Issue (25 Oct): the day the money changes, and after.
const ISSUE := {"log": "The Issue: the town runs on the Issuer's money now. Your pile came out at %s.",
	"printed": "The Issuer printed again: %s, and every price up with it.",
	"kicker": "THE ISSUE", "title": "Its value is as stated", "sub": "The Issuer's down. The town runs on his money now.",
	"line": "\"Everything you've got is worth what I say it is. Today, that's this.\"",
	"pile": "Your pile: %s, %s notes, and kit and goods worth %s", "rate": "The Issue: 0.8 × the square root of your pile", "came": "What came out: %s; your kit sells at ×%s of the day's rate, as the pile did",
	"tiles": [["Prices follow the money", "More fiat about, more it costs"], ["His rate moves", "The Fence buys at it"], ["Burn it", "Hand fiat back: prices fall"]],
	"go": "Take it", "hint": "Tins and notes are gone · the Issuer's at the Fence"}
const ISSUED := {"not_yet": "Not before the Issue", "on_a_run": "Not on a run", "short": "Short of fiat", "no_room": "No room in the stash",
	"bought": "From the Issuer: %s, for %s.", "tab": "The Issuer", "head": "Issued kit", "rate": "HIS RATE TODAY", "circ": "IN CIRCULATION", "prices": "PRICES",
	"burn": "Burn %s", "burn_line": "Out of circulation: prices x%.2f to x%.2f", "burn_go": "Burn", "said": "\"Its value is as stated.\"",
	"want": "The County wants %d issued piece%s worn", "wear_at": "Wear at level %d", "burn_nothing": "Nothing in circulation to burn",
	"burn_sure": "Burn %s"}
const STAMP := {"not_yet": "Not before the Issue", "on_a_run": "Not on a run", "not_kit": "Only a piece of kit", "issued": "Issued already",
	"done": "Stamped already", "no_issue": "Nothing issued for this slot", "short": "Short of fiat", "log": "Stamped for the County: %s, for %s.", "tag": "Stamped · counts as issued for the County",
	"tag_short": "Stamped"}
const CLASS_CARD := {"kicker": "A NEW CLASS IN TRAINING", "go": "To Training", "hint": "Click or Space · the class waits in Training",
	"edge": "The class", "trees": "Its trees"}
const CLASS_CARDS := {
	"Paramedic": {"face": "paramedic", "title": "The Paramedic", "sub": "Out of the Clinic, after the Gamekeeper fell", "place": "The Clinic", "voice": "paramedic",
		"heads": ["Knows where it hurts", "Proper dressings", "Patches herself up"],     # the tiles' headlines (27 Oct, Matt: "something more interesting than the class")
		"lines": ["Half of what's in the vet's bag works on people. I checked.", "The doctor keeps the Clinic. Somebody has to go out to them."]},
	"Doorman": {"face": "doorman", "title": "The Doorman", "sub": "Free of the Carpet Man's door, now he's down", "place": "The retail park", "voice": "doorman",
		"heads": ["Hits like a door", "Twelve years standing", "In no hurry"],     # the tiles' headlines (27 Oct, Matt: "something more interesting than the class")
		"lines": ["Twelve years on his door. Near the end he paid me in rugs.", "Nobody got past me then. Nobody gets past me now."]},
	"Scrapper": {"face": "scrapper", "title": "The Scrapper", "sub": "Out of the Bank's basement, after the Manager", "place": "The bank", "voice": "scrapper",
		"heads": ["Knows where to look", "Nothing left behind", "Bin-bag guns"],     # the tiles' headlines (27 Oct, Matt: "something more interesting than the class")
		"lines": ["I kept the Bank's lifts running till there was nothing left to lift.", "Give me a bin bag and an afternoon. I'll give you a gun."]},
	"Recruit": {"face": "recruit", "title": "The Recruit", "sub": "Walked out of the Barracks with the Quartermaster gone", "place": "The barracks", "voice": "recruit",
		"heads": ["Drilled", "Never tires", "What he was taught"],     # the tiles' headlines (27 Oct, Matt: "something more interesting than the class")
		"lines": ["Nobody signed me out. I took the stores and I walked.", "I can drill you. I can drill the lot of you. Show me where."]},
	"Drifter": {"face": "drifter", "title": "The Drifter", "sub": "Found on the road, in Kev's first story", "place": "The services", "voice": "drifter",
		"heads": ["Quick hands", "Hard to pin down", "Never stops"],     # the tiles' headlines (27 Oct, Matt: "something more interesting than the class")
		"lines": ["Kev found me on the ring road, walking the way the lorries go.", "I don't stop anywhere long. Lucky for you, I'm quick."]},
}
const CLASS_UNLOCK := {
	"Paramedic": {"who": "the Gamekeeper", "line": "Training offers the Paramedic. The doctor's apprentice. The doctor keeps the Clinic; she goes out."},
	"Doorman": {"who": "the Carpet Man", "line": "Training offers the Doorman. The Carpet Man's old bodyguard."},
	"Scrapper": {"who": "the Manager", "line": "Training offers the Scrapper. The Bank's repair man."},
	"Recruit": {"who": "the Quartermaster", "line": "Training offers the Recruit. He walked out of the Barracks with the stores."},
	"Drifter": {"who": "Kev's first story", "line": "Training offers the Drifter. Found on the road."},
}
const YARD := {
	"runner_refund": "The last runner's training went with them: %d point%s back to spend, and a past to pick for the next.",
	"set": "The Pitch is set. One runner, a hammer, the estate outside.",
	"paragon_lost": "The crew's %d paragon levels went with them; the next runner starts at level 50.",
	"dead": "Dead in %s. The kit's gone with them. %s",       # site, then the next runner arriving
	"first_run": "Out for the first time. Nobody past the ring road knows the Pitch yet.",
	"hardcore_lost": "Hardcore: the Pitch goes with the runner. Someone else will have the Pitch by morning.",
	"campaign": "The Outskirts, the Estate, the Town, the City. The Pitch's name is known in all of them. Now it's a question of how far in you go.",
	"lorry": "The Lorry's Load is yours. Kev's story's told; the Radio keeps talking, and the signals go on for as long as you do.",
}


## `code`: a paper's code line first (the item's card); the drawer's story leaves it off (it tells the estate, not the radio).
## A paper's words (15 Oct): its flavour, and its code once the Radio's open to read it; before, the flavour alone for
## every paper, code or none (16 Oct, Matt: one said "from before", one "a code" - the card's garbled chips say it now).
static func paper_words(base: String, radio_open: bool) -> String:
	for p in PAPERS:
		if p["name"] == base:
			if not p.has("code") or not radio_open:
				return str(p["words"])                  # before the Radio, every paper alike: the chips are the code, garbled (16 Oct)
			return str(p["code"]) + " " + str(p["words"])
	return item_words(base)



static func item_words(base: String, code := true) -> String:
	if ITEMS.has(base):
		return ITEMS[base]
	if SET_PIECES.has(base):
		return SET_PIECES[base]
	if base == DEEDS["name"]:
		return DEEDS["words"]
	if GATE_ITEMS.has(base):
		return GATE_ITEMS[base]
	for p in PAPERS:
		if p["name"] == base:
			return (str(p["code"]) + " " if p.has("code") and code else "") + str(p["words"])     # where its code is, first (13 Oct, Matt: the papers carry the radio codes)
	return ""


static func site_line(site: String, depth: int) -> String:
	var s: Dictionary = SITES.get(site, {})
	if s.is_empty():
		return ""
	var lines: Array = s["depths"]
	return lines[clampi(depth - 1, 0, lines.size() - 1)]


static func site_cleared(site: String) -> String:
	return SITES.get(site, {}).get("cleared", "")


## A line from a list, by a count, so the same visit gives the same words.
static func rotate(lines: Array, n: int) -> String:
	if lines.is_empty():
		return ""
	return lines[n % lines.size()]


## Which log lines earn a toast, and in what tone: "" for a plain one, "none" for the rest.
## A line's last short form for a toast, when it has no full stop, colon or comma to cut at (13 Oct: "One of them is in
## the last Doorman's hand-me-down nail gun." ran past its toast): the piece goes, the person stays. "" when none.
static func short_line(line: String) -> String:
	var lead: String = RECYCLE["wearing"].get_slice("%s", 0)
	var at: int = line.find("'s ", lead.length()) if line.begins_with(lead) else -1     # the person's, not a "butcher's chainmail"'s
	if at > lead.length():
		return line.substr(0, at) + "'s kit."
	return ""


static func toast_tone(line: String) -> String:
	if line.begins_with("Found: ") or line.begins_with("And a second: ") or line.contains(" Found: "):
		return "good"
	if line.begins_with("Level ") or line.begins_with("Not today") or line.begins_with("The Pitch moves") or line.begins_with("The Pitch's trade"):
		return "good"
	for b in BOSSES:
		if line.begins_with(b + " comes out") or line.begins_with(b + " is down") or line.begins_with(b + ": "):
			return "warn" if not line.begins_with(b + " is down") else "good"
	if line.begins_with("One of them ") or line.contains(" came off him."):
		return ""
	if line.begins_with("Dead in "):
		return "bad"
	if line.begins_with(RADIO_LEAD):
		return "none"                           # the radio line under the top bar plays it (13 Oct): no toast
	return "none"


## The wounds (19 Oct, Matt: three at most, one an area, the Clinic the cure).
const WOUNDS := {
	"took": "%s: %s. %s −%d%% until the Clinic sees to it (%d of 3)",
	"full": "Hurt again, and nowhere left to hurt: three wounds is the most a runner carries",
	"treated": "%s seen to: %s back",
}

## The Pitch circle (24 Oct): an element shut till a Pitch point opens its starter.
const ELEMENT_SHUT := "shut"
const ELEMENTS_NOTE := "Each opens with a Pitch point"

## The fight's breakdown (24 Oct, the endgame chase): the sources that aren't a gun or a skill.
const BREAKDOWN := {"dot:fire": "Fire", "dot:poison": "Poison", "dot:bleed": "Bleed", "dot:shock": "Shock", "dot:frost": "Frost",
	"grenades": "Grenades", "fists": "Bare hands", "rule:arsonists_rig": "The Arsonist's Rig", "rule:issuers_revolver": "Repeat hits · The Issuer's Revolver", "other": "Everything else"}
## What hit you, by type: frost on the runner is a chill (skills.md §11).
const TOOK_WORDS := {"physical": "Physical", "fire": "Fire", "frost": "Chill", "poison": "Poison", "shock": "Shock", "bleed": "Bleed"}
const TEMPER := {"done": "Tempered: item level %d → %d", "no_piece": "Only kit you wear tempers", "mythic": "A mythic takes no temper",
	"raise_first": "Item level +3 first", "short": "Needs %s scrap", "no_grow": "Nothing on it grows", "too_high": "Past the level you can wear", "price": "%s scrap · %s", "job": "Temper +1"}
const RUN_HOME_CLEAN := "%s picked clean, nothing more before time's up: home with the pack"
## The Mint's card before the Issue (the third review's A1(a)): what the win would turn the camp's money into.
const MINT_WARN := {"forms": ["Beat him: you come out at ≈ƒ%s", "Comes out ≈ƒ%s", "≈ƒ%s"],
	"tip": "Beat him and the town goes on his money. What you hold now, tins, notes and kit, comes out at about ƒ%s, plus what the run brings, and your kit sells at ×%.2f of its worth after."}
const RUN_GANG_LATE := ["after time's up", "too late"]     # a gang due after the clock runs out (the first review's 15)
const GREED := {"short": "Greed +%d%%", "tip": "Greed: +%d%% quality and +%d%% loot, from the patrols beaten since the site was cleared. Each one more adds to it."}
const FENCE_SURE := "Sell %d"     # a rarity row's Sell, pressed once (25 Oct): the second sells; how many it will (the second review)
## Every ask-twice press, one form (Matt, 26 Oct): what goes, then "press again"; "Again?" where there's no room.
const ASK := {"again": "%s – press again", "short": "Again?"}
## The pack as a grid (27 Oct): a find with no place, a piece let go where it won't lie.
## A crate tile clicked opens next (27 Oct): the crates' head's aside, long to short.
const CRATE_PICK := {"long": "%s · click one: next", "short": "click one: next"}
const PACK := {"no_room": "No room in the pack", "wont_lie": "It won't lie there", "move": "Drag a piece to move it; R or right-click turns it"}
const FIGHT_BUTTON := "The fight ›"
## Loadouts (24 Oct): on screen a saved set of kit is a Kit, never a loadout (the glossary).
const LOADOUTS := {"name": "Kit %d", "empty": "Empty: save what's worn here", "worn_now": "worn now", "ready": "ready to wear",
	"short": "gone: %s", "wear": "Wear", "save": "Save worn", "save_sure": "Replace it", "worn": "Kit %d on", "worn_short": "Kit %d on; missing: %s",
	"skill": "1 skill", "skills": "%d skills", "rig": "%d in the rig", "wear_tip": "Puts on its kit, tops up its rig and slots its skills"}
const BUILD := {"copy": "Copy build", "paste": "Paste build", "copied": "Build code copied", "bad": "That isn't a build code", "old": "A build code from an older version: the web has changed since",
	"out": "Not while the runner's out", "class": "A %s build: swap to them in Training first", "short": "Short of tins: the reset is %s",
	"title": "A %s build · %d perks · %d skills", "plan": "Resets every perk for %s, then trains %d of %d", "plan_free": "Trains %d of %d perks, no reset",
	"missed": "%d can't be trained yet", "go": "Retrain into it", "cancel": "Cancel", "done": "Retrained: %d of %d perks", "reset_sure": "Reset trees for %s", "ring_sure": "Reset the ring for %s", "pitch_sure": "Reset the Pitch for %s", "element_sure": "Reset %s for %s", "reset_copied": "Trees reset: the build code was copied first, to paste back"}
const COLLECTION := {"button": "The collection ›", "title": "The collection", "sub": "Every runner's, for the record · it gives no power", "close": "Close",
	"uniques": "Uniques found", "mythics": "Mythics found", "sites": "Sites with every mark", "classes": "Classes at level 50", "order": "The order's three beaten", "sets": "Sets complete",
	"of": "of %d", "grid_head": "Every unique · the found ones in colour, the rest by slot", "sites_head": "Sites · a mark at levels %s",
	"unfound": "? · %s", "level": "level %d", "none": "not yet"}
const FIGHT_TITLE := "The fight · %s"
const FIGHT_SUB := "%s fighting · %d kills · %d gangs after the clear"
const FIGHT_HEADS := ["Damage", "dmg/s", "Damage taken", "Damage stopped", "Meds used"]
const FIGHT_SRC := "Your damage, by where it came from"
const FIGHT_TOOK := "What hit you"
const FIGHT_SKILLS := "Your skills"
const FIGHT_NONE := "No skills used"
const FIGHT_CLOSE := "Close"

## The true pinnacles' fights on screen (24 Oct): his chips "On them", the Registrar's "On you".
const ORDER_CHIPS := {"shield": "Shield · break it in %d s", "stunned": "Stunned %d s", "taped": "Red tape · −50%% gun damage · %d s", "sealed": "A skill stamped",
	"printed": "%d printed men"}
const SKILL_SEALED := "Stamped"
const SKILL_SEALED_TIP := "Stamped by the Registrar: it can't fire for %d s"

## Patterns at the Workshop (24 Oct, the endgame chase).
const PATTERNS := {"not_unique": "Only a unique has a pattern; a mythic has none", "not_stashed": "Take it off first: only a stashed unique breaks", "out": "Not while the runner's out",
	"broken": "%s broken down: its pattern is kept at the Workshop", "no_pattern": "Pick a pattern", "has_one": "It has a power already: one a piece",
	"too_plain": "Only Rare or better takes a pattern", "wrong_slot": "That pattern goes on: %s", "wants": "Short of: %s",
	"wants_n": "Short of: %d %s", "short": "Short of tins", "put_on": "%s now carries %s's pattern",
	"tab": "Patterns", "break_head": "1 · Break a unique down", "kept_head": "Patterns kept · %d", "put_head": "2 · Put it on a Rare or better, same slot",
	"break": "Break it down", "break_sure": "Gone for good", "gone": "The unique goes for good; its power stays here as one pattern", "put": "Put it on", "kept_note": "One use each. They sit here, not in the stash.",
	"put_note": "Spends the pattern and the costs above; it can't come off",
	"none_kept": "None kept yet: break a unique down", "pick_unique": "Pick a unique in the stash", "pick_rare": "Pick a Rare or better, same slot"}

## The loot filter (24 Oct, the endgame chase).
const LOOT_RULES := {"scrapped": "Loot rules scrapped %d find%s on the way in: +%d scrap", "special": "Uniques, set pieces, mythics",
	"any_rarity": "Any rarity", "or_better": "%s or better", "upto": "Up to %s", "any_slot": "any slot", "tier": "a T%d+ affix", "tier_top": "a T%d affix",
	"button": "Loot rules · %d on", "button_none": "Loot rules", "title": "Loot rules", "sub": "Checked top down when a run comes home · the first that fits wins",
	"add": "Add a rule", "on": "Rules: on", "off": "Rules: off", "close": "Close",
	"note": "Keep: never sold or binned. Highlight: an amber edge, kept too. Scrap: scrapped on the way in. No rule fits: as before.",
	"keep": "Keep", "highlight": "Highlight", "scrap": "Scrap", "delete": "Delete", "delete_sure": "Delete it", "edit_head": "Rule",
	"rarity": "Rarity", "slot": "Slot", "gun": "Weapon", "affix": "Best affix", "then": "Then", "none": "No rules yet: add one", "any": "Any", "kinds": "Uniques, set pieces, mythics",
	"kind": "Kind", "plain": "Everything else", "from": "From %s ▾", "to": "To %s ▾", "up": "↑", "up_tip": "Move up: checked before the one above",
	"act_tip": "Press to change: keep, highlight, scrap", "never_tip": "Never scrapped by a rule", "body_tip": "Helmet, armour, gloves, charm", "bags_tip": "Rig, backpack",
	"full": "8 rules at most", "pick": "Pick a rule to change it", "row_on": "On", "row_off": "Off"}

## The repeat runs (29 Oct, docs/design/trips.md 1-2): the Map's button and its shut reasons, the away card on the rail,
## the log, the report card when they're back. Drafts for the language pass.
const REPEAT := {"button": "Run it ×%d", "button_short": "×%d", "button_full": "Run till the stash is full", "button_full_short": "Till stash full", "button_full_tiny": "Till full",
	"shut_site": "Site not open yet", "shut_away": "The runner is away", "shut_out": "The runner is out", "shut_trait": "Pick a trait first",
	"shut_new": "Not cleared yet", "shut_head": "Untick Head first", "shut_convoy": "Untick Convoy first", "shut_full": "The stash is full", "shut_reading": "Reading the odds",
	"shut_odds": "Odds %d%% at full HP, needs 90%%", "note": "Run it ×%d · %s", "note_full": "Run till full · %s",
	"set_off": "Away to %s: %s, nobody watching", "times": "%d runs", "till_full": "till the stash is full",
	"calling": "Bringing them back after this run",
	"bail": "Bailed out of %s under 25%% HP: the pack's finds lost, the kit kept",
	"sold": "Sold at the gate: %d find%s, %s",
	"back": "Back from %s: %d run%s, %d bail%s",
	"why_first": "First gun", "why_deeds": "Deeds", "why_mythic": "Mythic", "why_issued": "Issued", "why_unique": "Unique", "why_paper": "Paper",
	"why_opens": "Opens a room", "why_rounds": "Rounds", "why_meds": "Meds", "why_supplies": "Supplies", "why_set": "Set piece", "why_socket": "Socketable",
	"why_list": "Loot rule", "why_upgrade": "Upgrade",
	"stub": "After the Quartermaster", "gives": "×%d runs · %d%% XP", "gives_full": "Till the stash is full · %d%% XP",
	"away_head": "AWAY", "away_where": "%s · Run %d of %d", "away_where_full": "%s · Run %d · Till full", "away_where_full_short": "%s · Run %d", "away_resting": "Resting between runs", "away_resting_first": "Resting before the first run", "away_kit": "The kit's with them",
	"away_left": "About %s left", "away_left_full": "Till the stash is full", "bails_none": "No bails", "bails": "%d bail%s",
	"bring": "Bring them back", "coming": "Back after this run",
	"badge_away": "Away", "badge_back": "Back",
	"title": "Back from %s", "sub": "%d run%s · %s", "cleared": "%d cleared", "bailed": "%d bail%s", "wounds": "%d wound%s",
	"kills": "Kills", "kept": "Kept", "tins": "Tins in all", "sold_row": "Sold at the gate", "scrap": "Scrap", "mats": "Materials", "xp": "%d%% XP", "levels": "Level",
	"levels_same": "%d, no change", "levels_up": "%d → %d", "sold_val": "%d for %s", "none": "None",
	"each": "Each run ▾", "each_open": "Each run ▴", "run_line": "Run %d · %s · %d kill%s, %s", "run_cleared": "Cleared", "run_bail": "Bail", "run_out": "Out of time, a bail", "run_home": "Not cleared",
	"kept_head": "KEPT AND WHY", "kept_none": "Nothing new kept",
	"again": "Run it again", "done": "Done", "more": "%d more", "not_shown": "Runs 1–%d not shown",
	"ended_done": "Ended: every run done", "ended_full": "Ended: the stash is full", "ended_back": "Ended: brought back", "ended_bails": "Ended: two bails in a row", "ended_blocked": "Ended: %s"}

## Kev's wagers (29 Oct, docs/design/endgame_activities.md row 1): drafts for the language pass.
const WAGERS := {"button": "Wagers", "button_on": "Wagers · %d on", "button_n": "Wagers · %d", "title": "Kev's wagers", "kicker": "%s · The next run there", "kicker_sig": "%s · This signal's run",
	"kev": "Kev: \"Fancy a flutter? Do it the hard way and I'll see you right.\"", "line": "%s for %s", "take": "Take it", "taken_btn": "Taken ✓",
	"foot": "They go on the next run there, never a repeat run. The odds don't count them.", "foot_sig": "They go on this signal's run. The odds don't count them.", "done": "Done",
	"taken": "Kev's wager taken: %s", "left": "Kev's wager dropped: %s", "on": "Kev's wagers on: %s", "paid_notes": "Kev's wager paid: +%d note%s"}

## The expeditions (29 Oct, docs/design/trips.md 3-4: the design's "trips"; "Expeditions" on screen, the glossary's "a
## trip out" being a run): the Map's tab, the send card, the report, the Bunkhouse's hands. Drafts for the language pass.
const EXPEDITIONS := {"tab": "Expeditions", "tab_short": "Far places", "tab_back": "Expeditions · %d back", "tab_back_short": "Expeditions · %d", "tab_map": "Back to the Map", "tab_map_short": "The Map",
	"title": "Expeditions", "progress": "%d of %d out", "progress_back": "%d out · %d back", "far_head": "THE FAR PLACES", "art": "No painting yet",
	"level": "Level %d", "pays": "Pays %s", "time": "%s", "quota_chip": "%s wanted", "quota_chip_short": "%s wanted",
	"quota_head": "THIS WEEK'S QUOTA", "quota": "%s: +20–50%% on them and %s", "quota_short": "%s: %s", "quota_met": "Met this week: back next week", "quota_met_short": "Met this week",
	"quota_shut": "The quotas come with More bunks", "quota_left": "%s left this week",
	"q_mythic": "a %d%% chance of a mythic", "q_gamble": "the Fence's gamble restocked", "q_set": "a set piece", "q_issued": "an issued piece", "q_rebuild": "a rebuild at half",
	"q_socketed": "a socketed unique", "q_named": "%s", "q_missed_mythic": "no mythic this time", "q_missed": "nothing named this time",
	"k_meds": "meds", "k_supplies": "the Clinic's supplies", "k_tokens": "gamble tokens", "k_parts": "gun parts", "k_army": "army surplus", "k_materials": "rebuild materials",
	"k_fuses": "fuses", "k_socketables": "socketables", "k_charms": "charms", "k_socketed": "socketed kit", "k_uniques": "uniques", "k_papers": "papers",
	"slot_pick": "Uniques for: %s ▾", "slot_short": "%s ▾",
	"crew_head": "THE PARTY", "lead": "Lead: %s, level %d", "lead_short": "%s %d", "lead_none": "No other runner", "lead_away": "Every other runner's out",
	"lead_why": "Another class leads: build one in Training",
	"hand": "%s T%d · %s", "hand_short": "%s T%d", "hand_none": "No hand free", "hand_none_hired": "Hire one at the Bunkhouse", "hand_shut": "Comes with %s", "hand_add": "Add a hand",
	"cargo_head": "CARGO · %d SLOTS", "cargo_empty": "Empty ▾", "cargo": "%s ▾", "cargo_amt": "%s · %s", "amt_all": "All",
	"back_head": "WHAT COMES BACK", "back": "About %s' worth: %s", "back_none": "Nothing: no cargo, no return",
	"quality": "+%d%% loot quality", "time_line": "%s out · %s in wages", "time_line_free": "%s out · no wages",
	"risk_head": "THE RISK: THE CHANCE OF A BAD ROLL", "risk": "%d%%", "risk_word": "%d%% · %s", "risk_safe": "Safe", "risk_risky": "Risky", "risk_bad": "A bad idea",
	"risk_odds": "%d%% odds", "risk_hold": "%d%% chance of a hold-up", "risk_loss": "A bad roll loses 25–100% of the return",
	"stakes": "A bad roll hurts the hands sent unless a nurse goes · walking away from a hold-up loses them for good",
	"stakes_short": "Without a nurse a bad roll hurts them; a walk-away loses them",
	"send": "Send them", "send_short": "Send",
	"shut_open": "After the Quartermaster", "shut_lead": "Pick a lead", "shut_selected": "The runner you play stays: another leads", "shut_lead_out": "%s is out on an expedition", "shut_cargo": "Load some cargo",
	"shut_reading": "Reading the odds", "shut_at_once": "%d out at once: the Bunkhouse for more", "shut_wage": "Short of %s for the wages",
	"shut_hand": "%s can't go: hurt or out", "shut_hands": "%d hand%s at most", "shut_out": "The runner's on a run", "shut_held": "Short of %s",
	"out_head": "OUT · %d OF %d", "out_none": "None out", "out_line": "%s · %s", "out_left": "%s left", "out_back": "Back", "out_held": "Held up",
	"report": "Report", "out_slot_shut": "Comes with %s",
	"rep_title": "Back from %s", "rep_held_title": "Held up: %s", "rep_sub": "%s led · %d hand%s · %s of cargo", "rep_sub_alone": "%s led alone · %s of cargo",
	"rep_bad": "A bad roll: %d%% of the return lost", "rep_good": "No losses", "rep_quota": "Quota met: +%d%% and %s", "rep_quota_only": "Quota met: +%d%%",
	"rep_got_head": "WHAT CAME BACK", "rep_hands_head": "THE HANDS", "rep_hand_lv": "%s · level %d", "rep_hand_up": "%s · level %d → %d",
	"rep_hurt": "%s · hurt, sits out %s", "rep_nothing": "Nothing came back", "rep_lead_xp": "%s · +%s XP",
	"rep_held_line": "They're holding the party and the cargo. Three ways out:",
	"fetch": "Go after them", "fetch_note": "The runner goes to %s, against its head: win, and they're home with the return as rolled; lose, and they're still held",
	"fetch_note_short": "The runner goes to %s, against its head", "fetch_out": "Going after them: the runner's at %s",
	"pay": "Pay %s", "pay_note": "Half of what's coming back: they're home with the rest", "walk": "Walk away", "walk_again": "Walk away? Press again",
	"walk_note": "The cargo's lost and %s leave for good", "walk_note_none": "The cargo's lost", "take": "Take it", "later": "Later",
	"no_room": "No room in the stash: %d sold to the Fence for %s",
	"tokens": "%d gamble token%s: a free gamble each at the Fence", "halves": "%d rebuild%s at half",
	"sent": "%s out to %s with %s of cargo", "back_log": "Back from %s: %s", "held_log": "Held up: %s - the party's waiting on you",
	"paid": "Paid %s: the party's home from %s", "walked": "Walked away from %s: %s gone", "walked_none": "Walked away from %s",
	"fetched": "Got the party back from %s", "fetch_failed": "The party's still held: %s",
	"hands_head": "THE HANDS", "pool_head": "FOR HIRE", "roster_head": "ON THE ROSTER · %d OF %d", "hire": "Hire", "let_go": "Let go", "let_go_again": "Let go? Press again",
	"new_faces": "New faces (%s)", "better_faces": "Better faces (%s)", "hands_shut": "The pool of 6 comes with A hand along",
	"hands_closed": "After the Quartermaster", "pick_hand": "Pick a hand to hire or let go", "wage": "%s wage an expedition",
	"roster_full": "The roster's full: let one go", "hired": "%s hired: %s", "let_go_log": "%s let go", "pool_empty": "Nobody left: try New faces",
	"better_shut": "Better faces come with Two along", "roster_none": "Nobody hired yet: pick one above",
	"hand_lv": "Level %d", "hand_tier": "T%d · level %d", "hand_out": "Out", "hand_hurt": "Hurt", "hand_free": "Ready",
	"short_cash": "Short of %s"}

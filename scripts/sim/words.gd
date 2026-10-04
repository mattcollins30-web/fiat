extends RefCounted
## Everything the game says that isn't a number: the people's lines, the
## sites' lines, the papers, the uniques' pasts, the ending, and a line for
## every item. The voice is docs/design/narrative.md's: British, flat, dry;
## the money words everywhere; nobody explains the collapse; the worst
## things said shortest. Words only - no rules live here.


# ------------------------------------------------------------------ the people

## The fence. `visit` lines rotate by how often you've been; the rest fire
## on the action and show in the pick panel.
const FENCE := {
	"visit": [
		"Everything's for sale. That's the one thing that hasn't changed.",
		"I pay cash. Don't ask where I get it.",
		"You bring, I price. The price is the price.",
		"The crew in the bank buy off me too. Different prices.",
		"I knew your last one. Didn't know them long.",
		"Nothing's worth what it was. Some things are worth more.",
	],
	"sold": ["That'll do.", "I've had worse through here.", "Someone will want that.", "Cash. Count it if you like."],
	"bought": ["It's yours. It was someone's.", "No returns.", "Mind how you go with that."],
	"shelf": "More shelf. Same stock, more of it.",
	"contract": ["That's what I asked for. Here's what I said.", "Good. Someone's waiting on these.", "Done. I'll have another for you."],
	"insured": "I'll hold the paper on it. If they don't come back, you do.",
	"paid_out": "Insured. The fence held the paper; the kit's back in the yard. The runner isn't.",
	"mate": ["He doesn't come in. He sends them with me. Don't ask.", "Notes. He still thinks they're money. So do the crews."],
	"town": "You've been past the retail park, then. The bank's got a crew. They'll know your name before you know theirs.",
	"deeds": "I'll find a buyer. Someone always wants to be owed.",
	"papers": "Someone collects these. Don't ask me why.",
}

## The medic.
const MEDIC := {
	"visit": [
		"Sit down. You're letting the cold in.",
		"I stayed on when the pay stopped. Somebody had to.",
		"The clinic's a caravan. It was a caravan before.",
		"I don't ask what they were doing. I can usually tell.",
	],
	"treated": ["Hold still.", "That's the third time with that arm.", "You'll do.", "Keep it dry. Nothing round here is dry."],
	"fit": "Nothing wrong with you that I can charge for.",
	"hurt": "Sit down before you fall down.",
	"new_runner": "Another one. The last one didn't listen either.",
	"shelf": "More on the shelf. It won't be enough.",
}

## What the runner was, before: a line each, and how they turn up at the yard.
const PASTS := {
	"Poacher": {"was": "Kept the village in rabbits when the shops shut. Knows where everything hides.",
		"arrives": "A poacher turns up at the yard, rifle wrapped in a coat. Doesn't say where from."},
	"Doorman": {"was": "Worked the door of a club that closed the week after. Still stands like it's open.",
		"arrives": "A doorman turns up at the yard. Big, polite, looks at your hands first."},
	"Paramedic": {"was": "Stayed on the ambulances after the pay stopped. Left when the fuel did.",
		"arrives": "A paramedic turns up at the yard, still in the green. Asks where the kit is."},
	"Scrapper": {"was": "Stripped the estate's own cars for copper. Knows what everything's worth, to the penny.",
		"arrives": "A scrapper turns up at the yard with a trolley. Prices the lock-up before saying hello."},
	"Drifter": {"was": "Walked in from somewhere worse. Doesn't say where; doesn't plan to stay.",
		"arrives": "A drifter turns up at the yard. Light pack, good boots, already looking at the road."},
}


# ------------------------------------------------------------------ the places

## A line a depth on every site - what you learn by going further in - and
## the line the log gives the first clear. Index by tier, then depth − 1
## (the last line holds for every depth past it).
const SITES := {
	"Ransacked streets": {
		"depths": [
			"The first streets off the ring road. Doors open, curtains gone.",
			"Someone's taken the copper out of the walls.",
			"A car on bricks with a child seat still in it.",
			"They've started on the roof tiles.",
			"Nothing left here but the people who stayed. They're the ones with guns.",
		],
		"cleared": "The streets are quiet. They'll fill again; they always do.",
	},
	"The parade": {
		"depths": [
			"Six shops and a chippy. The chippy went first.",
			"The bookmaker's shutters are the only ones still down.",
			"Someone's living in the launderette. Someone else wants to.",
			"The off-licence has been emptied twice. The second time by its owner.",
			"The post office safe is open. It was empty when the money went.",
		],
		"cleared": "The parade's yours for an hour. Nobody's shop now.",
	},
	"The retail park": {
		"depths": [
			"Big sheds, big car park, nothing in the car park.",
			"The DIY place is the armoury round here. It's where the nail guns came from.",
			"The supermarket's freezers went off in the first week. Nobody's been in since.",
			"There's a crew in the carpet warehouse. They've got the carpet.",
			"The petrol station's forecourt is a market on Sundays. Not this Sunday.",
		],
		"cleared": "The retail park's cleared. The road to the town is open, which is not the same as safe.",
	},
	"The pleasure park": {
		"depths": [
			"The wheel still turns when the wind's right.",
			"Somebody kept the arcade's generator going for the lights. Then for the heat.",
			"The log flume's a reservoir now. They guard it.",
			"The ghost train's where they keep what they take.",
			"The man who ran the park is still here. He's the one up on the wheel.",
		],
		"cleared": "The park's quiet. The wheel keeps turning; nobody's on it.",
	},
	"Shopping centre": {
		"depths": [
			"Two floors and a food court. The escalators are stairs.",
			"The jeweller's was done the first night. Nobody wanted the watches.",
			"The upper floor is a camp. The children's clothes shop, for the children.",
			"The bank's crew come here for stock. They pay in paper.",
			"The security office has the tapes from the night it happened. Nobody's watched them.",
		],
		"cleared": "The centre's cleared. The camp upstairs didn't come down to look.",
	},
	"The services": {
		"depths": [
			"A motorway services. The lorries stopped here when the diesel did, and so did the drivers.",
			"The lorry park is a town now. Every trailer's a house; every cab's a shop.",
			"The fuel's long gone. What's in the tanks is what they fight over.",
			"The drivers kept the CB sets. They heard your yard before they saw it.",
			"The last lorry in was the army's. It isn't here any more. They know where it went.",
		],
		"cleared": "The services are quiet. The trailers are still houses; nobody's opening the doors.",
	},
	"The hospital": {
		"depths": [
			"The hospital kept going longer than anything. Then it kept going without the lights.",
			"A&E is the gate. They triage who comes in, and they're not doctors any more.",
			"The pharmacy was emptied by the staff, by rota, to be fair about it.",
			"Theatres on the third floor. Someone's still operating. Not on who you'd think.",
			"The paramedic's old crew are here. They kept the ambulances. They kept the uniforms.",
		],
		"cleared": "The hospital's cleared. It still smells of what it was.",
	},
	"The barracks": {
		"depths": [
			"The depot the lorries never reached. The gate's open; the gatehouse isn't.",
			"The armoury's been issued. The quartermaster signs for everything, still.",
			"They drill. Properly, in the mornings. Then they go out and take things.",
			"The stores are full of what the town's been missing. He's rationing it.",
			"He's got the lorry. It's in the shed with the engine running, every day, for the heater.",
		],
		"cleared": "The barracks are cleared. The stores are open. He signed nothing.",
	},
	"The bank": {
		"depths": [
			"A branch like any other. Steel shutters, a hole in the wall for cash.",
			"The crew call themselves staff. Some of them were.",
			"They've got the tills running off a generator. Nothing to put through them.",
			"The vault's behind the manager's office. The manager's behind the vault.",
			"They're not guarding money.",
		],
		"cleared": "The bank's taken. The vault was never locked.",
	},
}


# ------------------------------------------------------------------ the papers

## Found lying about: a line of the before, one cell each, worth pennies to
## the fence. The only place the old world speaks.
const PAPERS := [
	{"name": "A council tax reminder", "value": 2, "words": "Final notice. The council it's from doesn't exist."},
	{"name": "A P45", "value": 2, "words": "Someone's last day at the sorting office. Signed, dated, kept."},
	{"name": "A betting slip", "value": 3, "words": "An accumulator on the football. Four of the five came in."},
	{"name": "A pawn ticket", "value": 3, "words": "A wedding ring, for a week's shopping. Never collected."},
	{"name": "A bank statement", "value": 2, "words": "In credit, to the penny, the week before."},
	{"name": "A food bank voucher", "value": 2, "words": "Three days' worth. Stamped by the church."},
	{"name": "A mortgage offer", "value": 3, "words": "Approved. Fixed for five years."},
	{"name": "A school report", "value": 2, "words": "'Tries hard.' The school's in the shopping centre now."},
	{"name": "A lottery ticket", "value": 4, "words": "Unchecked. The draw was the Saturday after."},
	{"name": "A wage slip", "value": 2, "words": "A month's wages. The number means nothing; the name's been underlined."},
	{"name": "An eviction notice", "value": 3, "words": "Fourteen days. They stayed."},
	{"name": "A boarding pass", "value": 4, "words": "One way. The flight went; the ticket didn't."},
	{"name": "A parking ticket", "value": 2, "words": "Issued the morning of. The car's still there."},
	{"name": "A Christmas list", "value": 3, "words": "In a child's hand. Most of it's in the retail park."},
]

## The deeds: what the bank was holding. Dropped once, when the bank is
## first cleared; two cells; the ending is what you do with it.
const DEEDS := {
	"name": "The deeds", "value": 5000,
	"words": "Every mortgage on the estate, in a fire box. The crew held the bank for this.",
	"found": "In the vault: a fire box. The paper on every house on the estate.",
	"burned": "Burned in the yard. Nobody on the estate owes anybody. Let it be done.",
	"sold": "Sold on. Someone, somewhere, is owed the estate now. Let it be done.",
	"held": "The yard holds the paper on every house on the estate. Let it be done.",
}


# ------------------------------------------------------------------ the bosses

## The crews' heads: a line when they come out, a line when they go down.
const BOSSES := {
	"The carpet man": {"out": "He's brought the whole warehouse.", "down": "The warehouse crew go quiet. Somebody else will have the car park by morning."},
	"The manager": {"out": "He's in a suit. It fits.", "down": "The staff stop. Nobody's told them what to do next, and he isn't going to."},
	"The quartermaster": {"out": "He signs for you.", "down": "The depot's unlocked. Nobody's counting any more."},
}


# ------------------------------------------------------------------ the uniques

## Who they were.
const UNIQUES := {
	"Grandad's shotgun": "Sixty years in a cupboard under the stairs. He kept it for rabbits. He never said whose grandad.",
	"The Postman's bag": "He kept the round going for a year after the last letter. People gave him things to carry.",
	"The Doorman's jacket": "The club shut; he stood on the door of the shopping centre instead. Nobody told him to.",
	"Lucky cap": "Covered in stickers from every site it's been on. It outlasted three owners. That's the luck.",
	"The van's spare": "The carpet man's. Under the driver's seat for the one time, which was you.",
	"Underlay": "His own jacket, lined with the good underlay, the kind people paid extra for. Stops a lot.",
	"The manager's coat": "A good coat over a better vest. He wore it to the vault every morning. He had standards.",
	"The branch pistol": "The pistol from under the counter at the bank, kept for a robbery that never came. Then everything was one.",
	"The quartermaster's rifle": "Issued to himself, signed for by himself. Zeroed every Sunday.",
	"Issue webbing": "The last set the depot issued, to the last man who signed for it. The pouches are full of paperwork.",
	"The van keys": "The carpet man's. The van's long gone, but the keys were in his pocket, and they're the kind that start anything.",
	"The manager's pen": "His own, not the counter's. Everything he signed, he signed with this, right up to the last day. It still works.",
	"The quartermaster's ledger": "Every round, every blanket, every name, in his hand. What's signed for is yours. He'd say so himself, now.",
	"The lorry's load": "What the convoy was carrying, in the end. Not food. Notes, baled, and the tarp they were under. Nobody said what for.",
	"The council's weed burner": "Parks department. A gas bottle on a frame and a lance with a roar in it. It was for the pavements. It still is, in a way.",
	"Jump leads": "Red and black, from a boot. Clipped to the right thing, the first one they touch passes it on.",
	"The rat man's bag": "The council's rat man had a bag, and whatever's in the bottom of it never came out. It's in everything you put in there now.",
	"The butcher's steel": "Not the knife, the steel: the rod he ran the knife down. Anything cut with what it's touched doesn't close.",
	"The gritter's hopper": "The yellow hopper off the back of the gritter, cut down and strapped on. Everyone near you is standing in January.",
	"The sparky's gloves": "Rubber, to the elbow, tested and stamped. He never got a belt in thirty years. Neither will you.",
	"The quartermaster's manual": "Every piece of kit the army ever issued, and how to use it, in a binder. He'd read it. Now so have you.",
	"A blue plaque": "Off a wall in town: somebody lived here. It makes you a listed building. Nothing on you works but the listing.",
	"The lollipop lady's sign": "STOP, on a pole, scratched. She held it up for forty years and nobody went through. They still don't.",
	"The bookie's pencil": "Short, flat, chewed. He used it to work out who'd lose. Twice as lucky, half as paid.",
	"The float": "The milk float's keys and the battery to run it. Quiet, quick, carries anything, and there's no room on it for a first aid kit.",
	"Nan's cardigan": "Knitted. It stops nothing and it fixes everything, which is what it did before.",
	"The dinner lady's ladle": "Stainless, the size of a face. One serving, one at a time, and you feel better for every one. Don't ask her for a plaster.",
	"A traffic warden's hat": "Nobody liked him. People see the hat and one of them goes home. The rest of them pay the fine.",
	"The vicar's thermos": "Tea, strong, always. Whatever's burning on you he'd call warmth. Don't stand near the fire for long, mind.",
	"The scout leader's whistle": "One blast and everyone falls in; two and they go home. The gangs have heard it before.",
	"The sergeant's whistle": "Everyone comes at once, which was the point, and you hit like a section because that was the point too.",
	"The electrician's tester": "A screwdriver with a bulb in it. Touch something and it stays lit until it's dead. The bulb's not bright.",
	"The gamekeeper's flask": "Sloe gin, with something in it for the pheasants. What they give you, you give back.",
	"The caretaker's keys": "Every door on the estate on one ring. Something's always open and something's always happening.",
	"The lorry driver's log": "Hours, miles, stops, in biro. It's worth notes to the right people, and the fence insures anyone who's got one, for free, because he wants it.",
}


# ------------------------------------------------------------------ the items

## A line for every base: what it is, where it came from, in the one voice.
const ITEMS := {
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
	"Automatic shotgun": "An army gun, the kind the news used to show. It arrived with the crew in the bank.",
	# rifles
	"Semi-auto .22": "A plinking rifle from a garden shed. It's killed more rabbits than people, but not by much now.",
	"Old .303": "A service rifle from a war two wars ago, kept oiled by a man who talked about it. Still hits what it's pointed at.",
	"Stalking rifle": "A deer rifle, walnut and blued, from an estate with a different meaning of the word.",
	"Army bullpup": "The army's own, with the army's own problems. It came off a lorry that never reached the barracks.",
	"AR-pattern rifle": "Built from parts that came in the post, before the post. Light, fast, hungry.",
	"Battle rifle": "A full-calibre service rifle. Heavy, loud, and nothing it hits gets up to argue.",
	"Scoped .308": "A target rifle with a glass on it. The man who owned it shot paper on Sundays. Then he didn't.",
	"Sniper rifle": "The real thing, from somewhere that shouldn't have lost it. Whoever had it before you didn't miss.",
	# SMGs and carbines
	"Workshop SMG": "A box magazine, a tube, and a trigger. The workshop's bestseller, which tells you about the market.",
	"Police carbine": "An armed-response carbine, from a response that never arrived.",
	"Army SMG": "A soldier's close-quarters gun. Compact, quick, and someone's unit patch is still on the sling.",
	"Belt-fed SMG": "Someone's idea of a joke that worked. A belt in a bag, a gun on a strap, and nothing left standing.",
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
	"Army helmet": "Issue kevlar, with a cover in a camouflage for a country this isn't.",
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
	"Full plate carrier": "Front, back and sides, pouches, the lot. The crew in the bank wear these. Now so do you.",
	"Light plates": "The thin plates, the slim carrier, the kind you wear under a coat. For people who need to move.",
	# rigs
	"Bum bag": "Three pockets round your waist. It's where people kept their money. It's where you keep what matters.",
	"Fishing vest": "Twelve pockets, half of them for flies. A kit here, a box there; you'll stop noticing the hooks.",
	"Paramedic's rig": "Green, reflective, and laid out so the hands know where the kit is before the head does.",
	"Chest rig": "Pouches across the chest, army surplus from when there was an army to be surplus to.",
	"Webbing": "A belt and straps, worn light. Everything to hand and nothing in the way.",
	"Medic's harness": "A full harness with the pouches for the job. The last one to wear it is why the clinic has a shelf.",
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
	"Bandage": "A roll of it. Pressure, time, and don't look.",
	"First aid kit": "A green box from a kitchen wall. Most of what's in it is plasters. The rest is what you want.",
	"Field dressing": "Army issue, vacuum packed. Tear, press, hold. It's quicker than it sounds.",
	"Trauma kit": "A paramedic's bag with the good things in it. Clotting, splints, a mask for the worst of it.",
	"Surgeon's kit": "What the clinic would use, in a roll. If you're using it yourself, it's that bad.",
	# ammo
	"Nails": "A box from the DIY place. The gun doesn't care which end goes first.",
	"Hardened bolts": "Bolts someone's tempered on a forge. They go through what nails bounce off.",
	"Shells": "Birdshot, mostly, from a cabinet with the key still in it.",
	"Slugs": "One lump of lead a shell, for things bigger than birds. Everything's bigger than birds now.",
	"Rifle rounds": "Mixed calibres in a biscuit tin. Enough of them fit.",
	"Match rounds": "Target ammunition, boxed and counted by someone careful. They fly straighter; so will you.",
	"SMG rounds": "Boxed 9mm, the most common round in the country, which is why the SMGs are.",
	"SMG hollow point": "Police issue 9mm. They open up inside. That's the whole description.",
	"Pistol rounds": "A bag of mixed pistol ammunition from a drawer that had a pistol in it once.",
	"Pistol hollow point": "The expensive ones. Fewer, better, and you'll know when you've used one.",
	# the city
	"Armourer's carbine": "Built by the depot's armourer from parts off three guns. Better than any of the three.",
	"Assault shotgun": "A military combat shotgun with a drum. The sort of thing the news said nobody had.",
	"Marksman rifle": "The army's long rifle. The glass alone was worth a house, back when a house was worth something.",
	"Section gun": "A light machine gun off the lorry, belt-fed, and the section it was issued to are the crew who have it.",
	"Issue pistol": "The army's sidearm. Clean, boring, and it works every time, which is the point of it.",
	"Composite helmet": "A modern army helmet, light and hard. It arrived with the lorry, with a name written inside.",
	"Issue plates": "The army's own plates in the army's own carrier. The lorry was full of them. He issues them to people he likes.",
	"Assault rig": "A soldier's rig, every pouch meant for something. You'll find things to put in them.",
	"Patrol pack": "An army day sack, built for a day that lasts a week. Everything stays dry, which nothing else does.",
	"Hospital kit": "The hospital's own crash bag. Everything in it is real and most of it is out of date. It still works.",
	"Belt links": "Linked rounds for the section gun, in a tin from the lorry. They don't fit anything else.",
	"Depot rounds": "The army's rifle ammunition, boxed and dated. Better than anything the garage ever loaded.",
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
	"Choke": "Tightens a shotgun's spread. Fewer pellets miss. Shotguns only.",
	"Compensator": "Ports in the muzzle that fight the climb. Loud for whoever's beside you.",
	"Oil-can silencer": "An oil filter on a thread. It works for a magazine or two, then it's an oil filter.",
	"Muzzle brake": "A proper brake. The gun stays put; your shoulder wishes it hadn't.",
	"Suppressor": "A real suppressor, army issue. The gangs come later, because they heard less.",
	# melee - no rounds, in among them
	"Spiked bat": "A bat from the sports shop with roofing nails through the fat end. The estate's second gun, and the quieter one.",
	"Machete": "From a garden centre, meant for brambles. Light, quick, and it goes through a coat.",
	"Pipe wrench": "A Stillson from a plumber's van. Heavy at the wrong end, which is the right end.",
	"Fire axe": "Off the wall of a stairwell, behind glass that's gone. Made for doors; works on anything.",
	"Bayonet on a stick": "A bayonet from the barracks on a broom handle, taped. Reach, and a point. Whoever made it had been shown.",
	"Sledgehammer": "Fourteen pounds. Slow, and nothing it lands on gets up to argue.",
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
	"Wedding ring": "Gold, which the fence would take, worn, which is why it isn't sold. Someone's still coming back for it.",
	"Dog tag": "A name, a number, a blood group. Whoever it was isn't using them. The number holds.",
	"Casino chip": "Five hundred, from the place in town, the night they stopped paying out. Still feels like money in the hand.",
	"Bank's own pen": "On a chain, from the counter. Everything that ever changed hands in the town was signed with one of these.",
	# attachments - magazine
	"Extended magazine": "More rounds before the pause. The pause is when they get you.",
	"Quick mag": "A magazine with a pull-tab and a taped spare. Out, in, on.",
	"Drum magazine": "Fifty rounds in a drum that jams when it's cold. It's always cold.",
	"Belt box": "A hundred rounds in a box on the side. SMGs only, and even then.",
	"Hundred-round drum": "The drum that doesn't jam. Someone paid for it with more than money.",
	# attachments - handguard
	"Foregrip": "A handle under the barrel. Steadier, and your hand's not on the hot bit.",
	"Rail handguard": "Rails all round for things to bolt to. Lighter than it looks.",
	"Heat shield": "A shield over a shotgun's barrel. Keeps the heat off, keeps the shots coming. Shotguns only.",
	"Bipod": "Two legs for the rifle to rest on. Set up, wait, don't move. Rifles only.",
	"Angled grip": "A grip set forward at an angle. For moving and shooting, which is all you do.",
	# attachments - stock
	"Folding stock": "A stock that folds. Shorter in the car, in the stairwell, in the doorway.",
	"Wire stock": "A wire frame off something improvised, on something improvised. It fits. Improvised only.",
	"Heavy stock": "A solid stock that soaks the kick. Slower to bring up; steadier when it's there.",
	"Cheek riser": "A pad on the stock that puts your eye behind the sight the same way every time.",
	"Recoil pad": "Rubber on the butt. The hundredth shot feels like the first.",
	"Precision stock": "An adjustable stock from a target rifle. Everything set to you. Nobody else can use it now.",
}


# ------------------------------------------------------------------ the yard's own

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
	"Issue helmet": "Issued to a name, and the name's still on the band. He signed for it.",
	"Issue carrier": "Plates in, straps right, a blood group on the shoulder. It did its job once.",
	"Issue bergen": "The big one, packed by the book. The book's in the top pocket.",
	"Issue rifle": "Zeroed, cleaned, signed for. The quartermaster would want it back. He can ask.",
	"Carpet knife": "The fitter's own, blade snapped back fresh. He never cut a straight line in his life.",
	"Fitter's knee pads": "Forty years on his knees, and a pair of these. They go on over anything.",
}

## What happens on a run, once in a while.
const EVENTS := {
	"convoy": "A convoy comes through. Lorries, and a crew riding on them. They stop.",
	"convoy_notes": "They were carrying notes. They were, anyway.",
	"trapped": "Someone under a fallen ceiling, alive. You get them out. They say they know a yard.",
	"cache": "A locked cabinet, council green. The bench's tools open it.",
	"cache_shut": "A locked cabinet, council green. Nothing on you opens it. Another time.",
}

## The estate recycles: what was lost turns up on someone, and comes off him.
const RECYCLE := {
	"wearing": "One of them is in %s's %s.",                # who, the piece
	"has": "One of them has %s. The fence said someone would want it.",   # the unique
	"off": "%s came off him. %s's, by the name in the collar.",         # the piece, who
	"off_unique": "%s came off him. Sold once, found twice.",           # the unique
	"listed": "Someone on the estate will be wearing it by the week's end.",
}

const YARD := {
	"set": "The yard is set. One runner, a nail gun, the estate outside.",
	"dead": "Dead in %s. The kit's gone with them. %s",       # site, then the next runner arriving
	"first_run": "Out for the first time. The estate doesn't know the yard yet.",
	"hardcore_lost": "Hardcore: the yard goes with the runner. Someone else will have the lock-up by morning.",
	"campaign": "The estate, the town, the city. The yard's name is known in all three. Now it's a question of how far in you go.",
	"moved": "The yard moves. A new lock-up on a new estate, the same radio, the same list on the wall. The name came with it.",
	"trade": "The yard's trade came too: %s, and anyone who runs for the yard learns the lot of it.",
}


static func item_words(base: String) -> String:
	if ITEMS.has(base):
		return ITEMS[base]
	if SET_PIECES.has(base):
		return SET_PIECES[base]
	if base == DEEDS["name"]:
		return DEEDS["words"]
	for p in PAPERS:
		if p["name"] == base:
			return p["words"]
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

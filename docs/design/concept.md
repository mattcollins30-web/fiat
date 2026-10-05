# Fiat — the idler cut

*Let it be done.* 1 October 2026. Mundane Studios.

FIAT's systems — the Diablo loot loop, the Path of Exile tree and map modifiers, Tarkov's loadout risk, five
classes that shape gear rather than gate it, the camp — in the idler format, on the Storeys menu shell. The
isometric action game was deferred as too big a first project; this is the same design with the real-time
combat and the art budget taken out. If it plays, it will want art, more than Greenhorn did: loot wants to be seen.

## What's ours

Idle Directive exists and is a Tarkov idler almost one to one. The parts that are ours and that the slice has
to prove: the setting — a Britain fractured by financial collapse, *The Rover*'s tone, contemporary and realistic,
nothing fantasy — carried in every name and event line; and the ARPG layer on top of the idle loop: affixes now,
the tree and the classes next. Cash is "the one number" and it's called what it is: pounds in a world where
money has stopped meaning much.

## The loop

The camp is the rail. A mission is the idle action: pick a tier of the zone, it runs as a bar, and underneath it
combat resolves as numbers a second at a time — the loadout's damage against the enemy pool, their damage
against the operator's HP, armour as mitigation. Clear the pool and extract with the loot, the cash and a clear
bonus. Press **Extract now** and leave with what's been found, no bonus. HP hits zero and the operator is KIA:
the equipped loadout and what was found are gone; the stash and the cash stay; a fresh operator takes over at
level 1. Loot is items with a slot, a rarity (Common / Uncommon / Rare / Elite) and one to three affixes
(damage, armour, max HP, loot find, capacity, pace). Sell at the Black Market, buy from its three-item stock
that re-rolls after every mission, heal at the Medic Tent for free slowly or for cash at once.

## The body

The operator is a body with a slot per item — Primary, Secondary, Helmet, Armour, Rig, Backpack — and a gun is
itself a body with slots for attachments (optic, muzzle, magazine, handguard, stock). Attachments are modelled
on every gun now and empty; they are the Workshop's job in a later slice. Rig and backpack set how much a
mission can bring back; loot past that is left behind, which is why extracting early can be the right call.

## The first slice

One operator, no class. One zone, the Ring Road, in three tiers: outer checkpoints, fuel yards, the depot. Five
rooms: Camp, Missions, Armoury, Medic Tent, Black Market. The depot clear is the win. Standard mode only;
hardcore (stash wiped too) is a toggle later. Workshop, Comms Tower and Barracks come when there's something for
them to do.

The question it answers: does a mission with loot at the end of it hold attention in a menu, where Clade's
skill training didn't?

## Decisions (1 Oct 2026)

- KIA loses the equipped loadout; the stash is safe.
- Extract now is a button on the mission card.
- Hardcore off for the slice.
- The gear model is Tarkov's / an ARPG's from the start: a body with slots, guns with attachment slots.

## Second slice (1 Oct, after the first playtest)

The depot fell in 33 minutes with no deaths and the gear choice couldn't be acted on. Added: ±25% combat swing
and a survival % on every tier card; two-card combat (Contact and Mission) with the pack listed; a search phase
after the clear - caches every 5 s, patrols every 20 s and growing, extract whenever - which is Tarkov's
push-or-leave decision made from parts the sim already had; auto-run per tier; and the Armoury screen, the
body's slots beside a stash grid with a compare panel. Barracks stays reserved for the operator: level, tree, class.

**Meds and the rig** (same day): the rig carries consumables, the backpack carries loot. Bandage, medkit and
surgical kit are items with rarity and a healing affix; bought at the Medic Tent, found rarely, taken into the
rig in the Armoury, used from the Operator card under fire. Decisions settled: manual use first (auto-use
later), KIA loses the rig's meds, meds are found rarely so cash matters.

**The tree** (same day): built as above - the camp's, kept across operators, three chains with notables that
change the sim's rules rather than add numbers.

## After the slice, in order

1. ~~The passive tree~~ — built.
2. ~~Classes~~ — built: five sets of rules, chosen at the Barracks, free to change in camp. ~~A second zone~~ — built: the Docks, opened by the depot.
3. ~~The Workshop~~ — built: attachments as loot, fitted at a bench whose levels are the cash sink.
4. ~~Intel-framed map modifiers on missions~~ — built, with depth as the ladder on every tier.
5. ~~**Stash and inventory rework**~~ — built (added 1 Oct, before anything offline): the stash grid and the Armoury's body
   column were built as the quickest thing that worked and are rudimentary. Tarkov's grid proper - items with a
   footprint, the stash a container with upgradeable size, filtering by slot and rarity, sort, multi-select
   sell, and the rig and pack as containers of their own rather than counters - with the Workshop's attachment
   grid on the same component.
6. ~~Comms Tower and camp upgrades~~ — built: buy and pin intel; stash, tent and shelf levels for cash.
7. ~~Offline missions, save slots, hardcore~~ — built: time away runs through the sim (eight-hour cap), three
   slots beside the autosave, hardcore as a title option where a KIA ends the camp.
8. ~~The balance pass~~ — done once, with `tests/balance.gd` as the reader; the numbers are in status.md.
   ~~The language pass~~ — done: the words are Fiat's now (the Estate and the Town, nail guns to army
   bullpups, runners who were doormen and poachers); the table is in status.md.
9. ~~Builds~~ — built (1 Oct, before the playtest at Matt's call): one common tree and two per class with a
   keystone each, weapon types the class notables key off, five conditional affixes, and the yard's own
   upgrades (generator, lookout, kennel) as the late sinks. Art is still last.
10. ~~The run as a screen~~ — built: the pack as a live cell grid with Ditch, and loot split by source (kills
    drop what they carried, looks turn up what's lying there) so the fight is a loot source too.
11. ~~**Juicing a site**~~ — built (2 Oct). (From the playtest, 1 Oct): at the Radio, pay to add a word of your choosing to a tier,
    or lock one word and re-roll the other - PoE's map crafting, on the Radio rather than a bench of its own.
    Small, and the synergy words below need it.
12. ~~**Synergies and broken builds**~~ — built (2 Oct): the build-keyed affixes, typed parts, uniques, the per-class
    keystone bot in the reader; the pairs are left to emerge. What's built is the foundation - stat stacks, type-gated notables,
    keystones that break one rule - but nothing in the game is written to multiply with anything else yet.
    A synergy is two pieces that are each fine alone and stupid together. The slice, all from hooks the sim
    has:
    - *Keystones that talk to each other.* Pairs across a class's two trees that are the build: Not today
      (the first death is half HP) with under-half-HP damage - you want to be nearly dead; Never there (no lot
      ever comes) with the look bonuses - a long quiet search - and with One shot, pointless. Some pairs
      should be actively bad, so the good ones feel found, not given.
    - *Gear that keys off the build.* Affixes that scale with a choice rather than add a number: damage per
      attachment fitted, armour per empty pack cell, loot find per med carried, cash per pack cell filled.
      A Bodger with a nail gun and five mounts, or a Pack horse who fills a bergen, becomes a thing because
      the gear rewards it.
    - *Words that change what keystones do.* Delivery day under Bodyline is free money; Spread out turns
      Bodyline off; Tooled up with One shot. Juicing becomes the build's enabler.
    - *Breakage on purpose, and a guard.* One or two interactions tuned clearly over the line - a Scrapper
      with Nothing wasted, Magpie, the dog and a bergen walks out of the bank with the stash full - because
      finding the thing that breaks an idler is why people play them. The guard is the reader: a bot per
      class that trains towards its keystones rather than greedily, so which build clears the bank first,
      and by how much, is a number we chose.
    - *What it needs from the playtest first:* which keystones get reached and whether any felt like a build
      on its own. None: make the keystones louder before the pairs. One: that's the template.
13. ~~**The item and attachment pool, expanded significantly**~~ — built (2 Oct): 18/8/6/7/5/6/5 bases, 23 parts, 4 uniques. Seven primaries, four secondaries, three
    helmets, four armours, two rigs, three packs, three meds and twelve attachments is a slice's worth; a
    loot game needs the drops to keep being new for the hours the curve runs. Roughly three to four times
    the bases, and the shape matters more than the count:
    - *Guns by type, several per tier,* so a type is a build you can stay in: improvised (nail gun, bolt
      gun, a pipe shotgun, a crossbow), shotguns (farmer's, pump, sawn-off, riot), rifles (.22, stalking,
      bullpup, AR-pattern, an old .303), SMGs (workshop, machine pistol, a proper one looted from a police
      armoury), pistols. Each with a reason to be chosen - rate of fire, first-shot weight, mount count,
      cells - not a straight tier ladder.
    - *Armour and helmets with a second axis* beyond armour: weight as pace, or cells as capacity on a
      carrier, so a plate carrier and a stab vest are different choices, not a bigger number.
    - *Rigs and packs as the carry builds* - more sizes, and a few with affixes native to them (a medic's
      rig that carries more meds, a scrapper's pack with a parts pocket).
    - *Attachments: a full set per mount with trade-offs,* so Bodger and Spray builds have parts to choose
      between rather than one best per mount - and the first attachments that key off a type (a choke for
      shotguns, a bipod for rifles) which is where item 12's gear synergies live.
    - *Uniques, a handful:* named items with a fixed affix set and one rule of their own, dropped at depth,
      the thing a build is found around. Not many; the ones there are should be argued about.
    - Every base is data in `data.gd`; every line the UI builds from it goes through `UI.fit`, and the
      worst-case pass in the smoke test covers every base automatically, so the pool can grow without the
      screens being re-checked by hand. The balance reader re-runs after.
14. ~~The Clinic on the grid~~ — built (2 Oct).
15. ~~Art~~ — a first pass (2 Oct): line-art glyphs per kind of item, in cells and rows. Drawn art later.
16. ~~Ammo~~ — built (2 Oct, from the playtest): five types for the five gun types, stacks in the rig spent
    per shot, dry means the secondary then fists, two grades a type, standard by the box at the fence.
17. ~~Footprints, the body, the art hooks~~ — built (2 Oct): W×H footprints on a 64 px cell, the grid
    packs first-fit, the Lock-up's slots are boxes to drag gear onto, item cells load `art/items/<slug>.png`
    when it exists; PixelLab manifests per type in `tools/`, the studio card and a title that stands on
    `art/title.png`.
18. ~~Narrative~~ — built (2 Oct): `docs/design/narrative.md`; the yard is the player, the deeds are the
    ending, the log and the places and the people and the things tell it; item words for everything; a
    language pass (gangs, not lots).
19. ~~The City, the campaign and the endgame~~ — built (2 Oct): three zones, a zone opens on the boss of the
    one before; the depth ladder and call-in open when all three are done; at depth every site fights the
    same curve bent by its shape and differs by what it drops (exclusives); one boss a zone with their own
    uniques, free once, then notes - the second currency, dropped everywhere.
20. ~~The endgame built out~~ — built (2 Oct, "do it all now and balance after"): trees as webs with a
    branch to the keystone and a branch to a rule; the second past at 30; traits and the two who turn
    up; rules for the bosses' uniques; the charm (magic find and cash); sockets and six socketables;
    the map (atlas passives); contracts and the fence's mate; events on a run; pinnacles at depth 10
    with their charms and the convoy at 12 with the lorry's load; the bench's crafting in notes; moving
    the yard. Status.md has the detail.
21. ~~The late cash sinks~~ — built (2 Oct): call-ins priced by depth and by the words on the site;
    insurance, the fence holding the paper on the kit for a run.
22. **From the playtest (2 Oct), the list** — in the order I'd do them:
    1. ~~**Stacks.**~~ Done (5 Oct). Ammo stacks of a type merge (a box of nails found joins the nails in the stash and the
       rig, up to a stack cap), and socketables stack the same way; "a lot of different stacks of nails
       felt wrong". Stack caps per type; a stack splits when taken to the rig if the rig's pouch can't
       hold it all.
    2. **Git.** The project lives on the Legion and nowhere else. A repo on GitHub (mattcollins30-web),
       `.gitignore` for `.godot/`, `*.import` kept, `pixellab_secret.txt` never, the art in (it's small);
       Claude Code commits from the Legion and the cloud session works from the remote when the Legion
       is off.
    3. **The run view** — the showpiece: a rail-shooter frame (Time Crisis, not an FPS) as a layered 2D
       visualiser of what the sim already emits - a plate per site, enemies popping at three depth bands,
       cover in the foreground, the runner's gun; a gang is N sprites, a kill a drop, incoming a flash
       and a vignette, a med a hand, the search a pan, the boss the door at the back. Slice with coloured
       rectangles first (no art, no sim change), art second (the biggest art job in the game: plates,
       cover, enemies in four states at three scales, the heads, the hands), a click-to-focus-fire layer
       later if it earns it. The side-on street strip is the fallback.
    4. **Sound.** Ambient a site, the gun's tick, a sting when a gang arrives, the boss's door.
    5. ~~**The first ten minutes.**~~ Done (5 Oct), as "what's next" in the voice. An objective line on the Yard ("Clear the parade") and the log carrying
       the tutorial in the voice.
    6. ~~**The away report.**~~ Done (5 Oct): "Back, then." in the log's voice, with the fence's prices.
    7. ~~**Idle quality of life.**~~ Done (5 Oct). "Equip if better" and "sell commons on return" toggles; the reads leave
       184-item stashes.
    8. ~~**The collection.**~~ Done (5 Oct): the Caravan is the collection - the runners before on its
       wall, the papers in its drawer, the uniques on its shelf.
    9. **Juice.** Damage numbers on the run panel, a flash on a rare, the log's best lines as toasts.
23. Manual placement in the bag (true tetris), if first-fit feels wrong in play.
24. **Fiat feeling like Fiat (Matt, 4 Oct) — all built 4–5 Oct, in status.md:** money that goes off
    (every cash price and income rises with the yard's hours, 7% an hour after a grace hour, to ×12;
    notes hold); the estate recycles (a dead runner's kit and a sold unique turn up on a gang member a
    few runs later and come off him on the clear); faces for the people who matter (the heads' lines
    when armed and a face slot on the run, a manifest for their portraits, the Caravan's wall of
    runners before); the places changing (sites picked over and back over two hours, the clock's
    night, rain and fog by zone on the Runs card); the voice where the UI explained itself (the away
    report, the fence's contracts, the Yard's notes); the papers as the book (read in the order found,
    six deep ones, the drawer in the Caravan).

## Builds (4 Oct 2026): the gear pass before any art

Matt: "we need to spend time on the gear, affixes and builds ... resists ... enemies need to use those
damage types as it scales ... damage over time ... melee ... this all comes before anything above and
certainly before any art - that's the Greenhorn trap"; then "it needs to go further where we can actually
create entire builds out of fire ... perk trees expanded to account for the element types per class ...
build defining uniques that are rare but powerful enough to define a build ... power spikes that take you
from depth 20 to depth 60"; then "expand the entire affix system ... much wider and deeper ... tiers of
affixes so the workshop can be used to reroll ... that could also be the late game cash sink."

The thesis: a build is three layers multiplying - a commitment that converts what you do into one
thing, a tree that multiplies that thing, an item that changes that thing's rules. Depth 20 to 60 is
about ×190 in enemy HP on the curve, so a build has to be able to make ×100, and that only comes from
layers that multiply, not add. Built in this order, each step leaving the game green:

1. **Affixes, wide and tiered.** Sixty-odd affixes against today's fourteen, each with a slot list, five
   tiers (T5 worst, T1 best; the same affix at a different value), a weight, and for some a condition.
   Offence: increased and added damage per type, conversions on gear, attack speed, first-shot, dot
   duration and damage, spread chance. Defence: armour, HP, regen a second, life on hit, life on kill,
   a resist per type, all resists, dot resistance, less from three-plus. Utility: pace, search, loot
   find, magic find, cash, notes, cells, pouches, med speed and power. Conditional: per socket filled,
   per med carried, while bleeding, under half, against burning/frozen/poisoned. Which tiers can roll
   comes from the item's level - its base's tier plus the depth it dropped at - so depth has a third
   reason beside quantity and rarity: the ceiling on what the bench can make. Rarity still sets the
   count. The item panel shows the affixes as a list with tiers ("+21% fire · T1"); the Lock-up's log
   drops to its latest line to make the room (every room gets that 60 px).
2. **The damage model as layers.** Base hit → conversion by type → increased (everything additive, one
   multiplier) → more (keystones and uniques, each its own multiplier) → how many it hits → what stays
   on them (dots) → their resist. Six types: physical, fire, frost, poison, shock, bleed. Dots: burn (a
   share of the hit over four seconds), poison (slow, long, stacks), bleed (flat a second until a med
   or the gang's down), on them per target and on you as three states the run panel shows; searching
   doesn't tick dots on you. Frost slows their fire; shock is the first-shot type. The socketables
   become conversions.
3. **Their side.** Gang resist profiles by zone (soft, jacketed, ex-army with the lot); a type by zone
   and depth (estate blades and bats, town petrol and poison, city shock and fire), the share rising
   with depth; words that add a type ("Burners", "Cutters", "Wired") or a resist ("Jacketed",
   "Rubbered", "Hardened"); "Resistant" from depth 8; from depth 8 a zone's own resists (what it wears, what it throws) rise with depth and the rest stay open, so every site is somebody's; reflect gangs from
   depth 30 as a second pass. The depth band test becomes "every site viable for some build".
4. **Five element trees, as webs.** Fire ("Petrol"), frost ("The cold"), poison ("The rat man"), shock
   ("Live"), bleed ("Blades"): a spine of conversion and increased, a fork, a keystone that breaks the
   element's rule (fire spreads to the next; bleed never stops; poison past the cap; frost makes them
   miss; shock on the first is the whole gang) and a notable with a cost (fire: you burn too). Points are
   the points you have: an element's keystone means an unfinished class tree. **Affinities:** each class
   has two elements its nodes come cheaper on and whose keystone it reaches by 30; the other three cost
   double and need the second past. Drifter fire/shock, Doorman bleed/physical, Poacher poison/frost,
   Scrapper shock/fire, Paramedic poison/frost from the other side. The class webs' spare branches each
   get an element notable that keys the pairing.
5. **Melee**, a sixth build: primaries (spiked bat, machete, pipe wrench, fire axe, sledgehammer, a
   bayonet on a stick) and secondaries (knife, knuckle duster, a cosh). No ammo ("Takes nothing"), slow,
   hard, bleed built in, grip and head mounts plus sockets; +25% incoming and the gang's first shot
   before yours. Keystone "Through the lot": a swing hits everyone on you.
6. **Uniques that are rules**, depth-gated (12+, then 25+), from pinnacles, the convoy and the mate's
   deep stock, one in a few hundred finds. The first four: *the council's weed burner* (fire hits
   everyone on you and spreads), *jump leads* (the first of a gang is every one of them), *the rat man's
   bag* (poison never caps, carries to the next gang), *the butcher's steel* (bleed double, hits reopen
   it). Then *the gritter's hopper*, *the sparky's gloves*, *the quartermaster's manual*, *a blue
   plaque*. Tiers vary on uniques too, so a good one exists.
6b. **Uniques, more of them, inventive** (Matt, 4 Oct: "may as well go big ... nothing too formulaic").
   Twenty-odd across the slots, each a rule, several that cross elements or turn a cost into a
   strength; some charms and papers among them, not only guns and armour. Rare by depth and source.
6c. **Sets** (Matt, 4 Oct): named sets - the council's gear, the ambulance's, the bank's, the
   army's, the carpet man's - two to four pieces each, with bonuses at two and at the full set that
   make a build the way a unique does. Drawn in their own tint, apart from the rarity colours; the
   cell and the panel say "2 of 4 · the council's" and what the next piece brings.
7. **The bench as a crafting bench**, in cash: re-roll everything within the slot's pool; lock one and
   re-roll the rest (×3); re-roll one (same tier mostly, a chance up, a smaller chance down, narrowing
   as the tier rises); add, cut a socket, strip; and *bump the item level* in notes. Prices scale with
   the item's level and what's on it, so perfection is dear and bottomless. Insurance and call-ins
   stay; this is the main sink. A Craft view beside Guns and Sockets.
8. **Tests and the reader**: a bot per element that trains to its keystone and crafts toward it, so
   "which build clears depth 40 first and by how much" is a number we chose; where each walls.
9. The rest of the uniques (all thirty-five carry rules - done); prestige's "yard's trade" (a move
   opens one element's keystone to every class, permanently - done, 4 Oct: picked at the move, one
   of the five a move); balance last, from the element read.

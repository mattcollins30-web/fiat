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
change the sim's rules rather than add numbers. (5 Oct: only the yard's tree is kept across runners; a
runner's own trees - the class's, the second past's and the elements' (a fire build is the runner's) - go
with them on a death, refunded as points, and the next runner picks a past from the start.)

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
    4. ~~**Sound.**~~ Done (5 Oct) with synthesised placeholders. Ambient a site, the gun's tick, a sting when a gang arrives, the boss's door.
    5. ~~**The first ten minutes.**~~ Done (5 Oct), as "what's next" in the voice. An objective line on the Yard ("Clear the parade") and the log carrying
       the tutorial in the voice.
    6. ~~**The away report.**~~ Done (5 Oct): "Back, then." in the log's voice, with the fence's prices.
    7. ~~**Idle quality of life.**~~ Done (5 Oct). "Equip if better" and "sell commons on return" toggles; the reads leave
       184-item stashes.
    8. ~~**The collection.**~~ Done (5 Oct): the Caravan is the collection - the runners before on its
       wall, the papers in its drawer, the uniques on its shelf.
    9. ~~**Juice.**~~ Done (5 Oct). Damage numbers on the run panel, a flash on a rare, the log's best lines as toasts.
23. **Manual placement in the bag (true tetris)** — *backlog (Matt, 6 Oct): after the balance pass, if at
    all; a UI item that adds nothing to the game as it stands.* Agreed 5 Oct, after the playtest: the pack is a count
    today (`pack_used` sums footprints; the grid draws them first-come); it becomes a real grid, each find
    with a position, a find landing where it fits or not at all, drag to repack on the run and in the
    Lock-up's pack map; the bot and the estimator pack too. Balanced with 25, since both change what
    comes home and what it's worth.
25. **Crafting at the bench** (Matt, 5 Oct; shaped in the chat, after the playtest). One material,
    **scrap**: a stackable like the socketables, found on searches (one find in five a handful) and
    made by stripping any item at the bench or ditching it on a run (its value over twenty), so a ditch
    and a full stash both have a third answer beside sell and ditch. A **Build** column on the Craft view:
    - **a box of rounds**, standard, of any type you have a gun for, for scrap - cheap, so a dry gun has
      a fix at the yard and the pistol's rounds stop being a tax;
    - **the better grades**, from scrap plus a standard box of the type: nails to hardened bolts, shells
      to slugs, rifle rounds to match rounds, SMG rounds to hollow point, pistol rounds to hollow point,
      and the tier-3 grades (belt links, depot rounds) from the grade below - each step wanting the one
      under it, so the fence's shelf keeps its place for the top;
    - **a med**: scrap to a bandage; scrap plus a bandage to a first aid kit; and on up the grades, each
      wanting the one below - the clinic keeps the top grades and the healing affixes;
    - **a gun**: scrap to an improvised gun of a type you choose (improvised shotgun, rifle, SMG...),
      a plain roll at the bench's level with a random mount set, Common, firing nails whatever its type
      so the crafted rounds feed it. The improvised tag is the point: Bodger and the Scrapper's past key
      off it, and the bench's own jobs are how it becomes yours. Never strictly better than a found gun
      of its tier; the one you can have now, for scrap, and build a whole improvised runner around.
    Not crafted: gear with affixes, armour, helmets (the body slots stay what you find); not a second
    material. The balance levers: scrap per pound on a strip, a gun's price in scrap against the shelf,
    Bodger's +40% once improvised guns are on tap.
26. **Grenades in the rig** (Matt, 5 Oct; after the playtest). A rig item beside the meds, thrown the way
    a med is used - from a pouch on the run - for damage to everyone on you instead of healing: one an
    element (a petrol bomb, a nail bomb for bleed, a bottle of something for poison, a wired battery for
    shock, a dry-ice bag for the cold), its hit by type through the damage model so resists, conversion
    and the element trees all read it, and its dot lands on the gang. Found on runs, on the fence's
    shelf, and built at the bench from scrap plus the element's socketable (lighter fluid to a petrol
    bomb). A thrown one spends the pouch; Second shift and the rig's rules decide whether they cover
    it. The rig's pouches are the limit: a grenade is a med you didn't carry.

## Before the one balance pass (6 Oct 2026): everything that moves a number

Matt, 6 Oct: "we need to get as much in as possible that changes numbers and then balance pass only after
they are in - my point was we added stuff after a balance pass in greenhorn and then immediately had to
rebalance", and "we need to really select balance pass gates so as to not waste time." So: every feature
below goes in first, nothing numeric is tuned while they go in (the shock and bleed figures, the rest
threshold, the rarity weights and the prices wait), and then one pass against the gates at the end of this
section, ending when every gate is green with no accepted red. Anything numeric after the pass starts a new
pass. In build order; the economy items last so the reader runs once over all of it.

27. **The loot roll, straightened.** Quantity comes out of the rarity roll (`Items.roll` reads
    `rarity_bonus()` and the intel's rarity, not `loot_bonus()`), so Rat's share stops charging quality
    twice. Quantity reaches searches: a search's find count carries a fractional extra (quantity +25% is a
    fourth find one search in four), so the stat means "more" everywhere a find comes from. Quality's
    sources widen: a rarity node on every class tree's second branch, a rarity affix on backpacks, and
    the dog's level adding quality, so a build can lean on it. The weights themselves are the pass's.
28. **Capstones** (Matt, 6 Oct: "the skill tree doesn't feel all that impactful - there needs to be a
    final keystone above and beyond what we already have"). One a tree, past the keystone, costing a
    quarter of the tree's points (a third until the pass), taken only with the keystone and both notables; each changes how a run
    is played rather than a figure, and each reads on the run screen. Defaults, Matt to redirect:
    Stalking: *Patience* - no gang comes while you haven't fired; the search is free until you choose
    the fight (the Next gang tile reads "when you fire"). Snares: *Poached* - a gang that arrives a head
    short arrives having lost that head's loot to you (a find on every gang's arrival). Muscle:
    *Second wind* becomes a rule - kills under half HP heal a tenth of max. The yard's tree: *The dog's
    share* - a dead runner's rig comes home. Luck: *Loaded dice* - every Elite find rolls twice and keeps
    the better. The elements': *Petrol*: burns spread on a kill; *The cold*: a frozen gang's first shot
    misses; *The rat man*: poison keeps ticking on the next gang; *Live*: a shock chain never breaks
    while you fire; *Blades*: a bleeding target bleeds its neighbour. The second past's tree gets the
    class's. Shown as a ◆◆ tile at the foot of the tree, its own line on the run's fight box.
    *Built (6 Oct), the set as it landed:* The yard *The dog's share*; Stalking *Dead quiet* (every gang
    the size of the first); Snares *Poached*; Muscle *Iron*; The door *Held* (no second of their fire
    over a tenth of you); Triage *Clean hands* (a med clears what's on you, three seconds' grace);
    Shifts *Transfusion* (a med's overflow is armour, two to one); Stripping *Jerry-rigged*
    (improvised ×1.5); Fencing *The lot* (a full pack pays double); Moving on *Ghost* (the first gang
    never comes, and a full pack brought home is the clear: the tree's keystone is Never there, so a
    clear by fighting can never happen on it); Luck *Loaded dice*; Petrol *Spread*; The cold *Shatter*
    (physical ×2 on a chilled target); The rat man *Lingers*; Live *Arc*; Blades *Bleed out*. Each
    reads on the run band's third line, not the fight box.
29. **Picked over inside a run.** The between-run curve applied within one: after the Nth search on a
    site in a run (N by depth), finds thin by a fifth a search, to a floor; the Searching bar's words
    say so ("Thinning"). "Fill up, then go" and the pack grid get a natural stop, and quantity bonuses
    push N. *Built (6 Oct):* N = 6 + 2 a depth, scaled by the quantity bonus; a fifth a search to a floor
    of two fifths; "Thinning: finds at 80%", "Thinned out: finds at 40%" on the Searching bar.
30. **Wounds.** A hit that takes the runner under a quarter HP leaves a wound: one worn stat cut (pace,
    armour or max HP, −10%) until treated at the clinic for a price by level; the clinic's Treat gets a
    second reason, the band and the Runner card show it ("Wounded: pace −10%"), and dying stops being
    the only cost of risk. One wound at a time; a second replaces it. The bot treats on return. *Built
    (6 Oct):* −10%, £20 a level (the clinic's discount applies), the wound chip first on the Runner card.
31. **The works' top levels.** One level above what each has, each a rule rather than a figure: the
    generator powers a second rig row (the rig's pouches double, meds and grenades alike); the lookout
    names the first gang before you set off (the Runs card's Them tile reads the real count and HP, not
    the estimate, and the first gang comes at the lookout's call); the kennel's dog carries one find
    home on a death (the best in the pack). Priced as the top cash sink alongside the bench. *Built
    (6 Oct):* the Them tile already read the real count and HP, so the lookout's rule is the call alone:
    the first gang after the clear waits for a full pack. £30,000, £24,000, £18,000, untuned.
32. **Grenades in the rig** - as 26. *Built (6 Oct):* five, one an element, 60–100 damage to everyone on
    you through the model, a pouch each; found, on the fence's shelf, the bench's build under 34.
33. **Ammo grades with an element.** The tier-2 and tier-3 grades carry a type as well as damage:
    hollow point bleeds, match rounds a flat crit, incendiary (a new grade of shells and SMG rounds)
    fire, salted (rifle) frost, so crafting has something to craft toward and a build can run its
    element off the rounds. Through the damage model like a conversion affix on the gun. *Built (6 Oct):*
    hollow point 20% bleed, match rounds first shot +25%, incendiary shells and SMG rounds 30% fire, salted
    rifle rounds 30% frost; the primary's live stack feeds the conversion.
34. **Crafting at the bench** - as 25, with 33's grades in its ladder and grenades (32) in its Build
    column. *Built (6 Oct):* scrap as a count in hand, not a stackable (no stash cells; one figure for the
    gate); the Build menu off the craft view; a built gun is flagged to fire nails.
35. **Contracts paying in craft materials.** A third pay kind beside cash and notes: scrap by the
    handful, a socketable of the zone's element, or a grade of rounds, so the fence's contracts feed
    the bench and the Contracts tab has a reason once cash is easy. *Built (6 Oct):* a third of the
    non-unique contracts, scrap 6 a rarity a piece, the zone's element's socketable, a grade for a gun held.
36. **Retirement.** A runner at level 30 can be retired to the wall: the yard keeps a sliver of their
    trait for good (a third, stacking to a cap of three retired), the class and its trees refund as a
    death does, the Caravan's wall shows them as retired not dead. A death is not the only way a runner
    ends, and the trait pool gets a cumulative side without touching the refund rule. *Built (6 Oct):*
    level 30, a third a trait, three on the wall with the oldest making way, the kit kept in the stash.
37. ~~Manual placement in the bag~~ - *to the backlog (Matt, 6 Oct): "essentially a UI item and doesn't
    add anything to the game as it stands". The pass starts once 34, 35 and 36 are in.*

38. **The pool's last add** (Matt, 6 Oct: "expand the item pool and generate art for it - this will be the
    last item add for a while. Real top tier items. Uniques that really lean on elemental damage types
    for those broken builds. Some defensive gear that provides good resists."). *Built the same day,
    untuned:* the top of each slot at tier 6 - Police marksman's rifle, Riot squad's shotgun, Officer's
    revolver, Army machine pistol, Bomb-squad helmet, Bomb suit, Bomb-disposal rig, Full bergen, Mayor's
    chain; resist gear with the resist built into the base (`"res"`, read by `resist()` beside the
    affixes and said on the head) - Welder's mask, Station helmet (visored), Fireman's tunic, Lineman's
    rubber coat, Cold-store parka, Hazmat suit, Butcher's chainmail; five uniques, one an element, each a
    rule: The arsonist's rig (every med used sets everyone on you alight), The gritter's keys (a chill
    holds while you fire; chilled, double frost), The rat man's overalls (poison stacks without end and
    ticks twice as fast), The substation key (shock on one is shock on all; shocked, +60%), The butcher's
    apron (bleeds carry to the next and cut three deep); and a defensive set, The fire crew's (tunic,
    helmet, breathing set: fire resist +40% at two, all resists +15% and regen at three). Art for every one
    in the manifests.

### The gates

Measured by `tools\balance.bat` on the Legion (eleven reads at once: the five classes keystones-first,
the five element builds, the loot probe; `tests/balance.gd -- 8 gate <Class> [element]` each, then
`tools/balance_summary.gd` writes `docs/balance/summary.md` with the table below read red or green;
`tools\read.bat <hours> <Class> [element]` for one build) before
any value moves, and again after each change; the pass ends when every row is green. Figures to be set
with Matt's death count from the playtest; the rest are defaults to overrule. Known before the first read:
+35% quality scales every non-common rarity weight alike, so the Elite share goes 2.0% → 2.4%, not 3%; the
weights or the gate's figure move in the pass.

| Gate | Read by | Green when |
| --- | --- | --- |
| The bank's band | time to the bank, six builds | slowest within 1.5× the fastest |
| The keystone | hour each build takes its keystone | by hour 2, every build |
| The capstone | hour each build takes its capstone | by hour 4, every build |
| No reds | the odds reader at every open tier at depth 1, in the kit at the end | no tier under 60% |
| Loot quality visible | Legendary share at +35% quality | at least 2.0% (0.8% unboosted) |
| Quantity honest | finds a search at +25% quantity | 1.25 ± 0.05 |
| Cash sink | cash in hand at the end, in hours of the build's takings | no more than two hours' takings (was 3× the top bench: the wrong shape for a ladder that pays by depth) |
| Depth pace | depths cleared an hour on the grind site, hour 4 to 8 | at least one |
| Deaths | the player's own, from the playtest save | one every N hours at Matt's risk (N to set) |
| Wounds | share of runs ending wounded, the bot at its threshold | 10–25% |
| Scrap economy | scrap in hand against the dearest craft, hour 4 | between one and three crafts' worth |

**On the list for the pass, to discuss before it starts (Matt, 6 Oct):** rarity as quality in itself. Today
a rarity is only its affix count (Uncommon one, Rare two, Elite three) and its fence value; the base figures
never change with it and every affix's tier comes from the item level alone, so a Rare from deep beats an
Elite from shallow. Matt: "it should probably be both" - a floor on affix tiers by rarity (an Elite rolls no
T1s) and a base multiplier per rarity. Both are numbers, so they go in with the pass, and a gate for them
("an Elite outguns a Rare of the same level") joins the table once the shape is agreed.

**Also for the pass (Matt, 6 Oct):** the starting kit must be the worst kit in the game. Today the runner
starts with a Nail gun (28 × 0.6 = 16.8 damage/s, two mounts) and a Stab vest (15 armour), and the pool
holds a Bolt gun (38 × 0.4 = 15.2) and a Padded jacket (10 armour, +2 pace) under them, so those two bases
are never an upgrade for anyone. Recommendation: a starting pair of its own below the pool (a "Hand-me-down
nail gun" and a "Work jacket", say, with no mounts and nothing rolled), or start on the Bolt gun and the
Padded jacket; the gate: every base in the pool beats the starting kit of its slot on its own figures.

### The pass plan (6 Oct, after two reads; wired to the code, to argue with before the figures move)

Two full reads on the Legion (`docs/balance/summary.md`), the second with the bot's dry gun fixed: the
keystone row green, the bank 1.4 to 5.0 h, the capstone 2.1 to 7.1 h, cash at £150k–£300k against a £14k
top bench in seven builds of ten, scrap at four to nine crafts' worth, the Elite share 2.35% against 3%.
A lever a line below, with the code it touches, the row it moves and the rows it can break. No figures
here: they come from the read before and after each move, one move at a time, the summary re-read
between. Each move is one commit with its before-and-after summary lines in status.md.

0. **The reader first: the bot spends at the bench like a player.** The bot added one affix a worn piece
   and stopped, where a player with £200k re-rolls until the kit is right. `tests/bot.gd _bench_worn`:
   the worn kit's weakest affix re-rolled (`craft "one"`), one job a run at most, while two grand stays -
   one a run bounds the spend by the runs, so what piles up past it is the prices' to answer for. Built
   6 Oct, in status.md; the next read carries it.
1. **Cash: the bench and the words priced off the run's pay.** Every cash price takes the inflation
   already (`_inf`, sim.gd ~535: ×(1 + 0.07 an hour past the first, to ×12)), so that is not it. Income
   has two shapes: before the campaign `TIERS[i].cash` by tier (6, 9, 14, 22, 24, 30, 40, 44, 50) ×
   1.12 a depth; past it, at depth 2 and up, `CURVE.cash` 40 × 1.10 a depth × the site's shape
   (`effective()`, sim.gd ~2321). Every sink scales from an opening figure by the inflation alone, so a
   T8 run at hour 6 pays five times a T2 run on the base alone (more with depth) while a bench job
   costs the same multiple of its opening price. The move: one reader, the open tier's pay
   (`effective(top open tier)["cash"]`, whichever shape it's in), as the base of `craft_cost` (today
   `CRAFT[kind].cash` × ilvl × (rarity + 1), sim.gd ~1089) and `juice_cost` (today `INTEL_CASH[i]` × 3 ×
   depth × words, sim.gd ~1929); the works' ladders stay opening prices, each bought once. Moves: Cash
   sink. Can break: the capstone and the band if a work is what gets a slow class there - so the works'
   first levels stay. Not touched: income; the early hours are the right pace.
2. **Scrap: the ladder dearer, not the contracts leaner.** Scrap comes from searches (a fifth of them,
   3–6; `SCRAP_SEARCH`, `SCRAP_HANDFUL`), the bench (`scrap_of` = value ÷ 20, the rarity multiple in
   the value), ditching on a run, and contracts (count × rarity × `CONTRACT_SCRAP` 6, so 6–36, on the
   materials branch only). The ladder: box 8, grade 15 × tier, med 8 × tier, gun `BUILD_GUN` 40 × tier,
   grenade 12 × tier (`build_options`, sim.gd ~1160; data.gd ~1115). A catch the plan missed: a gun is
   built only at a tier the bench has reached and the bench stops at level 3, so the tier 4–6 improvised
   guns are never built and `BUILD_GUN` reaches T1–T3 only - either the bench's top level builds any
   tier, or the gun ladder is three rungs by design and the dearest craft is a T3 gun. Moves: Scrap
   economy. Can break: nothing read; the element builds bench their gun later.
3. **The bank's band: the starting kit and the classes' early game.** `_starter_loadout` (sim.gd ~117)
   gives every class the same Nail gun (28 × 0.6 = 16.8), Stab vest (15), School bag (12 cells), Bum
   bag, two bandages and nails: no helmet, no secondary, nothing rolled. Under it in the pool: Bolt gun
   (15.2), Pipe shotgun (15.0), Padded jacket (10 armour, +2 pace), Carrier bags (8 cells, +3 pace).
   The move: a starting pair of its own below the pool (a "Hand-me-down nail gun" and a "Work jacket",
   no mounts), so every base is an upgrade for someone; the gate, every pool base above the start of its
   slot on its own figures. **Built 6 Oct** (three: the gun, the jacket, a Plastic bag; in status.md). The classes (`CLASSES`, data.gd ~1173): Poacher +40% on a gang's first,
   gangs ×1.25 later, HP ×0.9; Doorman damage ×1.15, armour ×1.2, pace ×0.9; Paramedic heal ×1.5, meds
   by themselves, damage ×0.9; Scrapper search ×0.7, +15% quantity, damage ×0.95; Drifter one fewer on
   you, pace ×1.1, HP ×0.85. The late bankers (Paramedic 5.0 h, Poacher 3.8 h) are the two with no
   damage or armour in their figures, so their hour-2 dps is the kit's alone; the move there is a class
   figure each, read against the band. Moves: the bank's band, the capstone (which follows the bank:
   it needs the level). Can break: nothing else reads before hour 2.
4. **The capstone's own price, only if the band leaves it late.** `capstone_cost` = ⌈the tree's other
   nodes ÷ 3⌉ (data.gd ~1202), `node_cost` 1 + i÷4 (+2 keystone, +1 notable), `OFF_AFFINITY_COST` 2 on
   top; a point a level, 49 by level 50, two a yard move; the three trees on show cost 57. Read again
   after 3; move the late nodes' prices only for what's left.
5. **Rarity.** Matt (6 Oct): rarity is the affix slots, and the tier an affix can roll: "common can have
   1 and it can only ever roll tier 1 affix and so on" - so "a nail gun rolled as epic with 4 affixes
   available stays relevant for levelling builds in the stash", and the question whether the pool wants
   another tier: common, uncommon, rare, epic, legendary, unique. There are five affix tiers
   (`AFFIX_TIERS`), so five rarities map one to one: Common one affix at T1, Uncommon two to T2, Rare
   three to T3, Epic four to T4, Legendary five to T5, Unique the rules. Today (`RARITIES`, data.gd
   ~663): Common 0 affixes / weight 60 / value ×1, Uncommon 1 / 28 / ×1.8, Rare 2 / 10 / ×3.5, Elite 3 /
   2 / ×8; the affix tier comes from the item level alone (`TIER_CAP` [0, 3, 6, 10, 15]: T5 needs item
   level 15; `TIER_WEIGHT` [8, 5, 3, 2, 1], T1 the heaviest), rarity plays no part in it, and there is no
   floor - a deep find rolls T1s as readily as a shallow one. The shape: the rarity sets the cap on the
   tier (over `TIER_CAP`, so a Legendary from the first site is five T5s on a tier-1 base - the stash's
   levelling gun, as Matt says), and the item level gains a floor it never had (deep finds roll no T1s),
   so depth and rarity both mean something. Elite goes; Common gains an affix, which raises every drop a
   notch. What it touches: `roll`/`_roll_rarity`/`roll_tier`/`pick_affixes` (items.gd), the add's cap
   (`RARITIES.size() - 1`, sim.gd ~1080 and items.gd ~423), sets at `RARITIES[2]` and uniques at `[3]`
   (items.gd ~456, ~480), contracts rolling 1–2 (sim.gd ~665), the four-entry tone arrays in
   armoury/item_cell/item_head/workshop, the inventory's filter labels, the vendor's `[0,0,0,0]`, the
   find sound at rarity ≥ 2, the balance reader's Elite share (a Legendary share, with new weights, and
   the probe's gate figure with it), and the smoke's hard-set rarities. Nothing in the manifests. Moves:
   Loot quality visible; the whole loot feel. Can break: every odds row, since every drop gets stronger
   - read after, and let 3 absorb it. **Built 6 Oct** (in status.md); the gate row reads a Legendary share.
6. **Deaths and wounds.** N from Matt's playtest. A wound lands when a hit takes the runner under
   `WOUND_AT` 0.25 of max HP (sim.gd ~2948); the bot bails at a quarter and the odds reader counts that
   as lost, so the two agree, and a bot that plays to PUSH 0.75 is rarely under a quarter. If the
   wounds row stays under the band with the bot playing to its odds, `WOUND_AT` moves (a wound from
   under a third, say), not the bot. **Moved 6 Oct:** 0.25 → 0.33 after five reads at 2–10%.
7. **Depth pace last.** It assumes the campaign done by hour 4, which 3 decides. The curve: `CURVE`
   hp 3200 × 1.14 a depth, cash 40 × 1.10, rarity 0.10 a depth (data.gd ~794); before the campaign
   hostiles ×1.25 a depth against rewards ×1.12. Read after everything else; move `CURVE.grow` only for
   what's left.

The order is the order above: the bench rule is in; then cash and scrap (they break nothing that reads
early), then the band, then rarity, then the rest for what's left.

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
   tiers (T1 worst, T5 best, as built; the same affix at a different value), a weight, and for some a condition.
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

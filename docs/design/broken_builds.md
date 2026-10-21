# The broken builds

Agreed with Matt on 21 Oct. Each class has one build that grows without a top over a run. It's made from three
things: the class's set at its count, one findable unique, and the keystone and capstone of the class's element. The
code is in `Data.COMBOS` and `Sim.combo_on`.

**Outside the balance.** The balance read switches them off (`Sim.combos_off` in tests/balance.gd), and the bot never
builds one on purpose.

**Hidden from the screens.** No screen describes them. The run log says one line, once per run, the first time it
catches. That line is the theorycrafter's hint.

**Per run.** The stacks belong to the run. They build kill on kill and are gone when you come home. A long run that
farms patrols after the clear is where they run away: stay out, no early extract.

**Points.** The paths below come from the training rules: the class tree's joint half, your element's half, the
keystone (level 20), every notable of the element tree, then the capstone (level 30). They are about 45 points, so
roughly level 45-50. Nodes that would stop the stacks (Never there, Hit and run, Walking wounded) are left out. An
asterisk (*) marks the nodes the build needs; the rest are only there to open the gates.

**Where things drop.** Levels are the signal levels shown on screen.
- A set drops from its depth on, any site past depth 1, rarely: 0.4% of finds a depth past the first, capped at 2%.
- A "core" unique drops from level 14 at loot tiers 4-9.
- A "chase" unique drops from level 22 at loot tiers 7-9, and is rarer (band weight 1 against core's 4).

## Drifter: Embers (fire)

- **The loop.** A kill on a burning man adds a stack, and each stack is +4% fire damage for the run. Spreads puts the
  fire on everyone on you and Wildfire carries the burn to the next man, so kills come faster as the stacks grow.
- **Gear.**
  - The Fire Crew's, all 3: Station tunic, Station helmet, Breathing set. From level 17.
  - The Council's Weed Burner, Primary, core. From level 14. It turns all of your damage into fire, times the crowd.
  - Shotgun rounds for the Burner, plenty of them.
- **Points (45).**
  - Moving on: Light feet, Road legs, Head start, Keep moving, Never still, Bottle and rag*, Wiry, Spray, Breather.
  - Petrol: A can of it, Rags, Siphoned, Wick, Lit, Drifter's can*, Fumes, Spreads* (keystone), On your hands,
    Wildfire* (capstone).
- **Affixes.** Fire increase (fire_pct), dot damage (dot_pct), attack speed (attack_pct). On your hands burns you: carry
  HP, regen and fire resist. The Fire Crew set's 40% fire and 15% all resists help.
- **The log line.** "The fire's catching on itself."

## Poacher: Clean kills (frost)

- **The loop.** A kill on a chilled man adds a stack. Every hit after the first carries the first shot's bonus,
  +5% a stack on top, so the first shot never ends. The Gritter's Keys hold the chill for as long as you fire.
  Frozen solid slows them to a crawl, and Shatter doubles the physical share against the chilled.
- **Gear.**
  - The Army's, all 4: Issue helmet, Issue carrier, Issue bergen, Issue rifle (the Primary). From level 23. The
    4-piece is every type ×1.3 and one fewer on you.
  - The Gritter's Keys, Charm, chase. From level 22, tiers 7-9.
  - Rifle rounds.
- **Points (45).**
  - Snares: Quick hands, Hedgerows, Soft ground, Night eyes, Snare lines, Cold snap*, Knowing the land, Trapline,
    Quiet feet.
  - The cold: De-icer, Frost, A hard winter, Numb, Chill, Poacher's snare*, Wind chill, Frozen solid* (keystone),
    Cold hands, Shatter* (capstone).
- **Affixes.** Frost conversion (conv_frost_pct) on the rifle, or a frost socketable. Frost and physical increase
  (frost_pct, physical_pct). Stalking's Rifleman and the Poacher's own +40% are the first shot's bonus that carries.
  - Known bug, Matt's call: an item's or a set's "first of each gang" line does nothing in the fight today (the Army
    3-piece's +40%, the Issue rifle's +20). See the note at the end.
- **The log line.** "The cold's doing the work now."

## Paramedic: Overdose (poison)

- **The loop.** Your poison's ticks heal you 5% of what they deal. Healing past full HP becomes stacks: a max HP's
  worth is one stack, and each stack is +100% poison. More poison means more ticks, more healing and more stacks, a
  loop that feeds itself. It wants you at full HP, so it's at its best where they hit you least.
- **Gear.**
  - The Ambulance's, all 3: Ambulance rig, Green overalls, Crew helmet. From level 16.
  - The Rat Man's Bag, Backpack, core. From level 14. Poison stacks without a top, and it carries to the next man.
- **Points (46).**
  - Triage: Steady pulse, Fast hands, Kit bag, Good veins, Stock take, Syringe*, Pressure, Field surgery,
    Pockets checked.
  - The Rat Man: Under the sink, Bait, Council issue, Cumulative, Dosed, Paramedic's dose*, Slow acting, Builds*
    (keystone), Rat's share, Lingers* (capstone).
- **Affixes.** Poison conversion (conv_poison_pct), poison increase (poison_pct), dot damage (dot_pct). Armour and
  resists, so you stay full and every heal overflows. Healing increase (heal_pct) doesn't feed it: the dose is a
  share of the tick, not of a heal.
- **The log line.** "The dose is coming back round."

## Doorman: Opened for good (bleed)

- **The loop.** The bleed has no cap. Won't stop means it never drains. On every kill it carries to the next man and
  grows by a quarter, so the pool compounds kill on kill. In the smoke's test, at an early site, it cleared a 400-man gang inside 20 seconds.
  Its ceiling is 10^30, kept short of infinity for the save.
- **Gear.**
  - The Carpet Man's, both: Carpet knife (Secondary), Fitter's knee pads. From level 13. The 2-piece is +30% bleed
    conversion and twice the bleed's seconds.
  - The Butcher's Steel, Primary, core. From level 14. Bleed ×2 more, and the bleed carries.
- **Points (44).**
  - Muscle: Heavy hands, Gym, Broad shoulders, Weights, Thick skin, Glassing*, Big frame, Bodyline, Spoils.
  - Blades: Stanley knife, An edge, Sharpened, Deep, Opened up, Doorman's glass*, Nicked, Butcher's, Won't stop*
    (keystone), Blood up, Bleed out* (capstone).
- **Affixes.** Bleed conversion (conv_bleed_pct), bleed increase (bleed_pct), dot damage (dot_pct). Melee wants
  armour and HP for the first second of each gang.
- **The log line.** "They're not closing up."

## Scrapper: Live load (shock)

- **The loop.** A kill on a shocked man adds a stack, and each stack is +2% to the shock's damage for the run. Daisy
  chain puts the shock on everyone on you and Arc holds it for as long as you fire. Every kill is a shocked kill, and
  the stacks add to every hit.
- **Gear.**
  - The Bank's, all 3: Branch blazer, Cashier's pen, Branch holdall. From level 18.
  - Jump Leads, Secondary, core. From level 14.
  - An improvised Primary. The Scrapper's joint shocks on every improvised hit.
- **Points (46).**
  - Stripping: Nose for parts, Quick fingers, Tools, Spare parts, Fast strip, Live wire*, Magpie eye, Nothing wasted,
    Bodger.
  - Live: Sparks, Charge, Off the mains, Amps, Current, Scrapper's mains*, Volts, Daisy chain* (keystone), Earthed,
    Arc* (capstone).
- **Affixes.** Shock conversion (conv_shock_pct) on the improvised gun, shock increase (shock_pct). Earthed costs a
  fifth of your armour: carry HP.
- **The log line.** "The current's building."

## Notes

- **Bugs found while mapping these.** Neither is fixed; both are Matt's call.
  1. An item's or a set's `first_pct` line isn't read in the fight. `_fight` reads the fitted parts, the class, the
     rounds' grade and the trees only. That affects the Army 3-piece, the Issue rifle, Jump Leads, the Lollipop and
     the Starting Pistol's lines.
  2. The Headmaster's Cap grants every notable and capstone of the class's trees, Hit and run included, though its
     comment says it keeps Hit and run out. Only keystones are left out.
- **No mythic in any build.** A mythic is one find in 10,000, which can't be built toward by hand. The proposal said
  "one mythic"; these use a findable unique instead.
- **Two builds at once.** Each combo checks its own class, so two can't be on together.

# The broken builds

Agreed with Matt on 21 Oct; redone for the web and the skills on 24 Oct, with the Recruit's added (milestone 8). Each
class has one build that grows without a top over a run. It's made from three
things: the class's set at its count, one findable unique, and the keystone and capstone of the class's element. The
code is in `Data.COMBOS` and `Sim.combo_on`.

**Outside the balance.** The balance read switches them off (`Sim.combos_off` in tests/balance.gd), and the bot never
builds one on purpose.

**Hidden from the screens.** No screen describes them. The run log says one line, once per run, the first time it
catches. That line is the theorycrafter's hint.

**Per run.** The stacks belong to the run. They build kill on kill and are gone when you come home. A long run that
farms patrols after the clear is where they run away: stay out, no early extract.

**Points.** Each build needs four nodes: the class lane's joint half, the element's class half, the element's keystone
(level 20) and its capstone (level 30). `Data.COMBOS[...]["recipe"]` names them, and the smoke walks to each from an
empty web under the real gates, so a change to the trees that breaks a recipe goes red. The paths below are the
shortest walk the web gives today: 32 to 42 points, so about level 35 to 45. Fillers repeat their names along a lane
(Tough, Mending, Keen); take the ones the path runs through. None of the paths runs through a node that would stop
the stacks (Never there, Hit and run, Walking wounded). An asterisk (*) marks the four the build needs.

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
- **Points (36).**
  - Moving on: Light feet, Mending, Head start, Tough, Spray, Lucky, Bottle and rag*.
  - Petrol: A can of it, Hardy, Siphoned, Keen, Lit, Mending, Brisk, Drifter's can*, Tough, Spreads* (keystone), Lucky,
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
- **Points (36).**
  - Stalking: Still hands (the class's starter).
  - Snares: Quick hands, Nimble, Soft ground, Tough, Quiet feet, Hardy, Cold snap*.
  - The cold: De-icer, Mending, A hard winter, Tough, Chill, Nimble, Lucky, Poacher's snare*, Wrapped up, Frozen solid*
    (keystone), Hardy, Shatter* (capstone).
- **Affixes.** Frost conversion (conv_frost_pct) on the rifle, or a frost socketable. Frost and physical increase
  (frost_pct, physical_pct). Stalking's Rifleman and the Poacher's own +40% are the first shot's bonus that carries.
- **The log line.** "The cold's doing the work now."

## Paramedic: Overdose (poison)

- **The loop.** Your poison's ticks heal you 5% of what they deal. Healing past full HP becomes stacks: a max HP's
  worth is one stack, and each stack is +100% poison. More poison means more ticks, more healing and more stacks, a
  loop that feeds itself. It wants you at full HP, so it's at its best where they hit you least.
- **Gear.**
  - The Ambulance's, all 3: Ambulance rig, Green overalls, Crew helmet. From level 16.
  - The Rat Man's Bag, Backpack, core. From level 14. Poison stacks without a top, and it carries to the next man.
- **Points (42).**
  - Triage: Steady pulse, Tough, Kit bag, Hardy, Fast work, Keen, Syringe*.
  - The Rat Man: Under the sink, Nimble, Council issue, Hardened, Dosed, Slow acting, Hardened, Nimble, Paramedic's
    dose*, Hardy, Rat's share, Builds* (keystone), Mending, Lingers* (capstone).
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
- **Points (32).**
  - Muscle: Heavy hands, Keen, Broad shoulders, Brisk, Shotgunner, Mending, Glassing*.
  - Blades: Stanley knife, Tough, Sharpened, Lucky, Opened up, Clotted, Nimble, Doorman's glass*, Hardy, Won't stop*
    (keystone), Keen, Bleed out* (capstone).
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
- **Points (42).**
  - Stripping: Nose for parts, Lucky, Tools, Nimble, Bodger, Tough, Live wire*.
  - Live: Sparks, Keen, Off the mains, Brisk, Current, Volts, Brisk, Keen, Scrapper's mains*, Mending, Earthed, Daisy
    chain* (keystone), Nimble, Arc* (capstone). Earthed is on the way and costs a fifth of your armour.
- **Affixes.** Shock conversion (conv_shock_pct) on the improvised gun, shock increase (shock_pct). Earthed costs a
  fifth of your armour: carry HP.
- **The log line.** "The current's building."

## Recruit: Drilled (physical)

- **The loop.** A kill while one of his skills is running (any timed effect: Suppressing fire, Smoke, Make ready's
  shots) adds a stack, and each stack is +3% to the physical share of every hit for the run. Bust
  them up takes their armour and resist out of the physical share and keeps it physical; Flattened halves the next
  man's fire after a physical kill. More damage means more kills inside each skill's window, and Make ready and Stand
  to keep a window open most of a fight.
- **Gear.**
  - The Army's, 3 pieces: Issue helmet, Issue carrier, Issue bergen. From level 23. (The Poacher wants all four; the
    Recruit leaves the Issue rifle for his own.)
  - The Quartermaster's Rifle, Primary, chase, off the Quartermaster (the head that opens the Recruit). It never runs
    out of rounds.
- **Points (42).**
  - Ordnance: Pull the pin, Keen, Spare pouch, Brisk, Cook it off, Mending, Brute force*.
  - Knuckles: Bare hands, Tough, Half a brick, Hardy, Stagger, Weight behind it, Hardy, Tough, Recruit's boots*, Keen,
    Heavy, Bust them up* (keystone), Tough, Flattened* (capstone).
- **Skills.** Make ready, Suppressing fire and Smoke, all on auto: one is nearly always running. Stand to and Quick
  march keep them coming round.
- **Affixes.** Physical increase (physical_pct), cooldowns (cdr_pct) and energy (energy_regen_pct) on the non-weapon
  slots. Heavy costs 15% pace: carry attack speed (attack_pct).
- **The log line.** "The drill's taking over."

## Notes

- **Bugs found while mapping these (21 Oct), both fixed the same day** (Matt: "fix both"): an item's or a set's
  "first of each gang" line now reaches the fight, and the Headmaster's Cap leaves out keystones, the nodes with a
  cost (Hit and run) and, since 24 Oct, the skills.
- **No mythic in any build.** A mythic is one find in 10,000, which can't be built toward by hand. The proposal said
  "one mythic"; these use a findable unique instead.
- **Two builds at once.** Each combo checks its own class, so two can't be on together. The Army's set serves the
  Poacher's (four pieces) and the Recruit's (three) for the same reason.

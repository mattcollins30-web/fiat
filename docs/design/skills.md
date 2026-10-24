# Milestone 8: active skills, energy, the sixth class, the unlock order, the Pitch

Agreed 24 Oct with Matt. This is the design to build from. It changes numbers everywhere, so it all lands before the
balance pass, which moves to milestone 9. Every figure below is a first figure, there to make the sim run; the
balance pass tunes them. The names and on-screen lines are the language pass's (section 11): section 4 gives what each skill does, section 11
the exact words the player sees.

Matt's brief: "Our skill tree has no skills and fights devolve into watching bats and clicking meds. We need active
skills ... 8 per character with 3 available for a fight. We then need an energy system plus a cooldown reduction
affix."

---

## 1. Decisions

| # | Question | Decision |
|---|---|---|
| 1 | Who fires a skill | **Auto, with manual override.** Every slotted skill has a rule and fires on it by itself. Watching, you can fire it yourself, and a switch on each slot turns its rule off. |
| 2 | Energy regen and pace | **Its own base rate, plus a small share of pace.** Pace keeps its job (a run's speed, the fight clock). |
| 3 | Skills and meds | **Defensive skills clear damage over time; meds stay the flat heal.** Skills clear bleed, poison, burn, frost and shock and ward against them for a few seconds. |
| 4 | Which classes | **All six,** 48 skills in this milestone. |
| 5 | The sixth class | **The Recruit**, folded in now so the tree is built once. |
| 6 | Unlock order | **One class at the start, the rest unlocked by bosses** (section 6). |

The sim, the odds' dry runs and the bot all fight with skills through the same auto rules. A watched
fight and an unwatched one are the same fight unless you press something.

---

## 2. Energy

| | First figure | Notes |
|---|---|---|
| Pool | 100 | Starts full each fight. |
| Base regen | 4 a second | About 280 more over a 70-second fight: 8 to 10 casts across three skills. |
| From pace | A quarter of pace's bonus | Pace 1.20 gives +5% regen. Pace builds feel it; it doesn't take over. |
| Between fights | Refills | A run's fights don't drain into each other. |

**Three new affixes** go into the item affix pool:

| Affix | Effect | Cap | Rolls on |
|---|---|---|---|
| Cooldown reduction | Every skill's cooldown shortened | 40% | The non-weapon slots, tiered like other affixes |
| Energy regen | Regen +% | none | The non-weapon slots |
| Max energy | Pool + flat | none | The non-weapon slots |

Some passive nodes feed these too, most of all the Recruit's Drill lane (section 5).

**Cost and cooldown.** Every skill has both. Energy limits how often you cast overall; a cooldown stops one skill
being cast over and over. So cooldown reduction helps every skill, and regen helps the cheap, frequent ones.

---

## 3. How skills work

### Learning them

- **The tree teaches them.** Each class has 8 skill nodes, 4 on each of its two lanes. On each lane the first three
  sit at notable depth and the fourth, the class's signature for that lane, sits at keystone depth.
- **A skill node takes a notable's place.** It costs a point like any node and has the skill's own picture and its own
  ring, so it reads as a skill at a glance. Where it displaces a notable, that notable's passive moves to a filler
  nearby or is dropped, decided per class in the build.
- **Only your class's skills.** Another class's half isn't yours, as now.

### Loading them

- **Three slots, set before a run** on the Runs card, beside the rig. The picker shows the skills you've learned with
  their cost, cooldown and rule. The slots lock when you set off.
- **The bot** fills its three by its build: the highest-scoring damage skill, the cleanse that matches the site's
  damage type, and a control or defensive skill.

### The auto rules

Each skill carries one rule, shown on its slot:

| Rule | Fires when |
|---|---|
| On cooldown | Ready and enough energy |
| Pressed | 3 or more on you |
| Hurting | HP under half |
| Ailing | A damage-over-time effect on you (its own type for the specific cleanses) |
| Finisher | A figure under a quarter HP |
| Opener | In the first 5 seconds of a fight |
| Last stand | You'd go down (a once-a-run skill that sits reserved) |

When two skills want to fire on the same tick, the more expensive one goes first and the other waits a tick.

### In the fight frame

- **An energy bar** under Your HP.
- **Three skill buttons** at the frame's foot, each with its picture, a cooldown sweep, a cost that greys when you
  can't afford it, and a small "auto" pip that the switch turns off.
- **When a skill fires:** a short flash on its button, a word over the frame ("Collared"), the effect on the figure
  it hits, then the beat where the numbers land.
- **Mockups** on the design canvas before any UI is built: the frame with buttons and bar, and the loadout picker.
  *Agreed 24 Oct (canvas "Fiat – Skills in the fight, the picker, the Pitch"; Matt: "this spot"):* the energy bar under
  Your HP at its size, in #7d8ff0; the three skills as 76 px picture buttons at the frame's foot, between the bars and
  the hands; on each the picture, the cost under it, a pip (A for auto, a dash off), the cooldown as a dark sweep with
  the seconds, a cost it can't meet in red with the picture grey. Press fires; right-click (hold on the Deck) switches
  auto. The name, line, chip and rule on hover. Firing: the button lights, the name over the frame for a beat, the man
  hit ringed with his state ("Stunned 3 s"). The numbers that land on you move up clear of the buttons. The picker:
  a SKILLS row on the Runs card (Conditions gives up its empty half) - three pictures and a button that opens the
  picker over the map, both lanes, the picked three numbered with an amber edge, ones not learned faded.

---

## 4. The 48 skills

Format: **Name** - what it does. Cost / cooldown in seconds. *Auto rule.*

### The Poacher - Stalking and Snares (the starting class)

He's the only class for the first stretch, so his first skills are simple and hit hard.

**Stalking**
1. **Clean shot** - the next shot does ×2.5 damage. 25 / 8. *On cooldown.*
2. **Flush them out** - the far one is pulled to the middle and takes +20% damage for 8 s. 30 / 15. *When a far one stands.*
3. **Go to ground** - drop out of sight for 3 s, untouchable; clears bleed and poison. 35 / 25. *Ailing or Hurting.*
4. **One for the pot** (signature) - a figure under a quarter HP drops outright; never a boss, who takes a heavy hit instead. 50 / 30. *Finisher.*

**Snares**
5. **Collared** - the nearest is stunned for 3 s and can't fire. 25 / 12. *Pressed (2 or more).*
6. **Gin trap** - the next one to step up takes a big hit and bleeds. 30 / 15. *Opener, then on cooldown.*
7. **Decoy** - the gang's fire drops 30% for 6 s while they turn on it. 35 / 20. *Hurting.*
8. **Net every hole** (signature) - every figure is stunned for 2 s and bleeds. 60 / 40. *Pressed.*

### The Paramedic - Triage and Shifts (the Clinic doctor's apprentice)

The cleanse class: most of the game's debuff answers live here, and her signature is the one way back from going down.

**Triage**
1. **Tourniquet** - clears bleed; warded against it for 10 s. 20 / 12. *Ailing (bleed).*
2. **Antidote** - clears poison and burn; warded for 8 s. 25 / 15. *Ailing (poison, burn).*
3. **Adrenaline** - +25% damage and rate of fire for 8 s. 30 / 20. *Pressed.*
4. **Major incident** (signature) - clears every debuff on you, and the run's next wound doesn't happen. 55 / 40. *Ailing (two or more).*

**Shifts**
5. **Two sugars** - energy regen +50% for 10 s. 15 / 25. *On cooldown.*
6. **Sedative dart** - one figure sleeps for 4 s and wakes when hit. 25 / 14. *Pressed.*
7. **Strapped up** - the next hit that would wound you doesn't. 30 / 25. *Hurting.*
8. **Code blue** (signature) - when you'd go down, you're back up at 30% with your debuffs cleared. Once a run; its 60 energy stays reserved. *Last stand.*

### The Doorman - Muscle and The door (the Carpet Man's old bodyguard)

Control and armour: he decides who gets in.

**Muscle**
1. **Shoulder charge** - a heavy hit on the nearest, knocking him back to the far spot. 25 / 10. *On cooldown.*
2. **Headbutt** - a hit and a 2 s stun. 20 / 9. *Pressed.*
3. **Brace** - armour +60% for 6 s. 30 / 18. *Pressed (3 or more).*
4. **Barred** (signature) - the nearest is thrown out of the fight: counted down, drops nothing. Not on bosses. 60 / 45. *Pressed.*

**The door**
5. **Not on the list** - one fewer on you for 10 s. 30 / 20. *Pressed.*
6. **Shutters down** - get behind the wall: 80% less damage for 4 s. 35 / 22. *Hurting.*
7. **Pat down** - one figure loses his armour and resists for 10 s. 25 / 15. *Opener, then on cooldown.*
8. **Chucking-out time** (signature) - everyone on you is stunned for 2 s, then you deal +50% damage to all for 6 s. 60 / 40. *Pressed.*

### The Scrapper - Stripping and Fencing (the bank's repair man)

Kit and wiring: shock and fire, ammo, and paying his way out.

**Stripping**
1. **Ring main** - a shock that jumps through three figures. 25 / 9. *On cooldown.*
2. **Hot work** - a strong burn on the nearest. 25 / 10. *On cooldown.*
3. **Breakdown** - the next one killed drops 20 rounds. 20 / 15. *When the gun's low.*
4. **Short circuit** (signature) - shock on everyone, a 1.5 s stun, shock damage +30% for 6 s. 60 / 40. *Pressed.*

**Fencing**
5. **Bung** - pay 20 tins: one figure stops fighting for 8 s. 20 / 20. *Pressed.* The only skill with a cost outside energy (Matt: keep it).
6. **Knock-off kit** - your gun's damage +30% for 8 s. 30 / 18. *On cooldown.*
7. **Back of the van** - makes one grenade from scrap. Once a fight. 40 / -. *When the rig has no grenade.*
8. **Everything must go** (signature) - for 5 s every shot fires twice. 60 / 45. *Opener.*

### The Recruit - Ordnance and Drill (the Quartermaster's recruit who walked out with the stores)

The class built around skills: he casts most often, and his passives make everyone's casting cheaper.

**Ordnance**
1. **Lob one in** - throws a grenade without spending one. 25 / 10. *Pressed.*
2. **Flashbang** - everyone on you stunned for 1.5 s, their fire −50% for 4 s. 30 / 16. *Pressed (3 or more).*
3. **Smoke** - their fire misses half the time for 6 s. 30 / 18. *Hurting.*
4. **Danger close** (signature) - a big blast on every figure; you take 10% of your max HP. 60 / 40. *Pressed, and only above half HP.*

**Drill**
5. **Suppressing fire** - the gang's rate of fire −35% for 8 s. 30 / 18. *Pressed.*
6. **Make ready** - +25% damage for the next 10 shots. 15 / 8. *On cooldown.*
7. **Stand to** - +30 energy now and every cooldown 2 s shorter. 0 / 30. *On cooldown.*
8. **Fire and manoeuvre** (signature) - for 10 s every skill costs half and cooldowns run at double speed. 60 / 50. *Opener.*

### The Drifter - Moving on and Luck (found on the road after Kev's first story)

Last to arrive: evasion, big single hits and chance.

**Moving on**
1. **Duck and weave** - the next three hits miss. 25 / 12. *Pressed.*
2. **Look lively** - pace and rate of fire +40% for 6 s. 30 / 18. *On cooldown.*
3. **Elbow room** - the ones on you are pushed back a step: their fire −25% and your damage +15% for 8 s. 30 / 18. *Pressed.* (Replaces Leg it, the once-a-run escape from death: Matt, "change" - surviving death stays Code blue's alone.)
4. **Gone** (signature) - out of sight for 4 s, untouchable; the next shot does triple damage. 60 / 40. *Hurting.*

**Luck**
5. **Coin toss** - a 50/50: double damage for 8 s, or nothing. 20 / 10. *On cooldown.*
6. **Close shave** - the next debuff that would land on you misses. 25 / 15. *Ailing.*
7. **Chancer** - the next one downed drops better loot. 30 / 20. *Finisher.*
8. **Jackpot** (signature) - for 8 s every kill takes 2 s off every cooldown. 60 / 45. *Opener.*

### What the sim needs to support

Most of these build on effects the fight already has: hits, damage over time, armour, resists, ducking, the
number on you, grenades. New to the sim:

- stunned and asleep figures;
- wards against a damage type;
- your misses and dodges;
- a figure thrown out of the fight;
- the once-a-run Last stand;
- energy and cooldown changes made by skills themselves.

Each needs a smoke check.

---

## 5. The Recruit

| | |
|---|---|
| Who | A recruit from the Barracks who walked out with the stores. Unlocked by beating the Quartermaster. |
| Lanes | **Ordnance** and **Drill**. |
| On the wheel | The free spoke at 0°: the five classes sit at -120, -60, 60, 120 and 180, so his wheel goes on the right without moving the others. |
| Elements his lanes lean on | Petrol (fire) and Knuckles (physical) for Ordnance. Drill has none of its own. |

**Ordnance** (passives): grenade damage %, more grenades carried, a grenade hits one more figure, blast damage burns,
damage against the wall's far side (the far one).

**Drill** (passives): energy regen %, cooldown reduction, rate of fire %, the gang's fire −% while a skill is running,
reload speed.

Like the others, each lane has four skill nodes (section 4), notables, a keystone and fillers. He needs a bridge to an
element tree like the other classes.

**Art** (through the art handoff, after the slice reads with test art): a portrait (128), a full figure (208x488),
two region emblems (96), about 30 node pictures (64) and his 8 skill icons.

---

## 6. The unlock order

| Beaten | Unlocks | Who they are |
|---|---|---|
| (start) | the Poacher | The hunter |
| The Gamekeeper | the Clinic, the Paramedic | The Clinic doctor's apprentice: the doctor stays, she runs |
| The Carpet Man | the Doorman | His old bodyguard |
| The Bank Manager | the Fence, the Scrapper | The bank's repair man |
| The Quartermaster | the Recruit | The recruit who walked out with the stores |
| Kev's first story | the Drifter | Found on the road |

- **One runner.** You switch class at the Yard as now. The runner's level and the Pitch carry over; a new class's half
  of the tree starts empty.
- **Saves break.** By the standing rule: SAVE_VERSION goes up, with the warning on the old slot.
- **What it moves:**
  - The bot's early runs and the balance gates are re-based on the Poacher instead of the Drifter.
  - The Poacher's first ten nodes and first two skills must carry a new player through the Outskirts on their own.
  - Each class's arrival is a moment worth a room card or a radio line; the words are written in the build.
- **The Clinic and the Fence** already unlock from somewhere. They move to these bosses, and the rooms' current unlock
  conditions go.

---

## 7. The Pitch's tree

Three things, the first two before anything else in the milestone:

1. **The buy button doesn't show its cost.** It reads like Train: "Build (6,000 tins)", greyed with the shortfall
   when you can't afford it. A smoke check makes every buy button on the Pitch show its price. *Done 24 Oct:* a pick
   reads "Build (2,500 tins, 3 copper)", shorter when it won't fit; a rank reads just "Buy (79,000 tins)" (Matt: the
   rank is in the title). Ranks have no cap, so the title says "rank 1", not "1/10".
2. **Nodes for the removed offline progress go.** Overtime ("tins found while you're away come in a quarter higher")
   and anything else reading time away is replaced with an effect during runs. The build lists each one and its
   replacement for Matt before changing it. *Done 24 Oct (Matt: "remove all offline stuff"):* the catch-up is gone
   too - the world waits while the game is shut, a run out included (SAVE_VERSION 7). The Generator's away side
   becomes energy (the language pass's names; the skill engine reads them, until then they do nothing):

   | Was | Now | Short | Words |
   |---|---|---|---|
   | Twelve hours | Jerry can | +10 max energy | Max energy +10 |
   | A day away | Dynamo | +0.5 energy a second | Energy refills 0.5 more a second |
   | Overtime | Kickback | +5 energy a kill | Every kill gives 5 energy |
   | Two days | Flywheel | 5% shorter cooldowns | Every skill's cooldown is 5% shorter (inside the 40% cap) |
   | The grid | Pilot light | First skill free | Each fight, your first skill costs no energy |
   | Rank: +3% tins while away | | +2 max energy | Max energy +2 a rank |

   Skills start every fight ready (Opener needs it), so the agreed "first skill ready at once" did nothing; Pilot
   light makes the first skill free instead. Names changed in the pass: Spare cells ("cells" is stash room), Live
   wire and Capacitor (both perks already), Mains (Off the mains). The five new pictures need an art run.
3. **The binary choices become a real tree.** Each building's column is a fork today (a or b, one locks the other).
   Proposed: each column becomes a small group of nodes you can rank up, two or three per column with a trade-off
   between them, so a building grows in the direction you choose rather than being picked once. Mocked up on the
   design canvas before it's built. *Agreed 24 Oct (Matt: "B"):* nothing locks - either side of a column builds
   first at its price, the other later at 2.5 times it, today's figures untouched. Refit goes (nothing to refit).
   Option A (three ranks a column, shared) was the other on the canvas.

---

## 8. Smoke checks to add

- **Energy and cooldowns:** energy never goes below 0 or over the pool; cooldown reduction never passes its cap; a
  skill never fires without its energy or off cooldown.
- **Auto rules:** each rule fires when its condition holds and not otherwise, on a staged fight.
- **Manual override:** a pressed skill fires once; a slot switched off never fires by itself.
- **The odds:** two dry runs with the same build, one with skills and one without, read differently (the odds see
  skills).
- **Each new state:** stunned, asleep, warded, thrown out, Last stand; each has an effect that ends on time.
- **Classes:** every class has 8 skills on its tree, 4 a lane, each reachable.
- **Loadout:** three slots, locked on setting off.
- **Unlocks:** each boss unlocks its class (and room); a fresh camp has only the Poacher.
- **The fight frame:** three buttons and the energy bar fit (the fit check).
- **The Pitch:** every buy button shows its cost; no node reads time away.
- **The Recruit:** sits on the wheel's free spoke, clear of the others (the overlap checks).

---

## 9. Build order

Each slice is smoked, reviewed and committed before the next.

1. **The Pitch's quick fixes** (section 7, 1 and 2). Small; the Pitch stops reading broken.
2. **Mockups:** the fight frame with buttons and bar, the loadout picker, the Pitch's columns.
3. **The engine with the Poacher's 8:** energy, cooldowns, auto rules, the new states, the loadout, the fight UI, the
   bot and the odds reading skills. Played before going on.
   *3a, the sim (24 Oct):* `Data.SKILLS`, the energy constants, `sim._skills_tick` in `_fight` before the hit, the
   loadout and its switches saved, the odds' key reading them. How the design maps onto the sim's fight (one man in
   front, a count on you):
   - A fight is a gang (the head is his own): each starts with full energy, every skill ready, the last fight's
     timed effects gone; a set Gin trap stays for the next man. A convoy joining a fight in progress refills nothing.
   - The crowd rules count everyone in the fight, not just those firing (Matt's call 3); a head counts as one.
   - Clean shot's "next shot" is the next second of fire. "Opener, then ready" acts as When ready (a fight's
     cooldowns start at 0).
   - Stunned men are a share of their fire, not figures; Net every hole's bleed lands on the man in front, Flush them
     out's +20% on whoever you're shooting. A skill's own hit (Gin trap, One for the pot) skips resists and shock.
   - Timed effects count by the share of a tick they cover, so the odds' 2 s steps read them as play does.
   - Still to come in 3b-3d: the skill nodes on the tree (and only your class's skills), the three affixes, the fight
     buttons and the picker, the bot's three.
4. **The other four existing classes' skills,** 32 more.
5. **The Recruit:** his lanes on the wheel, his 8 skills.
6. **The unlock order** and its words.
7. **The Pitch's columns** (section 7, 3).
8. **Art:** 48 skill icons (about $3.84 at $0.08 a 64 px job) and the Recruit's set, through the art handoff.
9. **Then milestone 9: balance.**

---

## 10. Settled with Matt (24 Oct)

1. **The sixth class is the Recruit** (not the Deserter, the Squaddie).
2. **Bung keeps its tin cost.**
3. **Leg it is changed:** the Drifter's third Moving on skill is Back off; surviving death is Code blue's alone.
4. **One for the pot and Barred never work on bosses.**
5. **Every player-facing word here went through the language pass** (section 11) before going into the game.

---

## 11. The words (the language pass, 24 Oct)

Two reviewers, each briefed with docs/language/style_guide.md, the approval summary and every existing name; my call on
their lists below. Their full reports: docs/language/review_m8_a.md and review_m8_b.md.

### What changed and why

- **Seventeen names renamed** for clashes with existing nodes in the same class or lane (Lie low/Lying up, Blowlamp/
  Blowtorch, Bounce/Bouncing, Not tonight/Not today, Steady on/Steady pulse, Graveyard shift/Night shift and the lane's
  other shifts, Set the lines/Snare lines and Trapline, Lucky break/Lucky and Lucky find, Hot-wire/Live wire), for
  echoing their own lane's name (Triage call, Hold the door, On the move, Mag drill), for two pairs that read alike in
  a list (Back off/Back of the van, Fire sale/Fire and manoeuvre), and Frag out (an American callout).
- **Words the game doesn't use:** figure (a number on screen) becomes *man*, *the nearest man*, *everyone on you*;
  boss becomes *head*; downed becomes *kill*; going down becomes "a hit that would kill you"; debuff becomes *ailment*;
  frost on the runner is a *chill*; held becomes *stunned*; warded becomes "no new bleed lands"; "drops outright" (reads
  as loot) becomes "dies at once"; better loot becomes *loot quality*; magazine (a gun part) becomes *rounds*.
- **Crits don't exist in the game.** Rather than add a mechanic, Clean shot and Gone say "×2.5 damage" and "triple
  damage", and Jackpot's trigger becomes a kill.
- **Reloads don't exist.** Make ready (was Mag drill) is "+25% damage for your next 10 shots"; Breakdown drops rounds.
- **Vague amounts get first figures:** a big hit is a multiple of your shot's damage, so it scales with the gun.
- **The rule labels:** On cooldown reads as "recharging" (the opposite), Pressed as "when you press it", Hurting
  against the glossary's *hurt* (any HP below full). They become When ready, 3+ on you, Under half HP. The rules
  outside the seven get their own labels.
- **Facts:** the head of the Bank is *the Manager*; a class is picked in **Training**, not the Yard; the Manager also
  opens the Yard and the Quartermaster the Radio and the Workshop, so their unlock lines say so.

### The 48 on screen

Name · the line under it · its rule chip. Cost and cooldown show on the slot as a chip ("25 energy · 8 s").

**The Poacher**
| Skill | Line | Rule |
|---|---|---|
| Clean shot | Your next shot does ×2.5 damage | When ready |
| Flush them out | Pulls the man at the back to the middle; he takes 20% more damage for 8 seconds | 3+ on you |
| Go to ground | Out of sight for 3 seconds: nothing can hit you. Clears bleed and poison on you. | Ailing |
| One for the pot | A man on you under 25% HP dies at once. A head takes ×5 damage instead. | Finisher |
| Collared | The nearest man is stunned for 3 seconds: he can't fire | 2+ on you |
| Gin trap | The next man to join the fight takes ×3 damage and starts to bleed | Opener, then ready |
| Decoy | Everyone on you does 30% less damage to you for 6 seconds | Under half HP |
| Net every hole | Everyone on you is stunned for 2 seconds and starts to bleed | 3+ on you |

**The Paramedic**
| Skill | Line | Rule |
|---|---|---|
| Tourniquet | Clears bleed on you; no new bleed lands for 10 seconds | Bleeding |
| Antidote | Clears poison and burns on you; neither lands again for 8 seconds | Poisoned or burning |
| Adrenaline | +25% damage and rate of fire for 8 seconds | 3+ on you |
| Major incident | Clears every ailment on you, and you take no wound this run | 2+ ailments |
| Two sugars | Energy refills 50% quicker for 10 seconds | When ready |
| Sedative dart | The nearest man sleeps for 4 seconds; a hit wakes him | 3+ on you |
| Strapped up | The next hit that would wound you leaves no wound | Under half HP |
| Code blue | Once a run, a hit that would kill you leaves you on 30% HP with every ailment cleared | Last stand |

**The Doorman**
| Skill | Line | Rule |
|---|---|---|
| Shoulder charge | Hits the nearest man for ×3 damage and sends him to the back | When ready |
| Headbutt | Hits the nearest man for ×1.5 damage and stuns him for 2 seconds | 3+ on you |
| Brace | +60% armour for 6 seconds | 3+ on you |
| Barred | The nearest man is out of the fight: he counts as a kill but drops nothing. Never works on a head. | 3+ on you |
| Not on the list | One fewer on you for 10 seconds | 3+ on you |
| Shutters down | Take 80% less damage for 4 seconds | Under half HP |
| Pat down | The nearest man loses his armour and resists for 10 seconds | Opener, then ready |
| Chucking-out time | Everyone on you is stunned for 2 seconds, then takes 50% more damage from you for 6 seconds | 3+ on you |

**The Scrapper**
| Skill | Line | Rule |
|---|---|---|
| Ring main | ×1.5 shock damage that jumps through 3 men | When ready |
| Hot work | Sets the nearest man burning for ×2 fire damage over 4 seconds | When ready |
| Breakdown | The next man you kill drops 20 rounds for your gun | Low on rounds |
| Short circuit | Shocks everyone on you and stuns them for 1.5 seconds. Your shock damage +30% for 6 seconds. | 3+ on you |
| Bung | Pay 20 tins: the nearest man is stunned for 8 seconds | 3+ on you |
| Knock-off kit | +30% gun damage for 8 seconds | When ready |
| Back of the van | Puts a grenade in your rig. Once a fight. | No grenade |
| Everything must go | For 5 seconds, every shot fires twice | Opener |

**The Recruit**
| Skill | Line | Rule |
|---|---|---|
| Lob one in | Throws a grenade at everyone on you without using one from your rig | 3+ on you |
| Flashbang | Stuns everyone on you for 1.5 seconds; they do 50% less damage to you for 4 seconds | 3+ on you |
| Smoke | Half their shots at you miss for 6 seconds | Under half HP |
| Danger close | ×4 blast damage to everyone on you; you lose 10% of max HP | 3+ on you, over half HP |
| Suppressing fire | Everyone on you fires 35% slower for 8 seconds | 3+ on you |
| Make ready | +25% damage for your next 10 shots | When ready |
| Stand to | Gives 30 energy and takes 2 seconds off every cooldown | When ready |
| Fire and manoeuvre | For 10 seconds, skills cost half and cooldowns pass twice as quickly | Opener |

**The Drifter**
| Skill | Line | Rule |
|---|---|---|
| Duck and weave | The next 3 hits on you miss | 3+ on you |
| Look lively | +40% pace and rate of fire for 6 seconds | When ready |
| Elbow room | Everyone on you does 25% less damage to you and takes 15% more from you, for 8 seconds | 3+ on you |
| Gone | Out of sight for 4 seconds: nothing can hit you. Your next shot does triple damage. | Under half HP |
| Coin toss | A 50% chance of double damage for 8 seconds | When ready |
| Close shave | The next ailment that would land on you misses | Ailing |
| Chancer | The next man you kill always drops something, at +50% loot quality | Finisher |
| Jackpot | For 8 seconds, every kill takes 2 seconds off every cooldown | Opener |

### The rest on screen

| Thing | Words |
|---|---|
| Rule labels | When ready · 2+ on you · 3+ on you · Under half HP · Ailing (tooltip: "An ailment on you: a bleed, burn, poison, chill or shock") · Bleeding · Poisoned or burning · 2+ ailments · Finisher (tooltip: "Fires when a man on you is under 25% HP") · Opener (tooltip: "Fires in the first 5 seconds of a fight") · Opener, then ready · Last stand (tooltip: "Fires when a hit would kill you; its energy is kept back all run") · Low on rounds · No grenade · 3+ on you, over half HP |
| The slot | Auto / Auto off; cost chip "25 energy · 8 s", "Free · 30 s", "20 energy · 20 tins · 20 s", "40 energy · once a fight", "60 energy kept back · once a run" |
| The bar | Your energy 60 / 100 (tooltip: "What skills cost. Refills 4 a second, a little quicker with pace, and fills at the start of every fight.") |
| Affixes | 8% shorter cooldowns (Stats: "Cooldowns 32% shorter, 40% at most") · +8% energy gain · +10 max energy |
| Places in the fight | the nearest man · the middle · the man at the back, each with a tooltip where it first shows |
| The class | the Recruit; lanes Ordnance and Drill; his line "Walked out of the Barracks with the stores." |
| Unlocks | Beat the Gamekeeper: the Clinic opens, and Training offers the Paramedic · Beat the Carpet Man: Training offers the Doorman · Beat the Manager: the Fence and the Yard open, and Training offers the Scrapper · Beat the Quartermaster: the Radio and the Workshop open, and Training offers the Recruit · After Kev's first story, Training offers the Drifter |
| Flavour, per unlock | The Paramedic: "The doctor's apprentice. The doctor keeps the Clinic; she goes out." · The Doorman: "The Carpet Man's old bodyguard." · The Scrapper: "The Bank's repair man." · The Drifter: "Found on the road." |
| The fight's buttons (24 Oct pass) | Pip "Auto" / "Off" (tooltip "Auto off"). Hover: the name; the line; the cost chip ("25 energy · 12 s"); the rule on its own line; "Right-click to turn auto off" / "…on", by the state. State chips over a man hit: "Stunned 3 s", "Asleep 4 s", "Bleeding". |
| The picker (24 Oct pass) | Card head SKILLS; button "Change skills" (no ▾: it opens a picker, not a setting); title "Skills for the run"; under it "Pick 3 you've learnt. They lock when you set off."; lane heads in caps; a row not learnt: "Learn it in Training"; footer "3 of 3 picked · press one to take it out"; "Done"; fewer learnt: "2 learnt · learn more in Training". |
| The Pitch, nothing locks (24 Oct pass) | Neither side built: "Or Kickback: every kill gives 5 energy" as now. The other side built: "Jerry can is built · this one costs ×2.5". The refit lines and verb go; the second side's button is "Build (…)". |

### Matt's calls (settled 24 Oct)

1. **"Skill" is unbanned** and has its own glossary entry (style guide v3): something you slot before a run and fire
   in a fight; costs energy and has a cooldown. *Perk* stays the point bought in Training; "skill node" and "loadout"
   stay off screen. *Ailment* and *energy* join the glossary too.
2. **Code blue replaces Not today.** Surviving a killing hit once a run is Code blue's; the Not today keystone gets a
   new effect, put to Matt when the Paramedic's tree is built.
3. **"3+ on you" counts everyone in the fight**, not just the ones firing, so Chokepoints, One at a time and fog don't
   switch those skills off. The rule's tooltip says so.
4. **The Paramedic is the Clinic doctor's apprentice.** They come as a pair: beating the Gamekeeper opens the Clinic
   with the doctor in it, and Training offers the Paramedic, who runs while the doctor stays. Her line: "The doctor's
   apprentice. The doctor keeps the Clinic; she goes out." (The vet's bag is no longer her link; the doctor's name is
   checked against the radio's medic in the build.)
5. **The Scrapper keeps both:** the Bank's repair man who stripped the estate's cars for copper on the side.
6. **Style guide v3:** affix lines number first ("+8% damage"); "8 seconds" in lines, "8 s" in chips.

# Language review A: milestone 8 (skills, energy, the Recruit, unlocks)

Read against style guide v2, the approval summary, existing_names.txt, affix_stats.txt and scripts/sim/data.gd (with sim.gd and items.gd where a fact needed checking).

## 1. Summary

The design's words describe mechanics the game doesn't have and use terms the glossary bans. **"Skill" is a banned variant of "perk"** (and "node" and "loadout" are banned too), so the whole feature needs a glossary decision before any line ships. **"Figure" means a number on screen** ("new figures"), not a man. **"Boss" is "head"**, and the boss is "the Manager", not "the Bank Manager". **"Debuff" and "damage over time" are used for five things** (bleed, poison, burn, frost, shock), but on screen damage over time covers only burns, poison and bleeds. The frost ailment is a **chill**, not "frost". Crits, reloads and magazines, and positions on the field (nearest, far one, middle, back, step up) **do not exist on screen yet**. Seven skills lean on them, and each one needs a defined term or a rewrite. Three auto-rule labels mislead a first-time player. **"On cooldown"** reads as "still recharging", the opposite of what it means. **"Pressed"** collides with pressing the button yourself, and with the Pressure node. **"Hurting"** contradicts the glossary, where hurt means below full HP, not under half. Eight skills also carry rules that aren't among the seven. There are two design overlaps. **Code blue repeats Not today**, the Paramedic's existing keystone in the same class ("Once a run, a hit that would kill you leaves you on half HP instead"), so "surviving death is Code blue's alone" is not true. **Steady on and Triage call both stop the run's one wound.** Nine skill names clash with existing names, five of them inside the same class: Lie low/Lying up, Set the lines/Snare lines, Steady on/Steady pulse, Blowlamp/Blowtorch and On the move/Moving on. Not tonight/Not today and Bounce/Bouncing are in the same tree. Most of the design's lines also need figures where they say "a big hit", "a strong burn" or "a heavy hit". The proposed lines use **N** wherever the design gives no figure.

## 2. Changes

Skill lines are the mechanics line under the name. Cost and cooldown show separately on the slot (see the chip row near the end). Seconds are written out in sentences ("for 8 seconds") and shortened only in chips ("first 2 s"), as data.gd does. **N** marks a figure the design doesn't give. "Ailment" is the proposed glossary term for a burn, poison, bleed, chill or shock (see Glossary notes); if Matt rejects it, write the five out in full.

### Skills: the Poacher

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Clean shot | the next shot crits for 250% | Your next shot does ×2.5 damage | clarity | Crit isn't a term on screen; × is the house multiplier |
| Flush them out | the far one is pulled to the middle and takes +20% damage for 8 s | Pulls the farthest man in; he takes 20% more damage for 8 seconds | clarity | "Far one" and "middle" are undefined positions; seconds written out |
| Flush them out (rule) | When a far one stands | One far off | fit | Not one of the seven rules; it needs its own label |
| Lie low (name) | Lie low | Into the bracken | clash | Lying up is a node in the same lane (Stalking) |
| Into the bracken (line) | drop out of sight for 3 s, untouchable; clears bleed and poison | Take no damage for 3 seconds; clears bleeds and poison on you | clarity | "Untouchable" is a new state; the house line for it is "you take no damage" (Clean hands) |
| Into the bracken (rule) | Ailing or Hurting | Ailment on you or under half HP | fit | Compound rule, outside the seven |
| One for the pot | a figure under a quarter HP drops outright; never a boss, who takes a heavy hit instead | Kills a man under 25% HP outright; the head takes N damage instead | glossary | figure → man; boss → head; no "a quarter"; "heavy hit" needs a figure |
| Wire snare | the nearest is held for 3 s and can't fire | The nearest man is stunned for 3 seconds | glossary | "Held" is a Doorman capstone and the Radio's word for signals; it means the same as stunned (see Glossary notes) |
| Wire snare (rule) | Pressed (2 or more) | Two or more on you | clarity | The threshold has to be on the label |
| Gin trap | the next one to step up takes a big hit and bleeds | The next man to reach you takes N damage and bleeds | clarity | "Step up" is an undefined position; "big hit" needs a figure |
| Gin trap (rule) | Opener, then on cooldown | First 5 s, then when ready | fit | Compound rule |
| Decoy | the gang's fire drops 30% for 6 s while they turn on it | Everyone on you fires 30% slower for 6 seconds | glossary | House form for rate: "fire 25% slower"; "while they turn on it" is flavour |
| Set the lines (name) | Set the lines | Pegged out | clash | Snare lines is a node in the same lane (Snares) |
| Pegged out (line) | every figure is held for 2 s and bleeds | Stuns everyone on you for 2 seconds and makes them bleed | glossary | figure → everyone on you; held → stunned |

### Skills: the Paramedic

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Tourniquet | clears bleed; warded against it for 10 s | Clears bleeds on you; no bleed can land for 10 seconds | clarity | "Ward" is a Yard pick's name (Rest +1 HP/s); say what it does |
| Tourniquet (rule) | Ailing (bleed) | Bleed on you | clarity | Plain condition |
| Antidote | clears poison and burn; warded for 8 s | Clears poison and burns on you; neither can land for 8 seconds | clarity | As Tourniquet; the name is kept, though an antidote clearing burns reads oddly |
| Antidote (rule) | Ailing (poison, burn) | Poison or burn on you | clarity | Plain condition |
| Adrenaline | +25% damage and rate of fire for 8 s | +25% damage and rate of fire for 8 seconds | register | Seconds written out; matches the existing "+20% damage and pace for 8 seconds" |
| Triage call | clears every debuff on you, and the run's next wound doesn't happen | Clears every ailment on you; no wound this run | glossary | "Debuff" isn't a game word; a run only ever takes one wound (sim.gd _wound), so "next" adds nothing |
| Triage call (rule) | Ailing (two or more) | Two ailments on you | fit | Compound rule |
| Graveyard shift (name) | Graveyard shift | Two sugars | clash | It would be the sixth "shift": Shifts (its own lane), Night shift, Second shift, Double shift, Long shift (already renamed for a clash) |
| Two sugars (line) | energy regen +50% for 10 s | +50% energy gain for 10 seconds | glossary | "Regen" is never on screen; uses the affix's label (below) |
| Sedative dart | one figure sleeps for 4 s and wakes when hit | One man on you sleeps for 4 seconds, or until he's hit | glossary | figure → man. Fact: if it picks your target, the next shot wakes him, so it has to pick someone else |
| Steady on (name) | Steady on | Patched up | clash | Steady pulse is a node in the same class (Triage), and Steady hands is a Yard pick |
| Patched up (line) | the next hit that would wound you doesn't | The next hit that would wound you doesn't | clarity | The line is kept. Design overlap: with one wound a run it does the same as Triage call's second clause |
| Code blue | when you'd go down, you're back up at 30% with your debuffs cleared. Once a run; its 60 energy stays reserved | Once a run, a hit that would kill you leaves you on 30% HP, ailments cleared · holds 60 energy back | glossary | House form from Not today ("a hit that would kill you"). Fact: Not today already does this in Shifts, so either one goes or they need telling apart |

### Skills: the Doorman

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Shoulder charge | a heavy hit on the nearest, knocking him back to the far spot | The nearest man takes N damage and is knocked to the back | clarity | Needs a figure; "far spot" is an undefined position |
| Headbutt | a hit and a 2 s stun | Your target takes N damage and is stunned for 2 seconds | clarity | Say who it hits ("target" is the on-screen word) and give a figure |
| Brace | armour +60% for 6 s | +60% armour for 6 seconds | register | Number-first like the other buffs in the list; seconds written out |
| Brace (rule) | Pressed (3 or more) | Three or more on you | clarity | "(3 or more)" is already Pressed's own threshold; the label now carries it |
| Bounce (name) | Bounce | Out on his ear | clash | Bouncing is a node in the same class (The door) |
| Out on his ear (line) | the nearest is thrown out of the fight: counted down, drops nothing. Not on bosses | Throws the nearest man out of the fight: it counts as a kill, but he drops nothing; not the head | glossary | boss → head; one line, not two |
| Not tonight (name) | Not tonight | Not on the list | clash | Not today is the Paramedic's keystone; the two read as the same thing |
| Not on the list (line) | one fewer on you for 10 s | One fewer on you for 10 seconds | register | Seconds written out; "one fewer on you" is the house idiom |
| Hold the door | get behind the wall: 80% less damage for 4 s | Take 80% less damage for 4 seconds | register | Effect first, as in Bodyline; "behind the wall" is flavour |
| Pat down | one figure loses his armour and resists for 10 s | Your target loses his armour and resists for 10 seconds | glossary | figure → target |
| Pat down (rule) | Opener, then on cooldown | First 5 s, then when ready | fit | Compound rule |
| Chucking-out time | everyone on you is stunned for 2 s, then you deal +50% damage to all for 6 s | Stuns everyone on you for 2 seconds, then +50% damage for 6 seconds | clarity | "To all" adds nothing: damage applies to everyone anyway |

### Skills: the Scrapper

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Hot-wire | a shock that jumps through three figures | Shocks your target for N, then jumps to 2 more on you | glossary | figure → men on you; needs a figure |
| Blowlamp (name) | Blowlamp | Hot work | clash | Blowtorch is a notable in the same class (Fencing), and the two are the same tool |
| Hot work (line) | a strong burn on the nearest | Burns the nearest man for N fire damage | clarity | "Strong" needs a figure |
| Breakdown | the next one downed drops a magazine for your gun | The next man you kill drops N rounds | glossary | Glossary says rounds; "magazine" is a gun part (Extended magazine, Drum magazine) |
| Breakdown (rule) | When the gun's low | Low on rounds | fit | Not one of the seven; there is no reload, so "low" has to mean the rig's rounds |
| Short circuit | shock on everyone, a 1.5 s stun, shock damage +30% for 6 s | Shocks and stuns everyone on you for 1.5 seconds; +30% shock damage for 6 seconds | clarity | Three fragments become one line |
| Bung | pay 20 tins: one figure stops fighting for 8 s | Your target stops fighting for 8 seconds; costs 20 tins as well | glossary | Effect first, cost after; figure → target |
| Knock-off kit | your gun's damage +30% for 8 s | +30% gun damage for 8 seconds | register | Matches "Improvised gun damage +40%"; seconds written out |
| Back of the van | makes one grenade from scrap. Once a fight | Puts a grenade in your rig; once a fight | clarity | Scrap is home stock, not carried; "from scrap" is flavour unless it really spends scrap (if it does, give the figure) |
| Back of the van (rule) | When the rig has no grenade | No grenade in the rig | fit | Not one of the seven |
| Fire sale | for 5 s every shot fires twice | Every shot hits twice for 5 seconds | clarity | "A shot fires" is muddled; effect first |

### Skills: the Recruit

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Frag out | throws a grenade without spending one | Throws a grenade at everyone on you; uses none from the rig | clarity | Say where it lands (grenades hit everyone on you) and where it would have come from |
| Flashbang | everyone on you stunned for 1.5 s, their fire −50% for 4 s | Stuns everyone on you for 1.5 seconds; they fire 50% slower for 4 seconds | glossary | House form for rate |
| Flashbang (rule) | Pressed (3 or more) | Three or more on you | clarity | As Brace |
| Smoke | their fire misses half the time for 6 s | Half their shots miss for 6 seconds | clarity | Effect first; "their fire" reads as rate elsewhere |
| Danger close | a big blast on every figure; you take 10% of your max HP | N damage to everyone on you; you lose 10% of max HP | glossary | figure → everyone on you; needs a figure |
| Danger close (rule) | Pressed, and only above half HP | Three or more on you, over half HP | fit | Compound rule |
| Suppressing fire | the gang's rate of fire −35% for 8 s | Everyone on you fires 35% slower for 8 seconds | glossary | "The gang" is every man on the site; the effect is on the ones on you |
| Mag drill | an instant reload; the next magazine does +25% damage | +25% damage for your next N shots | clarity | Fact: the game has no reload and no magazine count, only a pool of rounds in the rig |
| Mag drill (rule) | When the gun's low | When ready | fit | With no reload, "the gun's low" has nothing to trigger on |
| Stand to | +30 energy now and every cooldown 2 s shorter | +30 energy, and 2 seconds off every cooldown | clarity | "2 s shorter" with no duration reads as permanent; the design means a one-off cut |
| Fire and manoeuvre | for 10 s every skill costs half and cooldowns run at double speed | Skills cost half and cooldowns pass twice as quickly for 10 seconds | glossary | Effect first; glossary says quicker, not faster or speed |

### Skills: the Drifter

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Duck and weave | the next three hits miss | The next 3 hits on you miss | register | Figures in mechanics; say whose hits |
| On the move (name) | On the move | On your toes | clash | Moving on is its own lane, and Keep moving is a node in it |
| On your toes (line) | pace and rate of fire +40% for 6 s | +40% pace and rate of fire for 6 seconds | register | Number-first like the other buffs; seconds written out |
| Back off | the ones on you are pushed back a step: their fire −25% and your damage +15% for 8 s | Everyone on you fires 25% slower and takes 15% more damage for 8 seconds | clarity | "A step" is flavour and an undefined position |
| Gone | out of sight for 4 s, untouchable; the next shot crits at ×3 | Take no damage for 4 seconds; your next shot does triple damage | clarity | Crit isn't a term on screen; "triple" is allowed |
| Coin toss | a 50/50: double damage for 8 s, or nothing | A 50% chance of double damage for 8 seconds | glossary | Glossary says chance; "or nothing" goes without saying |
| Lucky break (name) | Lucky break | Near miss | clash | Lucky is a trait (Jammy was renamed off it), Lucky find is a node in the same lane, and there are Lucky penny and Lucky Cap too |
| Near miss (line) | the next debuff that would land on you misses | The next ailment that would land on you doesn't | glossary | "Debuff" isn't a game word |
| Near miss (rule) | Ailing | Ailment on you | clarity | See the rules table |
| Chancer | the next one downed drops better loot | The next man you kill drops something, at +N% loot quality | glossary | "Better loot" is banned; the glossary term is loot quality |
| Jackpot | for 8 s every crit takes 1 s off every cooldown | For 8 seconds, every crit takes 1 second off every cooldown | clarity | Crits have to exist and be defined (tooltip) before this ships; if they don't, the skill needs a new trigger |

### The sixth class and its lanes

No change. "Recruit" and its lanes Ordnance and Drill clash with nothing and are capped like the other classes ("the Poacher" mid-sentence). Watch for any "Recruit" button verb near the class name. Mag drill echoes the lane name, but Matt renamed only exact echoes before (Live, Triage), so it is noted under Clashes rather than changed.

### Affixes

The line format follows items.gd affix_lines: "+8% damage" for a percentage key, "+5 max HP" for a flat one.

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Cooldown reduction | Every skill's cooldown shortened (cap 40%) | **8% shorter cooldowns** · short "−8% cooldown" · key `cooldown_less_pct` · Stats tooltip "Cooldowns are at most 40% shorter" | clarity | Follows crowd_less_pct ("8% less damage with three or more on you", no plus) because it cuts a duration. "+% cooldown" would read as longer. Code: the formatter's no-plus case needs this key |
| Energy regen | Regen +% | **+8% energy gain** · short "+8% energy/s" · key `energy_regen_pct` | glossary | "Regen" never shows on screen (HP regen is "HP a second"). The plain key `regen` is taken by HP |
| Max energy | Pool + flat | **+10 max energy** · short "+10 energy" · key `max_energy` | fit | Parallels `hp` → "max HP"; a bare `energy` key would read as the current pool in code |

### Auto-rule labels

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Rule | On cooldown | When ready | clarity | In every game "on cooldown" means "recharging, can't fire", the opposite of this rule |
| Rule | Pressed | Three or more on you (short "3+ on you"); "Two or more on you" for Wire snare | clarity | Clashes with pressing a button yourself (the manual override) and with the Pressure node; "three or more on you" is the house idiom (Bodyline, crowd_less_pct) |
| Rule | Hurting | Under half HP | glossary | The glossary says hurt means below full HP; "under half HP" is the house phrase (Iron, Walking wounded) |
| Rule | Ailing | Ailment on you (or the specific one: "Bleed on you", "Poison or burn on you") | glossary | Plain condition; uses the ailment term (Glossary notes) |
| Rule | Finisher | A man under 25% HP | clarity | Jargon; no "quarter"; figure → man |
| Rule | Opener | First 5 s | clarity | "Opens" already means rooms and crates; seconds shortened as a chip ("first 2 s") |
| Rule | Last stand | Last stand (no change), tooltip "On a hit that would kill you; its energy is held back all run" | clarity | Kept as a label; the tooltip gives the rule in house words |
| Rules (design) | "Each skill carries one rule" from the seven | Add the eight compound labels above (One far off; Ailment on you or under half HP; First 5 s, then when ready; Two ailments on you; Low on rounds; No grenade in the rig; Three or more on you, over half HP; Two or more on you) | fit | Eight skills use rules outside the seven; every label needs a fit check on the slot |

### UI words

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Energy bar text | (an energy bar under Your HP) | Your energy 60 / 100 | fit | Matches "Your HP 91 / 160" and "Their HP" in run.gd |
| Energy (first show) | Energy | Energy, with tooltip "Skills spend energy; it refills 4 a second, and fully between fights" | clarity | A new term, so it needs a one-line definition like Guard and pace |
| Cost and cooldown chip | 25 / 8 | 25 energy · 8 s | clarity | A bare "25 / 8" reads like a pack or HP count ("3 / 9") |
| Cooldown chip, once-only | 40 / - ; "Once a run; 60 energy reserved" | 40 energy · once a fight; 60 energy · once a run | clarity | No hyphen standing in for a value |
| Auto pip | auto | Auto | caps | Chip text is sentence case |
| Auto pip, off | (the switch turns it off) | Auto off | caps | Matches "Auto-run off" |
| Picker title | the loadout picker | Skills | glossary | "Loadout" is banned (it means kit); title it with the agreed word for skill |

### Unlock lines (section 6)

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Unlock, the Gamekeeper | The Gamekeeper → the Clinic, the Paramedic | Beat the Gamekeeper to open the Clinic and unlock the Paramedic | clarity | Rooms open (the Map intro says "Each one opens a room"); a class unlocks |
| Who, Paramedic | The girl who patched up his dogs (his vet's bag) | She patched up the Gamekeeper's dogs | clarity | "His" has no referent on its own; the brackets are a design note. "Girl" reads young for a paramedic. Section 4 calls her "the Gamekeeper's apprentice", so one of the two should go |
| Unlock, the Carpet Man | The Carpet Man → the Doorman | Beat the Carpet Man to unlock the Doorman | clarity | Same form |
| Who, Doorman | His old bodyguard | The Carpet Man's old bodyguard | clarity | "His" has no referent |
| Unlock, the Manager | The Bank Manager → the Fence, the Scrapper | Beat the Manager to open the Fence and the Yard and unlock the Scrapper | glossary | The head is "The Manager" (data.gd BOSSES); he also opens the Yard, so the line must say so |
| Who, Scrapper | The bank's repair man | The Bank's repair man | caps | The Bank is a site, so it keeps its capital |
| Unlock, the Quartermaster | The Quartermaster → the Recruit | Beat the Quartermaster to open the Radio and the Workshop and unlock the Recruit | fact | He already opens both rooms (data.gd BOSSES); a line naming only the Recruit misleads |
| Who, Recruit | The recruit who walked out with the stores | Walked out of the Barracks with the stores | clarity | Doesn't repeat the class name; names the place |
| Unlock, the Drifter | Kev's first story → the Drifter | Kev's first story unlocks the Drifter | clarity | It isn't a fight, so "Beaten" doesn't fit |

## 3. Clashes

| New name | Clashes with | Where | Proposed |
|---|---|---|---|
| Lie low | Lying up (Stalking node) | same lane | Into the bracken |
| Set the lines | Snare lines (Snares node) | same lane | Pegged out |
| Steady on | Steady pulse (Triage node), Steady hands (Yard pick) | same class | Patched up |
| Graveyard shift | Shifts (lane), Night shift, Second shift, Double shift, Long shift | same lane | Two sugars |
| Blowlamp | Blowtorch (Fencing notable) | same class; same tool | Hot work |
| On the move | Moving on (lane), Keep moving (node) | same lane | On your toes |
| Not tonight | Not today (Paramedic keystone) | across classes; one word apart | Not on the list |
| Bounce | Bouncing (The door node) | same class | Out on his ear |
| Lucky break | Lucky (trait), Lucky find (Luck node), Lucky penny, Lucky Cap | same lane | Near miss |
| Pressed (rule) | Pressure (Triage node); the act of pressing a skill | UI | Three or more on you |
| Held (state) | Held (Doorman capstone); signals "held" on the Radio | UI | Stunned |
| Warded (state) | Ward (Yard pick) | UI | Spelled out ("no bleed can land") |

Noted, no rename proposed (Matt's call):

- **Triage call / Triage** and **Mag drill / Drill**: a skill name holding its lane's name. Matt renamed only exact echoes before.
- **Hold the door / The door** (lane) and **Hold**, the Radio action.
- **Clean shot** sits in the same lane as **One shot** and **Long shot**.
- **Shoulder charge / Shoulder, Charge** (nodes).
- **Short circuit / Circuits**.
- **Stand to / Stand and fight** (and Last stand).
- **Suppressing fire / Suppressor** (gun part).
- **Hot-wire / Live wire, Wired**.
- **Back off / Keep back** (a Doorman node; this is the Drifter).
- **Gone / Ghost / Never there**: the same lane, all about not being seen.
- **Headbutt** is a compound of "head" and reads fine, but it is the only skill that brushes the head-means-the-head rule.

## 4. Glossary notes

- **Skill.** The glossary bans "skill" (with node and talent) as a variant of perk, and the smoke fails on it. Before any of this ships, add an entry: "skill: an active ability a perk teaches, slotted before a run". Take "skill" off perk's banned list, and give it a first-show tooltip. "Skill node" and "loadout" stay off screen.
- **Figure** is a number on screen ("The same affixes, new figures"). An enemy is a man or one, or "your target" for the one being shot (data.gd: "the target dies", "chilled targets").
- **Boss → head.** "The Bank Manager" is **the Manager** on screen.
- **Damage over time** covers burns, poison and bleeds only (dot_pct: "burn, poison and bleed damage"; "Damage over time ×2; chill, shock last ×2"). The five together have no name. Proposal: **ailment** (a burn, poison, bleed, chill or shock), with a tooltip where it first shows; "debuff" never goes on screen.
- **Frost → chill.** Frost is the damage type; the thing on you is a chill, as burn is to fire.
- **Held, stunned, asleep, "stops fighting".** These are four words for close states. If held and stunned both mean "can't fire", use stunned for both. Keep asleep only because a hit ends it. Bung's "stops fighting" should be stunned too, unless it really differs.
- **Untouchable and warded** are new states. The house already says "you take no damage for 3 seconds" (Clean hands); say "no bleed can land" for a ward.
- **Crit** has no mechanic or term on screen. Clean shot, Gone and Jackpot depend on it. The first two are reworded; Jackpot needs crits defined, or a new trigger.
- **Reload and magazine** aren't mechanics; rounds are a pool in the rig, and magazines are gun parts. This affects Breakdown and Mag drill.
- **Positions** (nearest, far one, middle, back, step up, "the wall's far side") are new. If the fight frame shows places, give them one name each (nearest and farthest are proposed) and a tooltip. Otherwise reword the lines to "your target" or "everyone on you". The Ordnance passive "a grenade hits one more figure" contradicts how grenades already work: they hit everyone on you (data.gd).
- **The runner dies, not "goes down".** The house line is "a hit that would kill you" (Not today). Enemies are killed or die, not "downed".
- **Better loot → loot quality.**
- **Rate vs damage.** In sentences their rate is "fire N% slower"; the runner's is "rate of fire" (the attack_pct label) or pace. Don't use "their fire −N%" for both.
- **Regen** is never on screen. HP regen is "HP a second", so energy's is "energy gain".
- **Fight** is undefined on screen: the frame says THE FIGHT, then GANG 2. Energy "refills between fights" and Opener's "first 5 seconds of a fight" need it pinned down: per gang, or per site visit?
- **The Yard** is the tree of works on the Pitch. Section 6 says you switch class "at the Yard", but class lives in Training (barracks.gd). Use Training if this reaches the screen.
- **Camp → game** ("a fresh camp" in section 8): internal only, but banned if it reaches the screen.
- **Seconds.** In sentences write "for 8 seconds"; shorten to "s" only in chips. The design's "8 s" in lines is the chip form.

# Milestone 8 words: review B

## 1. Summary

The biggest problem is vocabulary. The skill lines use words the game doesn't have, or uses for something else. Enemies are "figures" (the glossary says man or one). There are "bosses" (head) and "debuffs" (no word on screen covers bleed, burn, poison, chill and shock together). There are "crits", and nothing on screen has ever mentioned a crit. "Held" is already the Doorman's capstone and the Radio's "signals held". "Warded" sits beside the Yard pick Ward. "Drops outright" reads as loot, because "drops" means loot everywhere else. "Magazine" is a gun part item. And "skill" itself is a banned variant of "perk" in the glossary, so the smoke will fail on the feature's own name. The second problem is the auto-rule labels. "On cooldown" reads as the opposite of "ready". "Pressed" reads as "when you press it" on a button you can press. "Hurting" contradicts the glossary's "hurt" (any HP below full). Seven skills also use rules that aren't in the list. Third, 16 name clashes. Most sit inside one class: Blowlamp next to Blowtorch, Hot-wire next to Live wire, Bounce next to Bouncing, Not tonight next to Not today, Steady on next to Steady pulse, Graveyard shift next to Night shift, Lie low next to Lying up, Set the lines next to Snare lines. Five echo their own lane's name (Triage call, Hold the door, On the move, Mag drill, Wire snare). Two pairs look alike: Back off and Back of the van, Fire sale and Fire and manoeuvre. Code blue also does what the Not today keystone already does, in the same lane. Fourth, many lines don't say who is hit ("one figure") or by how much ("a big hit", "a heavy hit", "a strong burn", "better loot"). Last, two unlock lines contradict the classes' own past lines, and one names a head who doesn't exist ("the Bank Manager"; the data calls him the Manager).

## 2. Changes

Format of a proposed skill: **Name** · on-screen line · rule chip. A name in bold that differs from the current one is a rename. Lines with one sentence take no full stop; lines with two take full stops (guide section 4). `[N]` marks a figure the design doesn't give; the line can't ship without it. Durations are "seconds" in lines and "s" in the cost chip (see Glossary notes).

### The Poacher

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Stalking 1 | Clean shot – the next shot crits for 250%. *On cooldown* | **Clean shot** · Your next shot is a crit for ×2.5 damage · When ready | clarity | "Crits for 250%" can read as +250%. "×" for multipliers. "Crit" isn't on any screen today, so it needs a tooltip (Glossary notes). |
| Stalking 2 | Flush them out – the far one is pulled to the middle and takes +20% damage for 8 s. *When a far one stands* | **Flush them out** · Pulls the man at the back to the middle; he takes 20% more damage for 8 seconds · 3+ on you | clarity | "When a far one stands" isn't one of the seven rules. A man stands at the back only when 3 are on you. The three places need fixed names (Glossary notes). |
| Stalking 3 | Lie low – drop out of sight for 3 s, untouchable; clears bleed and poison. *Ailing or Hurting* | **Go to ground** · Out of sight for 3 seconds: nothing can hit you. Clears bleed and poison on you. · Ailing | clash | Lie low and Lying up (a filler in the same lane) mean the same thing. "Untouchable" is new; say what it does. A skill carries one rule, and this one had two. |
| Stalking 4 | One for the pot – a figure under a quarter HP drops outright; never a boss, who takes a heavy hit instead. *Finisher* | **One for the pot** · A man on you under 25% HP dies at once. A head takes ×[N] damage instead. · Finisher | glossary | "Figure" becomes man, "boss" becomes head, and no "quarter". "Drops outright" reads as a loot drop; "dies at once" is the house phrase (One shot). "A heavy hit" needs a figure. |
| Snares 5 | Wire snare – the nearest is held for 3 s and can't fire. *Pressed (2 or more)* | **Collared** · The nearest man is stunned for 3 seconds: he can't fire · 2+ on you | clash | Four snare names already exist (Snares the lane, Poacher's snare, Snare lines, Snare and wait). "Held" is already the Doorman's capstone and the Radio's held signals; "stunned" is the one can't-fire state (Glossary notes). |
| Snares 6 | Gin trap – the next one to step up takes a big hit and bleeds. *Opener, then on cooldown* | **Gin trap** · The next man to join the fight takes ×[N] damage and starts to bleed · Opener, then ready | clarity | "Step up" is undefined and "a big hit" has no figure. The rule chip has to show both halves. |
| Snares 7 | Decoy – the gang's fire drops 30% for 6 s while they turn on it. *Hurting* | **Decoy** · Everyone on you does 30% less damage to you for 6 seconds · Under half HP | clarity | "Fire drops" could mean rate or damage. "Do N% less damage to you" is the house phrase (data.gd L2153). "While they turn on it" is flavour inside a mechanics line. |
| Snares 8 | Set the lines – every figure is held for 2 s and bleeds. *Pressed* | **Net every hole** · Everyone on you is stunned for 2 seconds and starts to bleed · 3+ on you | clash | Snare lines is a filler in the same lane, and Trapline is the lane's keystone. Netting every hole of a warren reads as "all of them". "Every figure" becomes "everyone on you", and "held" becomes "stunned". |

### The Paramedic

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Triage 1 | Tourniquet – clears bleed; warded against it for 10 s. *Ailing (bleed)* | **Tourniquet** · Clears bleed on you; no new bleed lands for 10 seconds · Bleeding | glossary | "Warded" is new and sits beside the Yard pick Ward. Say what it does. "Bleeding" is shorter than "Ailing (bleed)". |
| Triage 2 | Antidote – clears poison and burn; warded for 8 s. *Ailing (poison, burn)* | **Antidote** · Clears poison and burns on you; neither lands again for 8 seconds · Poisoned or burning | glossary | As Tourniquet. The name says only poison; the line has to carry the burn. |
| Triage 3 | Adrenaline – +25% damage and rate of fire for 8 s. *Pressed* | **Adrenaline** · Damage and rate of fire +25% for 8 seconds · 3+ on you | fit | Format only. The line follows the class-node form ("Damage +20% under half HP"), and "seconds" in a sentence. |
| Triage 4 | Triage call – clears every debuff on you, and the run's next wound doesn't happen. *Ailing (two or more)* | **Major incident** · Clears every ailment on you, and you take no wound this run · 2+ ailments | clash | The name has its own lane's name in it (Matt renamed the Triage notable to Fast work for this). "Debuff" isn't a game word. A run takes at most one wound (data.gd L2861), so "the run's next wound" is "no wound this run". |
| Shifts 5 | Graveyard shift – energy regen +50% for 10 s. *On cooldown* | **Glucose** · Energy refills 50% quicker for 10 seconds · When ready | clash | Night shift, a filler in the same lane, means the same thing. The lane already has Night, Long, Second and Double shift. "Regen" is on no screen, and "quicker" is the glossary word. |
| Shifts 6 | Sedative dart – one figure sleeps for 4 s and wakes when hit. *Pressed* | **Sedative dart** · The nearest man sleeps for 4 seconds; a hit wakes him · 3+ on you | clarity | "One figure" doesn't say which man. Check whether your own damage over time counts as "a hit". |
| Shifts 7 | Steady on – the next hit that would wound you doesn't. *Hurting* | **Strapped up** · The next hit that would wound you leaves no wound · Under half HP | clash | Steady pulse is in the same class (the rename of Steady hands). "Doesn't" can mean the hit misses or the wound doesn't happen; the line now says the second. If it means a miss, write "does no damage". |
| Shifts 8 | Code blue – when you'd go down, you're back up at 30% with your debuffs cleared. Once a run; its 60 energy stays reserved. *Last stand* | **Code blue** · Once a run, a hit that would kill you leaves you on 30% HP with every ailment cleared · Last stand · chip "60 energy kept back · once a run" | clarity | "Go down" becomes the house phrase from Not today. "Debuffs" becomes ailments. "Reserved" moves to the chip and avoids "held". The mechanic clashes with Not today (see Clashes). |

### The Doorman

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Muscle 1 | Shoulder charge – a heavy hit on the nearest, knocking him back to the far spot. *On cooldown* | **Shoulder charge** · Hits the nearest man for ×[N] damage and sends him to the back · When ready | clarity | "A heavy hit" has no figure, and "the far spot" isn't a term. |
| Muscle 2 | Headbutt – a hit and a 2 s stun. *Pressed* | **Headbutt** · Hits the nearest man for [N] damage and stuns him for 2 seconds · 3+ on you | clarity | It doesn't say who, or how much. |
| Muscle 3 | Brace – armour +60% for 6 s. *Pressed (3 or more)* | **Brace** · Armour +60% for 6 seconds · 3+ on you | fit | "Pressed (3 or more)" is the same as Pressed. One label. |
| Muscle 4 | Bounce – the nearest is thrown out of the fight: counted down, drops nothing. Not on bosses. *Pressed* | **Barred** · The nearest man is out of the fight: he counts as a kill but drops nothing. Never works on a head. · 3+ on you | clash | Bouncing is a filler in the Doorman's own The door lane. "Barred" is the club word for thrown out and not coming back. "Counted down" is unclear: if he pays no XP or tins, say so. Boss becomes head. |
| The door 5 | Not tonight – one fewer on you for 10 s. *Pressed* | **Members only** · One fewer on you for 10 seconds · 3+ on you | clash | Not today is the Paramedic's keystone; the names are one word apart. |
| The door 6 | Hold the door – get behind the wall: 80% less damage for 4 s. *Hurting* | **Shutters down** · Take 80% less damage for 4 seconds · Under half HP | clash | It has its lane's name (The door) in it, next to the Radio's Hold and the Yard's Hold fire. "Get behind the wall" names a wall that isn't on screen, and it's flavour in a mechanics line. |
| The door 7 | Pat down – one figure loses his armour and resists for 10 s. *Opener, then on cooldown* | **Pat down** · The nearest man loses his armour and resists for 10 seconds · Opener, then ready | clarity | "One figure" doesn't say which man. |
| The door 8 | Chucking-out time – everyone on you is stunned for 2 s, then you deal +50% damage to all for 6 s. *Pressed* | **Chucking-out time** · Everyone on you is stunned for 2 seconds, then takes 50% more damage from you for 6 seconds · 3+ on you | clarity | "+50% damage to all" can read as your hits reaching everyone (like Through the lot). If that is the design, write "your hits reach everyone on you, with 50% more damage". |

### The Scrapper

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Stripping 1 | Hot-wire – a shock that jumps through three figures. *On cooldown* | **Ring main** · [N] shock damage that jumps through 3 men · When ready | clash | Live wire is the shock notable in the same lane, and Daisy chain is already the game's word for shock going round. A ring main is the house circuit that goes round. Figures, not "three". |
| Stripping 2 | Blowlamp – a strong burn on the nearest. *On cooldown* | **Soldering iron** · Sets the nearest man burning for [N] fire damage · When ready | clash | Blowtorch is the Scrapper's fire notable; a blowlamp and a blowtorch are the same tool. "A strong burn" needs a figure. |
| Stripping 3 | Breakdown – the next one downed drops a magazine for your gun. *When the gun's low* | **Breakdown** · The next man you kill drops rounds for your gun · Low on rounds | glossary | A magazine is a gun part item (Extended, Drum, Quick magazine), so this reads as a gun-part drop. Rounds are the glossary word. "When the gun's low" isn't one of the seven rules. |
| Stripping 4 | Short circuit – shock on everyone, a 1.5 s stun, shock damage +30% for 6 s. *Pressed* | **Short circuit** · Shocks everyone on you and stuns them for 1.5 seconds. Your shock damage +30% for 6 seconds. · 3+ on you | clarity | "Shock damage +30%" doesn't say whose. "Everyone" becomes "everyone on you". |
| Fencing 5 | Bung – pay 20 tins: one figure stops fighting for 8 s. *Pressed* | **Bung** · Pay 20 tins: the nearest man is stunned for 8 seconds · 3+ on you · chip "20 energy · 20 tins · 20 s" | clarity | "One figure" doesn't say which man. "Stops fighting" would be a sixth state; if it differs from stunned (no hit breaks it, say), give it a word. The tin cost has to show on the chip too. |
| Fencing 6 | Knock-off kit – your gun's damage +30% for 8 s. *On cooldown* | **Knock-off kit** · Gun damage +30% for 8 seconds · When ready | fit | Format only. |
| Fencing 7 | Back of the van – makes one grenade from scrap. Once a fight. *When the rig has no grenade* | **Back of the van** · Puts a grenade in your rig. Once a fight. · No grenade · chip "40 energy · once a fight" | clarity | "From scrap" reads as spending the Workshop's scrap. If it does, say how much ("for 10 scrap"); if not, cut it. "When the rig has no grenade" isn't one of the seven rules. |
| Fencing 8 | Fire sale – for 5 s every shot fires twice. *Opener* | **Everything must go** · For 5 seconds, every shot fires twice · Opener | clash | "Fire sale" reads as fire damage in a class with a fire notable, and sits beside Fire and manoeuvre, another signature on the same Opener rule. The shop-window phrase keeps the Fencing joke and says "all of it". Check whether each double shot spends 2 rounds. |

### The Recruit

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Class name | the Recruit | the Recruit (keep, Matt's call) | fit | Keep. Two code notes. barracks.gd L826 and L983 and sim.gd L8443 lower-case the class ("a recruit"), which reads as a plain noun. On a Training card, a lone "Recruit" can read as a verb button. |
| Lanes | Ordnance, Drill | Ordnance, Drill (keep) | fit | Clear, British spelling, no clash. Renaming Mag drill (below) leaves "Drill" as the lane's own name. |
| Ordnance 1 | Frag out – throws a grenade without spending one. *Pressed* | **Lob one in** · Throws a grenade without using one from your rig · 3+ on you | register | "Frag out" is an American callout. Also say which grenade: [the rig's first, or a fixed type]. |
| Ordnance 2 | Flashbang – everyone on you stunned for 1.5 s, their fire −50% for 4 s. *Pressed (3 or more)* | **Flashbang** · Stuns everyone on you for 1.5 seconds; they do 50% less damage to you for 4 seconds · 3+ on you | clarity | "Their fire −50%" could mean rate or damage. The duplicate Pressed label goes. |
| Ordnance 3 | Smoke – their fire misses half the time for 6 s. *Hurting* | **Smoke** · Half their shots at you miss for 6 seconds · Under half HP | fit | Says plainly what misses. |
| Ordnance 4 | Danger close – a big blast on every figure; you take 10% of your max HP. *Pressed, and only above half HP* | **Danger close** · [N] blast damage to everyone on you; you lose 10% of max HP · 3+ on you, over half HP | clarity | "A big blast" needs a figure. "Every figure" could mean the whole gang or only the men on you. The rule is outside the seven. |
| Drill 5 | Suppressing fire – the gang's rate of fire −35% for 8 s. *Pressed* | **Suppressing fire** · Everyone on you fires 35% slower for 8 seconds · 3+ on you | glossary | "Fire N% slower" is the house phrase for their rate (data.gd L2155), and it keeps this apart from Decoy's "less damage". |
| Drill 6 | Mag drill – an instant reload; the next magazine does +25% damage. *When the gun's low* | **Make ready** · Reloads your gun at once; damage +25% until its next reload · Reloading | clash | It has the lane's name in it, and "magazine" is a gun part item. "Make ready" is the Army's load command. Nothing on screen has a reload today: if the sim adds one, add "reload" to the glossary. "The gun's low" means an empty magazine here but no rounds left on Breakdown, so they need two labels. |
| Drill 7 | Stand to – +30 energy now and every cooldown 2 s shorter. *On cooldown* | **Stand to** · Gives 30 energy and takes 2 seconds off every cooldown · When ready · chip "Free · 30 s" | clarity | "Every cooldown 2 s shorter" can read as for the rest of the fight. The line says it happens once; if it lasts, write "for the fight". |
| Drill 8 | Fire and manoeuvre – for 10 s every skill costs half and cooldowns run at double speed. *Opener* | **Fire and manoeuvre** · For 10 seconds, skills cost half and cooldowns run twice as fast · Opener | fit | Format only. |
| Who (section 5) | A recruit from the Barracks who walked out with the stores. Unlocked by beating the Quartermaster. | Flavour: "Walked out of the Barracks with the stores." Mechanics: see the unlock row. | fit | "A recruit" next to "the Recruit" repeats itself. The two voices go on separate lines. |

### The Drifter

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Moving on 1 | Duck and weave – the next three hits miss. *Pressed* | **Duck and weave** · The next 3 hits on you miss · 3+ on you | fit | Figures, and says whose hits. |
| Moving on 2 | On the move – pace and rate of fire +40% for 6 s. *On cooldown* | **Look lively** · Pace and rate of fire +40% for 6 seconds · When ready | clash | "On the move" is nearly the lane's own name (Moving on), next to Keep moving and Never still. |
| Moving on 3 | Back off – the ones on you are pushed back a step: their fire −25% and your damage +15% for 8 s. *Pressed* | **Elbow room** · Everyone on you does 25% less damage to you and takes 15% more from you, for 8 seconds · 3+ on you | clash | Back off and Back of the van (the Scrapper's) are one letter apart. "Pushed back a step" is flavour in a mechanics line, unless position changes something; if it does, say what. "Their fire" becomes the house phrase. |
| Moving on 4 | Gone – out of sight for 4 s, untouchable; the next shot crits at ×3. *Hurting* | **Gone** · Out of sight for 4 seconds: nothing can hit you. Your next shot is a crit for ×3 damage. · Under half HP | clarity | "Untouchable" says what it does now. The crit wording matches Clean shot. |
| Luck 5 | Coin toss – a 50/50: double damage for 8 s, or nothing. *On cooldown* | **Coin toss** · Half the time: double damage for 8 seconds. Otherwise nothing. · When ready | fit | "Half the time" is plain English; "a 50/50" is slang. |
| Luck 6 | Lucky break – the next debuff that would land on you misses. *Ailing* | **Close shave** · The next ailment that would land on you misses · Ailing | clash | Lucky, Lucky Cap, Lucky find and Lucky penny already exist, and the Luck perk was renamed Jammy for this exact reason. "Debuff" becomes ailment. |
| Luck 7 | Chancer – the next one downed drops better loot. *Finisher* | **Chancer** · The next man you kill always drops something; loot quality +[N]% · Finisher | glossary | "Better loot" is flavour-only in the glossary; loot quality is the term. "Downed" becomes kill. |
| Luck 8 | Jackpot – for 8 s every crit takes 1 s off every cooldown. *Opener* | **Jackpot** · For 8 seconds, every crit takes 1 second off every cooldown · Opener | clarity | The line is fine if crits exist. Nothing on screen names a crit today. If only Clean shot and Gone make crits, Jackpot does nothing for the Drifter's own build without Gone (question in Glossary notes). |

### Auto rules, energy, affixes

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Rule | On cooldown | When ready · tooltip "Fires whenever it's ready and you have the energy" | clarity | A skill "on cooldown" is one that can't fire, which is the opposite of this rule. |
| Rule | Pressed | 3+ on you (and 2+ on you for Collared) · tooltip "Fires when 3 or more are on you" | clash | On a button you can press, "Pressed" reads as "fires when you press it". The design itself uses "a pressed skill" for the manual press (section 8). A chip leads with the number. |
| Rule | Hurting | Under half HP | glossary | The glossary makes "hurt" any HP below full. The rule fires under half. "Under half HP" is the house phrase (Dead man's shoes, Iron). |
| Rule | Ailing | Ailing (keep) · tooltip "An ailment on you: a bleed, burn, poison, chill or shock". Specific forms: Bleeding · Poisoned or burning · 2+ ailments | glossary | Keep the word. It needs "ailment" defined (Glossary notes). The specific cleanses show their own type rather than "Ailing (bleed)". |
| Rule | Finisher | Finisher (keep) · tooltip "Fires when a man on you is under 25% HP" | clarity | The definition had "a figure" and "a quarter". |
| Rule | Opener | Opener (keep) · tooltip "Fires in the first 5 seconds of a fight". Add "Opener, then ready" for Gin trap and Pat down | clarity | "Opener, then on cooldown" is two rules. If it stays, it needs its own label. |
| Rule | Last stand | Last stand (keep) · tooltip "Fires when a hit would kill you. Its energy is kept back all run." | clarity | "You'd go down" and "reserved" become plain words. |
| Rules outside the list | When a far one stands · When the gun's low · When the rig has no grenade · Ailing or Hurting · Pressed, and only above half HP | 3+ on you · Low on rounds / Reloading · No grenade · Ailing · 3+ on you, over half HP | clarity | Seven skills use conditions the table doesn't list. Either add these labels to the table (and to the smoke's rule checks) or fold them in as proposed. |
| Energy | Energy | Energy (keep) · tooltip "What skills cost. Refills 4 a second, a little quicker with pace, and fills at the start of every fight." | glossary | It's a new term, so it needs a first-show tooltip. "Pool" and "regen" stay internal. |
| Auto pip | auto | Auto / Auto off · tooltip "Fires by its rule. Switch it off to fire it only yourself." | caps | Chip text is sentence case. The off state matches "Auto-run off". |
| Affix | Cooldown reduction | −8% cooldowns (short "cooldowns"; key `cooldown_pct`) · Stats: "Cooldowns −32% (40% at most)" | clarity | "Cooldown reduction +8%" is a double negative, and the number leads in affix lines. The cap shows where the total shows. |
| Affix | Energy regen | +10% energy a second (short "energy/s"; key `energy_regen_pct`) | glossary | It mirrors the HP regen affix's label "HP a second". "Regen" is on no screen. Keep it apart from the existing `regen` key, which is HP. |
| Affix | Max energy | +10 max energy (short "energy"; key `max_energy`, flat) | fit | It mirrors "max HP". |

### Unlock lines (section 6)

| item | current | proposed | kind | reason |
|---|---|---|---|---|
| Unlock, start | (start) the Poacher · "The hunter" | "The Poacher: the past you start with" · cut "The hunter" | cut | A poacher isn't a hunter, and his past line already says who he was ("Kept the village in rabbits…"). On screen a class is a "past" (barracks.gd L733). |
| Unlock, Gamekeeper | the Clinic, the Paramedic · "The girl who patched up his dogs (his vet's bag)" | "Beat the Gamekeeper: the Clinic opens, and Training offers the Paramedic" · flavour "She patched up the Gamekeeper's dogs from his own vet's bag." | fit | "His" reads as the Poacher's, the row above. "The girl" doesn't fit her past line ("Stayed on the ambulances after the pay stopped") and is the one patronising note in the cast. The radio medic already wants that vet's bag (words.gd L205), so a player may take the Paramedic for the Clinic's medic: decide whether they're the same person. |
| Unlock, Carpet Man | the Doorman · "His old bodyguard" | "Beat the Carpet Man: Training offers the Doorman" · flavour "The Carpet Man's old bodyguard." | clarity | Name him; "his" floats. |
| Unlock, Manager | The Bank Manager → the Fence, the Scrapper · "The bank's repair man" | "Beat the Manager: the Fence opens, and Training offers the Scrapper" · flavour "The Bank's repair man." | glossary | The head is "The Manager" in the data (data.gd L1324); "the Bank Manager" would be a second name. "The Bank" is a site, so it keeps its capital. His past line ("Stripped the estate's own cars for copper") should agree with "repair man"; one of the two needs a word. |
| Unlock, Quartermaster | the Recruit · "The recruit who walked out with the stores" | "Beat the Quartermaster: Training offers the Recruit" · flavour "Walked out of the Barracks with the stores." | fit | "The recruit" next to the class name the Recruit repeats itself. |
| Unlock, Kev | Kev's first story → the Drifter · "Found on the road" | "After Kev's first story, Training offers the Drifter" · flavour "Found on the road." (keep) | clarity | It isn't a fight, so not "beaten". |
| Section 6 wording | "You switch class at the Yard"; "unlocked by bosses"; "a fresh camp" | Training; heads; a new game | glossary | On screen a past is picked in Training, not the Yard. Boss becomes head, and camp becomes game. These words will end up in the room cards and radio lines that section 6 says get written in the build. |

## 3. Clashes

**With existing names** (all renamed in the table):

| New | Existing | Where it is | Proposed |
|---|---|---|---|
| Blowlamp | Blowtorch | Scrapper Fencing notable (fire) | Soldering iron |
| Hot-wire | Live wire; Daisy chain | Scrapper Stripping notable (shock), same lane; Daisy chain is the shock chain's name | Ring main |
| Bounce | Bouncing | Doorman The door filler | Barred |
| Not tonight | Not today | Paramedic Shifts keystone | Members only |
| Steady on | Steady pulse (and Steady hands) | Paramedic Triage filler, renamed from Steady hands for a clash | Strapped up |
| Graveyard shift | Night shift (synonym) and Long, Second, Double shift | Paramedic Shifts, same lane | Glucose |
| Lie low | Lying up (synonym) | Poacher Stalking filler, same lane | Go to ground (Soft ground is in the other lane; the verb sets them apart) |
| Set the lines | Snare lines; Trapline | Poacher Snares filler and keystone, same lane | Net every hole |
| Wire snare | Snares (lane), Poacher's snare, Snare and wait; Wire stock, Wired | Poacher | Collared |
| Triage call | Triage (its lane) | the ruling that renamed the Triage notable to Fast work | Major incident |
| Hold the door | The door (its lane); Hold; Hold fire | Doorman lane; Radio craft; Yard pick | Shutters down |
| On the move | Moving on (its lane); Keep moving | Drifter | Look lively |
| Mag drill | Drill (its lane); Extended, Drum, Quick magazine | Recruit lane; gun parts | Make ready |
| Lucky break | Lucky, Lucky Cap, Lucky find, Lucky penny | trait, unique, Fencing filler, charm (the Luck perk was renamed Jammy for this) | Close shave |

**Within the 48:**
- Back off (Drifter) and Back of the van (Scrapper): one letter apart in a list. Renamed Back off to Elbow room.
- Fire sale and Fire and manoeuvre: both signatures, both Opener, both start "Fire". Renamed Fire sale to Everything must go.

**State words that clash:**
- *held* (Wire snare, Set the lines): already the Doorman's capstone Held, the Radio's "signals held" and Held frequency, and the Town's "held by a crew". Replaced by *stunned*. If held really differs from stunned (they can fire but not move, say), the line has to say what held does, and it still needs another word (*snared*).
- *warded*: the Yard pick Ward is a rest bonus. Replaced by "no new bleed lands for N seconds".
- *drops* (One for the pot's "drops outright"): drops means loot everywhere. Replaced by "dies at once".

**Kept, but watch:**
- Shoulder charge sits next to Shoulder (the shotgun notable) and Charge (a shock filler). They're different trees and read as different things, so no change.
- Clean shot, One shot and Long shot are all in Stalking. One shot and One for the pot both kill outright in the same class. Distinct enough; don't add another "shot" there.
- Stand to sits next to Stand and fight, Stance and the Last stand rule. Different words in use; keep.
- Flashbang sits next to Flash hider and Flashpoint. Keep.

**Mechanical duplicates the names can't fix (for Matt):**
- **Code blue duplicates Not today.** Both are once a run: a hit that would kill you leaves you alive, on 30% HP against half. Both sit in the Paramedic's Shifts lane at keystone depth. Section 10.3 says "surviving death is Code blue's alone", but Not today (data.gd L1570) already does it. Recommendation: Code blue replaces Not today, or Not today gets a new effect.
- Go to ground (Poacher) and Gone (Drifter) do the same thing: out of sight, nothing can hit you. Different classes, so it's acceptable, but the lines should stay word-for-word parallel so the difference (the cleanse against the crit) shows.
- Strapped up and Major incident both prevent the run's one wound, in the same class.
- Ring main ("jumps through 3 men") and Short circuit ("shocks everyone on you") read the same while 3 are on you, which is the usual case.
- Six skills cut incoming damage. Keep their words apart: "do N% less damage to you" (Decoy, Flashbang, Elbow room), "fire N% slower" (Suppressing fire), "shots miss" (Smoke), "one fewer on you" (Members only).

## 4. Glossary notes

1. **"Skill" is banned.** The glossary lists skill as a banned variant of *perk*, so the smoke fails on every line here. Add *skill*: "an active thing you slot and fire; costs energy and has a cooldown". Keep *perk* for a point bought in Training. On the tree, call the node "a skill", not "a skill node", because *node* is banned too.
2. **New terms that need a first-show tooltip:** energy, cooldown, skill, signature (like keystone), ailment, stunned, asleep, crit (if kept), Auto, and each rule label.
3. **Ailment (proposed):** bleed, burn, poison, chill or shock on the runner. It replaces "debuff", which is on no screen. *Damage over time* (fire, poison, bleed) stays for the damage affixes and perks. Frost on the runner is *chill* (the game already says chilled), not "frost".
4. **States:** *stunned* (can't fire), *asleep* (can't fire; a hit wakes him), *out of the fight* (Barred). The game already has *staggered* ("loses a second of fire", Floored). Its tooltip should say how it differs from stunned, or the two read as one. One state word each; no *held*, no *warded*.
5. **Enemies:** *man* or *one*, never *figure*. *Head*, never *boss*. *Kill*, never *downed*. The runner *dies* ("a hit that would kill you"), never *goes down*.
6. **"On you"** means the men firing on you at once, as now. "Everyone on you" replaces "every figure" and "all", which could mean the whole gang. Question for Matt: a 3+ rule can never fire while Chokepoints (only 2 of a gang can fire on you) or One at a time is taken, or in Fog. That hits the Doorman hardest, and five of his eight skills are on that rule. Either the rule counts the men present rather than the men firing, or the Doorman's skills use 2+.
7. **Places in the fight:** the design uses "the nearest", "the far one", "the far spot", "the middle", "the wall" and "step up". The slots exist only in the debug tool (fight_placement.gd: middle, near, far). Fix three words, *the nearest*, *the middle* and *at the back*, and define them where they first show. Cut *the wall* unless it's drawn.
8. **Crit:** no screen names a crit today (the only use is a code comment in items.gd L1017). If crits exist outside skills, add *crit* with a tooltip and a Stats row. If only Clean shot and Gone make them, Jackpot needs another trigger.
9. **Rounds, not magazine:** magazines are gun part items. "Reload" isn't on screen; add it only if the fight models reloads (Make ready).
10. **Cost chip format:** "25 energy · 8 s", "Free · 30 s", "20 energy · 20 tins · 20 s", "60 energy kept back · once a run", "40 energy · once a fight". Lines say "8 seconds"; chips say "8 s". The guide's only time format is m:ss, so this needs Matt's nod as a house rule.
11. **Affix line order:** the guide contradicts itself. Its caps table gives "Damage +7%"; section 1 gives "+8% damage". The new affixes follow section 1 (number first). Settle it in v3.
12. **Loot words:** "better loot" is flavour only, so Chancer says *loot quality*. "Quicker" is the speed word, so Glucose says "refills 50% quicker".
13. **Pasts and heads:** classes show as *pasts* and are picked in **Training** (not the Yard). The Bank's head is **the Manager**. Class names are lower-cased in code (barracks.gd L826, L983; sim.gd L8443), against guide section 2, and with "the Recruit" that gives "a recruit".

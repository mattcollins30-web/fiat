# The language redesign (3 Nov, Matt's calls; the rename pass follows)

The inventory behind it: every player-facing name (365), tagged ours / borrowed / plain, and 82 clashes - kept in the
cloud scratchpad as lang_inventory.md; the decisions below are the record.

## The principle (Matt, 2-3 Nov)
- **The world speaks British; the systems speak the genre.** What the world itself would say - places, people, money,
  kit, rooms, factions - is our own word or plain British. What a player reads as a game - stats, ailments, tree
  parts, rarities, skills - keeps the genre's standard ARPG word.
- **The test** for an edge case: a borrowed word stays only if a genre player gets it at once and no in-world word
  does it better; a coined word stays only if it can be learnt where it first shows (its one-line definition there).
- **British, not Welsh**: the flavour voice is dry, understated British. The style guide's "South Wales voice" line
  goes. (Places like Swansea stay as places.)
- One name a thing, one thing a name: the glossary's rule, now with the clash list below closed.

## Matt's calls (3 Nov)
| Was | Now | Notes |
|---|---|---|
| the Pitch / the Yard (home, the rail room, its nine buildings) | **Home** | Rail "Home"; "built at home", "turns up at home"; the deeds are "the deeds to the place". "the Yard" retired. |
| the Pitch tree / "the Yard" key / Pitch points (Training's common tree) | **the shared tree / shared points** | "Reset the shared tree". |
| Guard, pace | **kept** | Each gets its one-line definition where it first shows. |
| joint | **pair** ("paired", "the pair pays") | The genre reads a pair bonus at once. |
| the ring | **the Paragon board** | Diablo's name; paragon itself stays. |
| a gun's edge ("Rifle edge") | **gun bonus** ("Rifle bonus") | |
| past (as class) | **class**, always | |
| salvage (Copper, Safe steel, Army surplus) | **trade goods** | "Scrap" keeps the breaking-down sense. |

## The rest, by the principle (the coordinator's calls; Matt to veto)
Two names for one thing - one kept:
- class (not past) · the medic (not the doctor) · Secondary (not Sidearm) · pack (the slot "Backpack", the stash tab
  "Packs" - not "Bags") · Guns (stash tab, Workshop view, loot rules, County) · frost (the element), chill (its
  ailment only: "What hit you" says frost) · Expeditions (not "Far places") · "Raise the item's level" stays the
  verb, "bump" goes from screen ("Overbump" -> "Over the cap") · Take him on (the head; never "Arm") · loot quality
  (the paragon row "Find" -> "Loot quality") · Loot rules (the Bunkhouse pick "Your own list" -> "Loot rules on
  repeats") · the Map (capital everywhere) · the Radio (never "the wireless"; Training's chip "Radio lines") · Stats
  (the band too, no "The") · Training (the caravan only in flavour) · the Workshop (its intro title too) · Kev's
  story (the Radio view too) · gun part (not attachment; the stash tab "Parts" stays as the short form) · rounds (the
  crate "Ammo tin" -> "Rounds tin") · locked (gates everywhere; "shut" only for rooms at a time of day) · Top up (the
  rig); "Fill up, then go" stays (the pack) · damage over time (the affix "burn, poison and bleed damage" -> "damage
  over time") · Uncommon (never "Magic").

One name doing two jobs - split:
- **crew** = a faction only. The roster of classes -> "your runners"; the events' rival crew -> "a rival gang"
  ("the gang of somebody you robbed").
- **Head** = the site's leader; the site card's toggle "Gang | Head" stays, the foot button is "Take him on".
- **town**: the zone "the Town"; the rebuild view -> "The rebuild"; the whole Map -> "the Map".
- **order**: the Issuer's "the Order" (capital, a proper noun); "Standing orders" stays; the unique "Last Orders"
  stays; the Doorman perk "Last orders" -> "Time, gentlemen".
- **Mint**: the pinnacle "the Mint"; the rebuild place that opens it -> "the Press".
- **Rooms vs home's buildings of the same name** (Clinic, Fence, Radio, Stash, Bench): what home builds for a room
  is that room's upgrades, so one name is right - the card is the room's ("the Clinic", "the Fence"...), headed
  "Upgrades"; the Bench's card becomes "the Workshop". The Generator, the Lookout, the Kennel and the Bunkhouse
  stay as things home builds.
- **The Bench** = the Workshop's craft station only.
- **shelf** = a shop's stock (the Fence, the medic). The Radio's paper list -> "the pile"; the mantelpiece's empty line
  -> "Nothing on the mantelpiece yet".
- **tier**: affix tiers T1-T5 and base tiers T1-T9 stay (genre); a site's Map tier -> off screen (its level shows);
  the code tier I-IV -> "strength"; a hand's tier -> "grade".
- **Clear**: the site's clear stays; the signal grade "Clear" -> the grades Faint / Strong / Full; the Radio craft
  "Clear" -> "Clean up"; the sky stays ("clear skies" only in flavour).
- **Safe**: the odds band stays; the crate "Safe" stays (an object); "Safe steel" -> "Steel"; risk's "safe" -> "low".
- **Long odds**: the odds band stays; the code -> "Outside chance".
- **Hardened**: the code stays; the poison resist filler -> "Seasoned".
- **Broadcast**: the run event stays; the Radio craft -> "Relay".
- **sealed**: a Twisted site stays; the Fence's "sealed lots" -> "closed lots".
- **Stamped**: issued kit stays; the Registrar's skill seal -> "Filed".
- **gamble**: the Fence's gamble stays; Twist's tip "A gamble; seals the site" -> "A risk; seals the site".
- **Burn**: the ailment (fire) stays; fiat out of circulation / the deeds -> "destroy" ("Destroy the deeds", "taken out
  of circulation").
- **Strip**: stays for taking parts off; the affix strip -> "Wipe"; the Scrapper tree "Stripping" -> "Breaking".
- **Kit**: the room and everything worn stay; the loadouts "Kit 1-3" -> "Loadout 1-3" (the genre word, a system).
- **scrap**: the currency and the pack item stay one thing; the loot rule's action "Scrap" -> "Break down"; the top
  bar tip "the Workshop's material" -> "what the Workshop runs on".
- **Guard dog** (the Kennel) -> "Watchdog".
- **Fencing** (a Scrapper tree) -> "Dealing"; **Moving on** (a Drifter tree) stays (the Pitch move is gone).
- **Bailiffs** (a code) -> "Debt collectors"; the Bailiff (a County head) stays.
- **convoy**: Kev's depot convoy and the site card's toggle stay one thing; the signal extra -> "a lorry"; the event
  -> "a passing lorry".

Glossary breaches in current strings - fixed to the glossary: money, faster, fast, attachment, zone, node (the Dial:
"Pick a point above"), camp (the opening: "You keep a place."), farm ("Where to go for it"), bag, rarer, gear outside
the contract kind ("Kit needs level %d"), patrols, the stale Pitch-move lines, the Treasurer always "she", "host" and
"the remix" defined where they show, Lv -> "Level".

Definitions where they first show (the glossary's list, kept words): Guard, pace, pair, keystone, notable, capstone,
reach, paragon, sealed, Twist, the Dial, trade goods - each a one-line tooltip on its first appearance.

## Mixed systems, settled
- The rail: Stats, the Kit, the Map, Training, the Clinic, the Fence, the Workshop, Home, the Radio - "The" on the
  rooms that are places (the Kit, the Map, the Clinic, the Fence, the Workshop, the Radio), none on Stats, Training,
  Home.
- Tree parts: perk, notable, keystone, capstone, bridge, pair, paragon, the Paragon board, shared points - all genre.
- The Radio's ladders: a signal has a level and a grade (Faint / Strong / Full); a code has a strength (I-IV).
- Rarities: Common, Uncommon, Rare, Epic, Legendary, Mythic, Unique, Set, Issued (ours, the one story rarity).
- Item slots stay (Primary, Secondary, Helmet, Armour, Gloves, Rig, Backpack, Charm).
- Map areas: "area" in mechanics, the names otherwise; "zone" off screen.
- Factions: crews have names (the Doormen's crew); a site's men are a gang, named for the site where named.

## The build (the rename pass)
Words only, no numbers: words.gd, data.gd names, UI strings; save keys and code identifiers stay (`yard_*`, `pitch_*`
internal). The smoke's banned-word list gains the retired words (Pitch, Yard, past-as-class, joint, the ring,
salvage, Far places, Sidearm, Magic, wireless, Arm ...), the glossary in the style guide is rewritten from this doc,
and a language review reads the result. Art keys and file names stay.

# Meds by what they treat, magazines, and the Clinic's quality

Agreed with Matt on 28 Oct, mid-playtest: "different meds for different things like bleed/poison etc and then we need
magazines for ammo - carrying 3000 smg rounds in a rig doesn't make much sense for the realistic tone we have. In
addition we need some way of improving what the clinic sells in terms of quality." Parked until after his playtest;
the numbers below are drafts for the balance pass to set. The rig's new look goes on the canvas before it's built.

## Meds: the heals, and a cure an element (Matt's call)

- **The heals stay** as they are: painkillers, bandage, first aid kit, field dressing, trauma kit, surgeon's kit,
  hospital kit (HP over their use time).
- **Five cures**, a pouch each, quick to use. Each stops its element on you and gives a few seconds where it can't land
  again:
  | Cure | Stops | Draft |
  |---|---|---|
  | Tourniquet | bleed | clears bleed; 6 s immune |
  | Burn gel | fire | clears burns; 6 s immune |
  | Activated charcoal | poison | clears poison; 6 s immune |
  | A hot flask | frost | clears the chill; 6 s immune |
  | Smelling salts | shock | clears shock and a stun; 6 s immune |
- **Used by the runner** when its element is heavy on them (its stacks would take a set share of the HP left), as the
  heals are under 40% HP. Click to use, as now.
- **What it touches:** the Paramedic's Tourniquet skill and Clean hands capstone (they become the cures' big
  brothers); the gangs' element mix per zone makes which cures to pack a choice; the Clinic and the Workshop's med
  ladder sell and build them; the mythic Ambulance bag and the Paramedic's bum bag read "a med" as a heal or a cure.

## Magazines: real reloads (Matt's call)

- **A gun fires from its magazine.** Draft sizes: SMG 30, rifle 10, pistol 15, shotgun 8, nail gun 50, belt-fed 100.
  Empty, it **reloads**: a pause in its fire (draft 1.5-3 s by type), shortened by a new reload stat (an affix on guns,
  a few nodes in the trees, the Recruit's drill).
- **The rig carries loaded magazines**, a few to a pouch (draft 3). A grade is a magazine of it (hollow points, match,
  incendiary). Out of magazines, the secondary, then fists, as now.
- **Loose rounds stay at home.** The stash keeps boxes; magazines are filled between runs, free, from what the stash
  holds. Rounds found on a run go in the pack as boxes, to fill magazines at home (or one by hand mid-run, slowly).
- **What it touches:** the rig's layout (a magazine's cell, the rounds left on it), the fight's rate (the reload pause
  in the dps and the odds), the Fence's ammo (sold as boxes), the bot's packing, every gun's balance. The melee and
  free-round guns (the Starting Pistol's rule) are untouched.

## The Clinic's quality: supplies you bring her (Matt's call)

- **Medical supplies** drop from medicine cabinets and the medical sites (the Hospital most), a stack in the pack.
- **Hand them to the medic** and her shelf improves for good, in steps: the tier she stocks first, then the rarity -
  magic and rare meds rolled with med affixes (heals more, works faster, a cure built in, a beat of Guard).
- **A reason to choose crates:** the medicine cabinet left at a site becomes worth going back for (picked over).
- The Yard's Clinic picks (the shelf's size) stay as they are.

## Order, when it's built

1. The cures (the smallest, and the Paramedic wants them). 2. The Clinic's supplies. 3. Magazines (the biggest:
it changes every gun's numbers, so it goes in before the balance pass, not after).

## Built (28 Oct, Matt: "build it all")

- The cures, with frost and shock pools on the runner (there were none: a chill slows your fire, a shock lands more on
  you); Smelling salts clears shock only (no stun on the runner). Auto-used at CURE_AT of the HP left; the Clinic keeps
  two cure slots, the front's elements first; the Workshop's med ladder builds them; the bot packs them.
- Medical supplies: found where the sites lean to meds (the Hospital most) and in medicine cabinets; handed in at the
  Clinic's body panel; CLINIC_STEPS lift her tiers then her rarity, with new med affixes (quicker, Guard, a cure
  built in).
- Magazines: a rig rounds item is a pouch of MAG_POUCH magazines; reloads by type, a reload_pct affix (no tree nodes
  yet); filled free at the gate from the stash; boxes found stay in the pack. Drafts all.
- For the balance pass: a 1 h bot read climbs 2-3x slower, almost all from the pouches (MAG_POUCH 12 restores the
  pace); the Paramedic's Tourniquet skill and Clean hands not yet reworked as the cures' big brothers; magazine
  attachments carry no size or reload yet.

## Magazines as items (30 Oct, Matt, mid-playtest; the playtest paused for it)

Why: "in practice the magazine thing doesnt hold - you need to be able to find magazines and then fill them up out
of boxes - then put them into the rig"; with a 6-pouch rig "its beyond annoying trying to manage mags - the issue is
compounded by different ammo types". Parts against items: "convert them into items instead of parts and then figure
out what we can either replace or add to the magazine part in the workshop". Matt's calls on the four questions:
pause and build now with the playtest's parked fixes, then a fresh save; the sling; the refill on its own; one a pouch,
a drum two.

- **A magazine is an item**, by ammo type (pistol, rifle, shotgun, SMG, nail). Its kinds are the old magazine parts:
  Standard (the type's size), Extended (+50%), Quick (a faster reload), Drum (x2, a slower reload, two pouches), Belt
  box and Hundred-round drum (the belt-fed). Found in crates; the Fence sells the standard ones. Tiered like the parts
  were; numbers drafts for the balance pass.
- **Every gun found comes with a standard magazine for it** - a gun is never dead for want of one. The first gun: the
  gun, its magazine and a box.
- **Rounds live in boxes only** - the stash and the pack. No rounds pouches; the rig holds magazines and meds, a
  magazine a pouch (a drum two).
- **Loading is the game's, not the player's.** At the gate every magazine in the rig is filled from the stash's boxes
  of its type, the best grade first. The top-up packs the primary's magazines, then the secondary's, then meds. The
  Kit reads a gun as "3 mags · 30 rounds".
- **On a run**, the rig's magazines all spent and a box of the type in the pack: the runner refills one, a long reload
  (draft 3x the gun's). This is the playtest's parked item 4 (the hand-load), with no button.
- **The Workshop's magazine mount goes**, replaced by a **sling**: while the primary reloads, the secondary fires (a
  share, drafts by part). The old parts on a gun come off as magazine items.
- **Mockups first** on the canvas: the rig with magazines, a magazine's card, the Kit's gun line, the sling's parts.
  New words through the language pass. The save's shape changes: SAVE_VERSION, a fresh save.
- **Approved (30 Oct, Matt: "All approved")**: the canvas "Fiat – Magazines as items, and the playtest's labels" -
  the size a kind times the gun's own magazine (a base's "mag", else MAG_SIZE), magazines under the stash's Rounds
  tab, slings drafts. Magazine art reuses the parts' and pouches' pictures (art/items/mag_<type>.png,
  extended_magazine, quick_magazine, drum_magazine, belt_box, hundred_round_drum); the four slings get a manifest.

### The language pass (30 Oct: two reviewers, the editor's call)

| What | The word |
|---|---|
| Magazines, by ammo type | Pistol / Rifle / Shotgun / SMG / Nail magazine; Extended <type> magazine; Quick <type> magazine; <Type> drum (not "Drum <type> magazine": the Drum shotgun is a gun). Belt-fed: Belt box, Hundred-round drum (kept). One pattern - no speedloader or shell tube; the card's "Feeds the ..." names the gun |
| The mount, the slings | Sling; Rope sling (T1), Webbing sling (T2), Leather sling (T4), Two-point sling (T6) |
| The Kit's gun line | "3 magazines · 36 rounds" (never "mags": one name a thing; too long, it drops to "36 rounds"); "No rounds needed" |
| A magazine's card | figure "12 of 12 rounds" / "0 of 16 rounds"; chips "The gun's own 8", "×1.5 the gun's 8", "×2 the gun's 8", "Reloads 1 s quicker" / "slower", "2 pouches" (only past 1), "Feeds the pump shotgun" (a base lower case mid-sentence) |
| A sling's card | figure "Secondary fires at 40%"; chip "While the primary reloads" |
| Log lines | "Out of magazines: refilling one from a box in the pack"; "Smaller rig: <what> back in the stash"; "Found: a pump shotgun, a shotgun magazine and a box of shells"; "Filled: 3 magazines from the shells in the stash"; the meds top-up loses "1 meds" (a number takes its plural rightly) |
| The run's Rounds tile | "5 · 1 spare"; "Refilling · 6 s" |
| The Barracks card | "✓ selected" (Matt's word; the card's tags stay lower case) |
| Glossary adds | magazine, pouch, sling, primary, secondary |

### Built (30-31 Oct, 0.10.2)

- As above, with Matt's two calls on the build's questions: **a box in the pack** (the gate packs one box of each
  worn gun's rounds, the grade its magazines hold, for the refills; it comes home, can't be ditched, is lost on a death
  like the pack) and **the sling lifts the secondary's normal share** while the primary reloads (Rope 50%, Webbing 65%,
  Leather 80%, Two-point 100%; through a refill the secondary fires at full).
- Every gun comes with a standard magazine of its type (it rides on the gun until home); spare magazines (empty, out
  of the rig, past the rig's share for a held type or of a type no gun fires) follow the junk, scrap and rarity sells.
- Reloads and refills are paced like the fire, in the fight and the reads.
- Drafts for the balance pass: kinds x1 / x1.5 / quick x1 reload x0.6 / drum x2 reload x1.4 (2 pouches); Belt box
  x2.5, Hundred-round drum a flat 100; REFILL_MULT 2 (3 left the Poacher under a coin flip at the Pleasure Park on the
  Estate's kit); a fifth of part finds are magazines; the Fence shelves 2 standard a held type; RIG_MAG_SHARE 0.5.
- Known: the bot's balance reads now carry real magazines and the gate's box (no bottomless magazines).
- The three-stage review's round (31 Oct, the project manager's calls while Matt slept): "Best grades only" is the
  stash's best grade at the gate or nothing (a magazine keeps the grade it holds); no sling on a secondary (the
  mount's gone from them); the Hundred-round drum fits ordinary SMGs, not the Belt-fed; the first gun found with a
  full rig moves a heal to the pack to make room for its magazine; two guns of one type share one pool (a gun with no
  magazine in it doesn't fire; the primary takes the secondary's last).
- Words the builds added past the table (for the next language pass): "Packed: a box of <grade> for the refills"; "Rig
  off: <what> back in the stash"; "Into the pack: <heal>, to make room for the <gun>'s magazine"; "Always 100 rounds";
  "Holds N"; "Shares the <gun>'s magazines"; "Empty: refilled at the gate" / "Empty: refilled from the box when the
  rest are spent"; "No magazine for it in the rig" / "No magazine"; "Used at once, under fire" (a cure's Kit line);
  "Grenades: N"; the gate box's pick "Packed at the gate for the refills: it comes home" / "Yours: never ditched or put
  down"; the Nail chip on Nails; counted lists ("3 bandages", "2 tubes of burn gel", "a pack of activated charcoal").
- For the balance pass: the reads (sheet dps, estimate, the bot's compares) assume magazines reloaded forever and read
  10-20% high once the rig's magazines run dry (the odds' dry runs fight the real rule); without a sling the secondary
  is at its backing share through reloads (was full): 3-10% off most kits; rounds carried in the rig a third of
  0.10.1's; the old magazine parts' +8-25% damage gone.


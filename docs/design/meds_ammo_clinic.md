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


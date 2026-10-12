# Fiat — the narrative

What the game is about, who tells it, and the voice it's told in. The lines
themselves live in `scripts/sim/words.gd`; this is why they say what they
say. Written 2 Oct 2026 at Matt's call ("start thinking about narrative"),
built the same day.

## The frame: the yard is the player

The runner isn't the character. The yard is: a lock-up on an industrial
estate at the edge of a town, after the money went, with a caravan, a radio
set and a reputation that draws people to it. Runners are the people who
pass through. The game already said this before the words did — a runner
dies and a new one turns up, the stash and the cash and the yard's own tree
survive, the classes are "what the runner was" — so the narrative leans on
it rather than fighting it.

What follows from that:

- **A runner was somebody.** Poacher, Doorman, Paramedic, Scrapper, Drifter
  are five answers to "what did you do before". Each has a line for the past
  (`Words.PASTS[class].was`, said when the class is chosen) and a line for
  how they turn up at the yard (`.arrives`, said when the last one dies).
- **The yard keeps a list.** Every runner who dies goes into `sim.past` —
  class, level, runs, where — and the Caravan reads it back: "Before: a
  poacher, 14 runs, died in the parade; a doorman, 3 runs, died in ransacked
  streets." It's the game's memorial and it costs nothing.
- **Hardcore** is the yard itself going. The line says so.

## The question: what's in the bank

The Town ends at the bank, "held by a crew". In a game called *Fiat — let it
be done* (the words on a note, a king's stamp, a decree) the right answer is
that the crew aren't guarding money. The vault holds **the deeds** — the
paper on every house on the estate, every mortgage, in a fire box. The crew
held the bank because whoever holds that owns the town when things come
back, and they believe things come back. That's their whole character and
it's why they're the last fight.

The ending is the player's one real choice, and it uses verbs the game
already has. The deeds drop once, on the first clear of the bank, whatever
the pack holds (two by two, £5,000 to the fence, the only paper worth
anything). Then:

- **Ditch it** on the run — *burned*: "Burned in the yard. Nobody on the
  estate owes anybody. Let it be done."
- **Sell it** at the fence — *sold*: "Sold on. Someone, somewhere, is owed
  the estate now. Let it be done." The fence: "I'll find a buyer. Someone
  always wants to be owed."
- **Bring it home** — *held*: "The yard holds the paper on every house on
  the estate. Let it be done."

`sim.ending` records which. No win screen; a line in the log, in the voice.
Ditch-commons and sell-commons both step round the deeds, so the ending is
never an accident. The game goes on afterwards — the town's still there —
but the yard has a story.

## Who tells it

Nobody explains the collapse. *The Rover* never does and is stronger for
it. The past is mentioned, never described. Four channels, all cheap:

**The log** is the narrator and already was. It gains: a line the first
time the runner sets off for a site at a depth (`Words.SITES[site].depths`,
one a depth, the last holding for every depth past it) and a line the first
time a site is cleared (`.cleared`); the runner's arrival; the deeds.

**The places.** The same site line sits on the Runs card, under the word,
so the card says what the site *is* at this depth and not only the numbers.
Going deeper into the shopping centre tells you what happened there: "The
jeweller's was done the first night. Nobody wanted the watches." Thirty
lines, six sites by five depths.

**The people.** The fence and the medic have faces now; they get lines
beside them: one on a visit (rotating), one on a buy, a sell, a treatment,
the shelf growing; the medic notices a new runner; the fence has a word
when the town opens. `Words.FENCE`, `Words.MEDIC`; the Fence screen's
`_says()`.

**The things.** Every item has a line (`Words.ITEMS`, one per base,
attachment, med and ammo box — 113 of them), shown under its figures in
every pick panel: what it is and where it came from, in the one voice. The
four uniques are four people who aren't here any more (`Words.UNIQUES`):
Grandad, the Postman, the Doorman, whoever wore the cap. And **papers** —
a new item class, a cell each, pennies at the fence: a council tax
reminder, a P45, a betting slip with four of five in, a pawn ticket for a
wedding ring. Fourteen of them, found among a site's pickings (6%), the
only place the before speaks in its own hand. They use the grid for story,
which is right for a game that lives on the pack.

## The voice

British, flat, dry. The money words everywhere — the title does this and
the game keeps doing it: the fence "pays worth", the bank's "crew", "cash
about", "picked over", "delivery day". Nobody heroic. The worst things said
shortest ("They're not guarding money." "They stayed."). Jokes are allowed
if they're the kind people make at a funeral. No exclamation marks. Second
person for the runner, never a name. Contractions. Full stops, not dashes,
inside a line.

Terms, after the language pass: a group that comes at you is a **gang**
(was "lot"); a hostile is one of them; the search phase is **picking over**
and a find is a **search** (not a "look"); the shop keeps its old name, the
**fence**; the Clinic's person is the **medic**; "word" is intel; "the yard"
is home, "the estate" and "the town" are the two zones.

## The city and the bosses (same day)

Estate, Town, City: the services where the lorries stopped, the hospital that kept going without the
lights, the barracks the army lorry never reached. The gun descriptions had already pointed there. Each
zone has a crew with a head - the carpet man, the manager, the quartermaster - fought once for free at the
zone's last site (that's the campaign) and after that for notes, the old paper money every kill carries,
which the fence won't touch and the crews still take. The bank keeps the deeds; the barracks closes the
lorry's thread. `Words.BOSSES` has their two lines each; the six uniques they drop are theirs
(`Words.UNIQUES`).

## The endgame's people and things (same day)

The fence has contracts now, and a mate who doesn't come in and sends uniques with him for notes
("He still thinks they're money. So do the crews."). Runs have events: a convoy stops, someone's under a
ceiling and says they know a yard, a council-green cabinet the bench's tools open. At full strength the
crews' heads carry one more thing each, and they're charms - the van keys, the manager's own pen, the
quartermaster's ledger - small things kept for luck by people who had none; the convoy's load is notes,
baled, under a tarp, and nobody says what for. Charms are the one cell on the body kept for luck and
their lines are the before in objects: a penny, a saint, a ring someone's still coming back for. The
socketables are a shed's worth of what the world adds that no gun part can. Moving the yard has one line
and keeps the list on the wall.

## Not built, deliberately

A papers collection (keep them all, read them in order) — maybe, if people
keep them. Lines for the gangs — they're words on a site, not characters,
and the Run screen's Them panel is a fight, not a face. A win screen —
the log and the deeds are the ending. Voice for the runner — they don't
talk; the yard does.

## The story underneath (12 Oct)

The notes' thread, the radio's three voices, the opening, the drawer as a book, the gangs' names, the wall's lines
and the traits: docs/design/lore.md.

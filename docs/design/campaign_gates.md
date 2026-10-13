# The campaign's gates, tins, codes and the live radio (13 Oct, Matt)

Design only until built; the order of the build is at the foot. Matt's calls are marked [Matt].

## Tins, not cash [Matt]
A game about a financial collapse where everything costs cash made no sense. What the Fence, the Clinic, the Yard
and the Workshop take is **tins** - tinned food, the thing anyone still values. Notes stay as they are: banknotes,
worthless to everyone but the Radio.
- A label change only: no balance, no numbers. The internal key stays `cash` (saves, the balance tools, the gates).
- Every figure on screen goes through one formatter: "143 tins", "+4 tins a kill", "2.4M tins"; the top bar shows the
  number by a tin glyph (art/ui_new/tins.png, the campaign manifest).
- The words: affix labels ("cash a kill" -> "tins a kill", "cash" find -> "tins"), the tips, Words lines that say cash
  or £, the Manager's Coat's rule ("Cash half again" -> "Tins half again").

## The gates: a boss a zone, an item a room [Matt]
Every room but the Yard's map-side ones is shut at the start: Runs, the Runner, Stats and Training are open.

| Zone | Boss (site) | Drops | Opens |
| --- | --- | --- | --- |
| The Outskirts | **The Gamekeeper** (Top Farm) - new | The vet's bag | the Clinic |
| The Estate | The Carpet Man (the Retail Park) | The Carpet Man's ledger | the Fence |
| The Town | The Manager (the Bank) | The deeds | the Yard |
| The City | The Quartermaster (the Barracks) | A military radio; the armourer's tool roll | the Radio; the Workshop |

- Each item is a once-only quest paper like the deeds are now: in the pack whatever it holds, read on the way home,
  the room opens with it. The deeds drop only when the Manager is down (not on any Bank clear).
- The Workshop stays with the Barracks [Matt]: no crafting in the campaign; the scrap stockpiles for it.
- The Yard's buildings for a shut room (the Bench, the Clinic's, the Fence's, the Radio's) stay hidden until it opens.
- Before the Fence: no selling, buying, gambling or contracts; the stash fills. Before the Clinic: rest or meds.
- The Gamekeeper: the Outskirts were the gentle edge with no crew, so he's soft - a boss the Outskirts' pace allows.
  A gamekeeper on Top Farm's estate who kept the vet's bag for his dogs (the Poacher's old enemy).
- A save from before: a room opens for each boss already beaten; the Outskirts' boss is new, so a save past the
  Outskirts has the Clinic.
- A radio line plays before each unlock event (the boss armed / named) and after (the item home, the room open).
- The bot: no Clinic or Fence until they open; one balance pass after (features first).

## The Clinic's and the Fence's own voices [Matt]
Once the Clinic opens, the medic speaks on the radio line herself now and then; once the Fence opens, the Fence does.
Their lines are their own pools, played in the radio's turn like the others, with no name in front (see below).

## Radio codes, not words [Matt]
The Radio's map juicing keeps its mechanics (a bite, a pay, tiers I-III, per site or across the map from the Relay);
on screen a "word" is a **code**. The papers you find carry the codes: a paper read into the book "carries a code"
where it said "teaches a word", and each paper's flavour says where the code is written on it. Notes still buy the
crafts (notes x depth). The military radio is what opens the Radio.

## The live radio line [Matt]
- A strip of its own under the top bar, above the rail and the room, always shown on every screen.
- One line that scrolls right to left all the time (about 70 px a second), never stopping; lines are not shortened.
  Lines run one after another with a faint dot between. With nothing new, the loop plays.
- No speaker in front ("Kev:" goes): the radio has its own voice. The voices stay as pools behind it.
- Events jump the queue: the gates' before and after, the gangs, the runner's news; the medic's and the Fence's lines.
- Clicking it opens the Radio once the Radio is open.
- The smoke: the strip is exempt from the fit check (it runs past its ends by design); a new check that it stays in
  its band, moves, and that nothing else overlaps it. Mockup on the canvas first (its height, its place by the bar).

## Art (tools/pixellab_campaign_manifest.json)
The tin glyph; the nine rail glyphs again for the rooms as they're named now (art/ui_new/, nothing in art/ui
touched); the Gamekeeper's portrait (art/people_new/); the five unlock items (art/items/, new names).

## Order
1. The pick panel's two fixes (parked, first). 2. Tins. 3. The radio strip: mockup, then build. 4. Codes.
5. The gates, the bosses, the items, the radio lines, the medic's and the Fence's voices. 6. The bot. 7. One balance pass.

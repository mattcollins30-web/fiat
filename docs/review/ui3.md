# Fiat: UI and player experience, the third review (before Matt's playtest, 26 Oct)

Sources: rev2/repo at 05b6589, rev2/since_review2.diff (from d17b479), docs/review/ui.md and ui2.md, the style guide,
CLAUDE.md, and fresh shots from a copy of the working copy (rev2/ui_copy, script tests/ui3_shot.gd; PNGs in
rev2/out/shots/). The cloud copy has none of the County's art (art/fight_county, the County crews, the heads, the
place cards, the issued kit pictures), so RunView's County plates, walls and crews are **code-checked only**, and the
cards and rows show their word fallbacks ("PRI 1901"). That isn't counted. **Code-checked** means confirmed in the
source. Nothing in the repo was edited.

Effort: S = under an hour, M = half a day, L = a day or more. Every UI bug comes with the smoke assertion that would
catch it. Each item needs Matt's go-ahead.

---

## 1. Yesterday's items

### Done and holding (re-checked in the source)
- ui.md 1 (the Fence's rows keep uniques, sets, patterned, ruled and kit pieces), 3 (Reset asks twice), 5 (the top bar
  and "Your fire" shorten), 25 (the Training badge), 26 (Hurt under 90%), 40 ("dmg/s", "Item level" on screen).
- ui2.md 1, 4, 5, 14 (one `Arm` helper for the Fence, Training, the Workshop's break and the Kit's bin and save:
  an 8 s window, a fingerprint of what it acts on, cleared on hide), 2 (the row's count leaves out a class's tab),
  6 (the temper tile says why), 7 (the temper words: "+1 item level", "Item level +3 first"), 9 (rain on a roof).
- ui2.md 3 is mostly done. The smoke presses twice, checks the arm clears on leaving the room and on a changed count,
  and checks a class's tab. The survive check still covers only a unique and a patterned piece: no set, rule-kept or
  kit piece.

### Never done (still open as of 05b6589)
| Item | What's still there | Effort |
|---|---|---|
| ui2 8 | run.gd 402/407/414: "Their fire" `"%.1f/s"`, one form. 440/773: Armour `"%.0f"`. The run-screen "no figure clipped" assertion is still missing. | S |
| ui2 10 | No assertion that the "On you" chips stay clear of the skill buttons. | S |
| ui2 11 | The greed chip has no tooltip. `GREED["chip"]` is dead and still says "finds". | S |
| ui2 12 | Five ask-twice phrasings: "Sell N?", "Again: …", "Press again: …", "… – press again", "press again". The Rules' Delete still acts on one press. | S |
| ui2 15 | workshop.gd 467 `"%d scrap in hand"`, 1054 `"+%d scrap"`. The stale ∞ comment in run.gd 766. | S |
| ui2 16 | data.gd 1502–1503: "each on the last" is unchanged. | S |
| ui.md 2(a,b), 15 | A picked-clean run still idles to the clock. "Gang in" still shows a time past the clock. (c), the timeout's log naming the pack, is done. | S–M |
| ui.md 4, 11, 12, 13, 28, 29, 30, 31, 34, 36 | No "Take all", no rule preview or apply-to-stash, no duplicate-unique exit, two junk systems, no bulk select, three sorts, SOCKET_STACK 10, no wheel paging, a two-line log, bulk sells silent. | as ui.md |
| ui.md 6 | Raw `%d`: stats_room 517/535 "%d runs", the Issue card's "1240 notes" (new, below), workshop 467. | S |
| ui.md 18, 19, 20, 21, 22, 24, 33, 35, 37–39 | Esc still opens the pause menu over overlays, and the rest are as listed. | as ui.md |

### Regressed
- **Fmt.money_k ignores fiat.** fmt.gd 97 returns `"%s tins"` for anything ≥1,000, and so does `money_forms`' middle
  form. After the Issue, every fit fallback that drops to the short form says "4.8k tins" (the run's take strip, the
  temper price). ui.md 5's short forms are now wrong-worded after the Issue. Code-checked.
  **Assertion:** with `Fmt.fiat = true`, `money_k(4800)` begins with "ƒ", and no `money_forms(x)` entry contains "tin".
  Effort S.

---

## 2. The new screens

### A. The money at the Issue: traps and figures that mislead (fix before the playtest)

#### A1. Nothing warns that the Mint's first win converts everything, and the card leaves out what the stash lost. Code-checked + 00, 01
- **Where:** the Mint's order card (Words.PINNACLE_WORDS["mint"]: "Prints the money nobody believes in…"). main.gd
  `show_issue_card`. sim.gd `issue()` (1131).
- **Why:** a 48,213,906-tin pile and 1,240 notes came out at ƒ5,662. Every piece held, worn or stashed, now sells at
  the pile's rate: in the fixture, a worn armour worth 4,545 tins sells for ƒ1. The card shows the tins, the notes, the
  formula and the fiat. It doesn't show the stash and kit (`issue_moment["stash"]` is computed and never shown), and it
  doesn't say that held kit now sells for a fraction. The pile it shows (cash alone) isn't the pile the root was taken
  of, so the sum doesn't check. the_issue.md §9 still lists "what the runner sees of fiat before the Issue" as open.
- **Change:** (a) once the Mint is open, a line on its card: "Beat him and the town goes on his money: what you hold
  now comes out at about ƒX" (a `sim.issue_preview()`). (b) The Issue card: "Your pile: N tins, N notes and your kit's
  worth N" → "What came out: ƒX · your kit now sells at ×0.06 of its old worth". Talk first: whether the warning
  belongs on the card or in the Issuer's voice on the Radio.
- **Effort:** S (card lines), M (preview and words pass)

#### A2. The Issuer sells kit the runner can't wear, with no padlock. Code-checked + 03
- **Where:** issuer_counter.gd 99–106 (`show_item` with no `set_locked`, Buy live). sim.gd `issued_block` (1763) has
  no wear check. `issued_piece` sits at reach + 5.
- **Why:** a level-50 runner sees six "item level 60" rows, all buyable, none wearable (wear = item level past 16).
  The bot was fixed for this on the fifth pass ("140 bought for a level-1 runner"); the player wasn't. At ƒ900–2,600
  apiece against an Issue pile of about ƒ5,600, one wrong buy is a third of the new money, and the County stays shut.
- **Change:** padlock the row's icon (`set_locked(sim.wear_lock(it))`), and make `issued_block` return "Wear at
  level 60" (Buy disabled). Name the wear level in the row: "Issued plate · Armour · wear at 60".
- **Assertion:** a camp at level 50 and reach 55: every counter row with `wear_lock > 0` has Buy disabled and its
  cell's `_lock.visible`.
- **Effort:** S

#### A3. Burn is live when it does nothing, and spends on one press. Code-checked + 03
- **Where:** issuer_counter.gd 107–109 and `_on_burn`. sim.gd `can_burn` (1206).
- **Why:** at ƒ0 in circulation the row reads "Burn ƒ3,030 · prices x1.00 to x1.00" and the button is live. It takes
  more than half of a fresh Issue's ƒ5,662 for nothing visible (only the rate ticks up). It's the only spend over
  ƒ1,000 that doesn't ask twice.
- **Change:** disable it when `circ_mult_after_burn() >= circ_mult() - 0.005`, with the note "Nothing about to burn".
  Put it on the `Arm` helper ("Burn ƒ3,030? – again"). Use "×" in the words (style guide §130).
- **Assertion:** circulation 0 → `_burn.disabled`. One press with circulation > 0 leaves the cash unchanged and the
  arm set.
- **Effort:** S

#### A4. After the Issue, small prices round to ƒ0: ammo is free, and the stash "sells for 0". Code-checked + 02
- **Where:** sim.gd `ammo_price` (3557, `_inf` rounds), `sell_price`. vendor.gd 584 (`Fmt.group`, no ƒ).
- **Why:** inflation after the Issue is the Issue's × 0.0005 × the circulation. An SMG box (value 40 × 1.5) is about
  ƒ0.09 at 30 h, and ƒ0.36 even at the old cap. Every box reads "Buy · 0" and costs nothing. The chip "Your stash
  sells for 0" has lost its ƒ. This is a pricing call as much as a UI one.
- **Change (talk first):** a floor of ƒ1 on every buy price after the Issue (`maxi(1, …)`), or show fiat to one
  decimal under ƒ10. Use `Fmt.money` for the stash chip.
- **Assertion:** after `issue()`, every Fence box's `ammo_price > 0`, and the Fence's visible labels contain no " 0"
  price without ƒ.
- **Effort:** S (once agreed)

### B. Words that contradict the code after the Issue

#### B1. "Tins" and "pays full value" are still on screen after the Issue. Code-checked + 02, 03
- **Where:**
  - vendor.gd 581, the Fence's band: "The Fence · pays full value, charges three times / 5,661 tins in hand". The Issue
    card sends the player straight here.
  - vendor.gd 783: "Pays full value; charges three times".
  - Words FENCE visit line 349: "I pay in tins".
  - clinic_body.gd 172/175: "Treat … · N tins".
  - sim.gd 4582/4647 and Words.PATTERNS/BUILD "short": "Short of tins".
  - main.gd 1398: "Tins lose value…; notes don't".
  - radio.gd 907, Kev: "Bring me notes".
  - missions.gd 497: "Not enough notes".
  - Perk and data words ("+3% tins", "Pay 20 tins", "kills pay … tins").
  - Fmt.money_k (section 1).
- **Why:** after the Issue the Fence buys at the Issuer's rate, and tins and notes don't exist. The design doc's §6
  table says the paragon row reads "+3% fiat".
- **Change:** a `Fmt.unit()` ("tins" / "fiat"), used in every UI string that names the money. A post-Issue pass on the
  Fence's lines ("buys at his rate, ×0.94 today"). A sweep that swaps "tins" for "fiat" in perk and node words shown
  after the Issue (the language pass first: new words).
- **Assertion:** a post-Issue camp: show every room and its tabs, walk `text_nodes()`, and fail on any visible text
  matching `\btins?\b` or `\bnotes\b` (with an allow-list for story lines, e.g. the opening's).
- **Effort:** S–M

#### B2. "His rate" means two things, and neither is explained. Code-checked + 01, 03
- **Where:** Words.ISSUE["rate"] ("His rate: the square root of it, x0.8", the conversion) and the tile "His rate
  moves · The Fence buys at it". Words.ISSUED["rate"] ("HIS RATE TODAY 1.00", the Fence's buy rate).
- **Why:** one name for two numbers on consecutive screens. "1.00" has no unit or meaning. "x0.8" and "x1.00 to x1.00"
  break the style guide's "×". "1240 notes" isn't grouped.
- **Change:** call the conversion "The Issue: 0.8 × the square root of your pile" and keep "his rate" for the Fence's.
  The counter's caption: "THE FENCE PAYS · ×1.00 of face". Use Fmt.group for the notes, and "×" throughout.
- **Assertion:** add `x\d` (an ASCII x before a figure) to the smoke's banned-on-screen list.
- **Effort:** S

#### B3. A County run tells the top bar and the log it's at the host site. Code-checked + 11
- **Where:** main.gd 1133 (`"Out: " + sim.tier(...)["name"]`); sim.gd 7226 (`zone_name(i)` in "Out to …").
- **Why:** the run header says "The Truck Stop" while the top bar says "Out: The Services" and the log "the Truck
  Stop, the City, level 55". The same leak happens on the order's runs and on remixed signals.
- **Change:** both read `signal_place` and the County zone's name when a signal or order is laid on the run.
- **Assertion:** deploy_order("truck_stop"): the top bar's where-label contains "Truck Stop", and the last log line
  doesn't contain "the City".
- **Effort:** S

### C. The County board: what the player isn't told

#### C1. "Wear 2 issued pieces" says it twice and never says where they come from. Code-checked + 05, 07, 09
- **Where:** county.gd 248–269: the `want` line and the `note` both carry `county_block`'s same text.
- **Why:** the first time the board opens, the card's whole answer is "Wear 2 issued pieces (0 worn)", twice, in a
  half-empty card. Nothing points to the Fence's fifth tab, and nothing says the pieces must be wearable (A2).
- **Change:** the note becomes the action: "Issued kit: the Issuer, at the Fence ›" (a button that opens the counter).
  The want line keeps the count. In the card's empty middle, list the pieces worn by slot (✓ Armour · ✓ Helmet ·
  — Primary …).
- **Assertion:** with want unmet, `_card["note"].text != _card["want"].text`.
- **Effort:** S (words), M (the shortcut button and slot row, design canvas)

#### C2. A shut zone is silent, there's no key, and taken places look like untaken ones. Code-checked + 05, 09
- **Where:** county.gd `_map_input` (359: shut zones aren't hit), `select` (368). `_draw_pins` (294–314: tone from
  the odds only). No legend.
- **Why:**
  - Clicking the hatched three-quarters of the map does nothing.
  - `Words.COUNTY["zone_shut"]` ("The Bailiff first") can never be shown, because a shut zone's place can't be picked.
  - At 11 of 12 taken, the map shows the taken places as red or grey dots by their odds, with no mark that they're
    done.
  - Grey means both "reading the odds" and "shut" (the ring is the only difference). Pins differ by colour alone (as
    ui.md 23).
- **Change:**
  - A click on a shut zone shows a small card: the scrambled name, "Shut · take the Truck Stop (the Bailiff) first ·
    then wear 3 issued".
  - A tick on taken pins.
  - The Map's key strip (Safe / Risky / A bad idea / Shut / Taken), bottom right as on the first map.
- **Assertion:** a click on a shut zone's centre makes the zone card visible, with text containing the previous head's
  name. Every taken place's pin draws its tick (expose `pin_state(k)` and check "taken").
- **Effort:** S–M

#### C3. The heads' fights are a surprise, and their chips don't say what they do. Code-checked + 06, 11
- **Where:** county.gd `_show_card` (no line for `mech`). sim.gd `order_chips` 1000–1003, Words.COUNTY chips.
- **Why:**
  - The Truck Stop's card says who's there, but not that he seizes your best piece until he's under half HP.
  - The chip reads "Seized: armour" (the slot, lower-case). It doesn't name the piece or say what it costs: −40% fire
    for a gun, ×1.25 taken for armour.
  - "Owed +15%" doesn't say of what. The Auditor's "Skills taxed ×1.5" is fine.
- **Change:**
  - A line on each head's card, from one Words table: "Seizes your best piece till he's under half", "Taxes your skills
    ×1.5 and stamps one", "His bill grows while he's out; drop a debtor to clear it", "Shields, and prints men".
  - The chips: "Seized: your Heavy armour suit · ×1.25 taken", "Owed: +15% taken".
- **Assertion:** each head's card has a non-empty mech line. The Bailiff's chip contains the seized piece's name.
- **Effort:** S

#### C4. Issued kit counts as a set piece, and the screen never says so. Code-checked
- **Where:** sim.gd `set_count` (4966). armoury.gd 268–274 (the set line). item_head.gd (issued uses the unique's rule
  line only).
- **Why:** a player wearing three Army's pieces and an issued plate sees "The Army's · 4 of 6 worn" with nothing
  explaining the fourth. Picking the issued plate says nothing about sets, about being kept on a death, or about never
  breaking into a pattern. Choosing which slots to give to issued kit (two, then three, four and all six) is the
  County's central decision. It's made blind.
- **Change:**
  - On an issued piece's card, a tag line: "Issued · kept on a death · counts as a piece of the set you wear (The
    Army's here)".
  - On a set piece, "4 of 6 worn (1 issued)".
  - On the counter's rows, a verdict against what's worn in that slot: "↑ upgrade", or "↓ −12% dmg/s · keeps your
    Army's 4".
- **Assertion:** with one Army's piece and an issued piece in an Army's slot, the Kit's set line contains "issued".
- **Effort:** S (lines), M (the counter's verdicts)

#### C5. "What came back" is a dead button on the County board. Code-checked
- **Where:** missions.gd 738 (`… and not county_on`), with the button still live and its style toggling.
- **Why:** a run set off from the board comes home, and the button shows "▴" (open) while the card stays hidden. Kev's
  auto-open is swallowed too.
- **Change:** pressing it on the board turns the board off (back to the map) and opens the card. Or the card drops over
  the County's place card, as it does over the site panel.
- **Assertion:** `county_on` with something come back: `_toggle_came()` leaves either `_came.visible` or
  `not county_on`.
- **Effort:** S

### D. Overflow and layout

#### D1. The Issue card's hint is cut, and its three tiles have empty picture boxes. 01 + code
- **Where:** room_intro.gd 137 (`_hint` 640 px at 22 px). Words.ISSUE["hint"]. `strip_texture` has no STRIPS
  entry for "issue".
- **Why:** "Tins and notes are gone for good · the Issuer sets up besid…" is ellipsised. The tiles reserve their strip
  art's top 80 px, which sits empty. The smoke checks the card's lines and `_check_fit`, never the hint.
- **Change:** shorten to "Tins and notes are gone · the Issuer's at the Fence", or widen the hint to the button's
  edge. Give "issue" strips (the Mint's plate, the Fence, a burn), or collapse the tiles' art band when there's none.
- **Assertion:** for every room, class and Issue card, `text_width(_hint) <= _hint.size.x`.
- **Effort:** S

### E. The remix

#### E1. The Radio names one crew and the fight draws another. Code-checked
- **Where:** radio.gd 513, 938 and 996 ("the %s crew" from `sg.zone`, the crew aimed and paid for). run_view.gd 586
  `county_gang` (the County zone's crew whenever `sg.county` is set).
- **Why:** in the remix a signal can be the Estate's crew laid on the Toll Plaza. The decrypt and the list say "The
  Estate crew", and once Matt's County crews are on disk the fight draws the Motorway's. That contradicts the remix's
  design ("any site's plate with any campaign's gang") and the notes paid to aim it.
- **Change:** `county_gang` reads only County runs (`sg.order` a County key), not remixed signals (`sg.county`).
- **Assertion:** `RV.county_gang({"signal": {"county": "toll_plaza", "zone": 1}}) == ""`.
- **Effort:** S

#### E2. The remix opens with one log line. Code-checked
- **Where:** sim.gd `_county_done` (`Words.COUNTY["remix"]`). There is no card and no Radio mark.
- **Why:** the payoff of the County is a line among two in the log strip. The Radio's list looks the same, apart from
  some new place names.
- **Change:** a card, like the Issue's, once ("The Treasurer's down · the Radio picks up both maps"). A "County" tag on
  remixed signals in the Radio's list.
- **Effort:** S–M

### F. The class cards: fine
- Readable, and they fit at 1080p (10_class_card.png). They come before the room intros, once, and go to Training.
- Polish: the three tiles' kicker is "THE CLASS" three times. The first tile's strip is a crop of the portrait already
  shown at the left. Consider "Search", "Loot", "Guns" as kickers. Effort S.

---

## 3. Can a new player follow the endgame?

The Grid → Archive → Mint path is as before (rebuilds, keys, order cards). Where a player gets lost:

1. **At the Mint (A1):** nothing says the first win ends tins and notes for good. A player who saved for 20 hours
   learns the cost after it's paid.
2. **At the Issue card (A1, B2, D1):** the formula instead of the figure, one "rate" for two things, a cut hint, and no
   mention of the stash's new worth. It does send them to the Fence, which is right.
3. **At the Fence (B1, A4):** the band still says "tins in hand · pays full value", the ammo costs 0, and the stash
   "sells for 0". The money seems broken rather than changed.
4. **At the Issuer's counter (A2, A3, C4):** the most likely first buys are kit they can't wear, or a burn that does
   nothing. Nothing says which slots to give up.
5. **Finding the County:** a "The County" button appears in the Map's row. No card, log line or badge says it exists.
   `Words.COUNTY["sub"]` ("Past the City… Each zone wants issued kit worn") is written and never shown. Use it on a
   one-time card when the button first appears, and add the County to the Map's rail badge.
6. **On the board (C1–C3):** the want is clear, but not where to get it. Shut zones are silent, the heads' fights are
   unannounced, and taken places look untaken.
7. **The remix (E1, E2):** one log line, then signals with new names and mismatched crews.

The thread breaks hardest at steps 1, 3 and 4: the money. Fixing A1–A4 and B1 makes the Issue read as intended (hard,
but understood). C1, C2 and the step-5 card make the County findable and fair.

---

## Suggested order
1. Before the playtest (all S): A2, A3, B1 (the Fence band, Fmt.money_k, the Clinic, "Short of tins"), C1 (words), C5,
   D1, E1, B3, and A1(b) (the Issue card's lines). A4 once the floor is agreed.
2. Next: A1(a) (the Mint's warning), C2, C3, C4 lines, the County's first-time card (section 3, step 5), E2.
3. Yesterday's open S items as they come: ui2 8, 10, 11, 12, 15, 16, and ui.md 2(a,b).

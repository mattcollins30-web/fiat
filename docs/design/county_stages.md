# The County's stages - the spec (6 Nov 2026, Claude's draft; the open calls at the end)

The campaign's treatment (docs/design/stages.md, as built) on the County's twelve places. First figures, from the code
at 0.14.0 plus today's art (file:line refers to that tree). Matt's play sets the numbers, not a pass (CLAUDE.md, 2 Nov).

## Why (Matt, 6 Nov)

- "We also need the same treatments for the county - stages, art, gear spread, full size map, UI changes from campaign
  if not already done so." He is painting the County himself, 688 x 384, as the Map.

## 1. Today

**The places** (data.gd:4034-4050) are fought as the order's: a signal on the host site (`order_sig`,
sim.gd:8059-8063) at `depth_for_level` (8671-8672), so on the endgame curve (`depth_figures`, `on_sig`, 7246-7262): a man
3,200 HP and 3.6 fire (data.gd:1988), x1.16 a level to 35 and x1.12 past (data.gd:2009), his HP bent by the host's
shape, his fire not, the gangs its `pool` (data.gd:1939-1979). XP a kill 30 x 1.02 a level (sim.gd:7253). A place's
level is set, **plus a level every win** (`county_level`, sim.gd:8280-8283).

| Place (line) | Zone | Host | Level | Gangs | HP a man | Fire a man | Whole HP | Whole fire | x HP | x fire |
|---|---|---|---|---|---|---|---|---|---|---|
| The Toll Plaza (4035) | the Motorway | the Services | 40 | 12 | 267,392 | 301 | 3,208,700 | 3,610 | - | - |
| The Distribution Centre (4036) | | the Retail Park | 42 | 12 | 335,416 | 377 | 4,024,993 | 4,528 | 1.25 | 1.25 |
| The Truck Stop (4037) | | the Services | 45 | 12 | 471,235 | 530 | 5,654,825 | 6,362 | 1.40 | 1.40 |
| The Container Port (4039) | the Docks | the Barracks | 50 | 8 | 1,245,717 | 934 | 9,965,734 | 7,474 | 1.76 | 1.17 |
| The Ferry Terminal (4040) | | the Pleasure Park | 52 | 10 | 1,041,751 | 1,172 | 10,417,514 | 11,720 | 1.05 | 1.57 |
| The Customs Shed (4041) | | the Shopping Centre | 55 | 11 | 1,609,944 | 1,647 | 17,709,387 | 18,112 | 1.70 | 1.55 |
| The Golf Club (4043) | the Big Houses | Top Farm | 60 | 12 | 2,063,470 | 2,902 | 24,761,645 | 34,821 | 1.40 | 1.92 |
| The Gated Close (4044) | | Ransacked Streets | 62 | 14 | 2,264,865 | 3,640 | 31,708,112 | 50,959 | 1.28 | 1.46 |
| The Manor (4045) | | the Hospital | 65 | 10 | 5,454,810 | 5,114 | 54,548,100 | 51,139 | 1.72 | 1.00 |
| The Counting House (4047) | the Treasury | the Bank | 70 | 7 | 11,215,445 | 9,012 | 78,508,118 | 63,087 | 1.44 | 1.23 |
| The Bullion Vault (4048) | | the Bank | 72 | 7 | 14,068,655 | 11,305 | 98,480,583 | 79,136 | 1.25 | 1.25 |
| The Treasury (4049) | | the Bank | 75 | 7 | 19,765,447 | 15,883 | 138,358,129 | 111,181 | 1.40 | 1.40 |

The steps run x1.05-1.76 in HP and x1.00-1.92 in fire. The zone gaps (45 to 50 ...) are five levels, x1.76 on the
curve, then bent by the next host: the Docks' first fire step x1.17, the Big Houses' x1.92.

**Opening.** A zone opens on the Issue and the last zone's head down (`county_zone_open`, sim.gd:8243-8246); a place on
the one before it (`county_open`, 8250-8256); every run wants the zone's issued kit worn, 2 / 3 / 4 / 6 (data.gd:4019;
`county_block`, sim.gd:8264-8277). No level gate.

**The heads** (COUNTY_ZONES, data.gd:4027-4032) sit on their zones' last places. A run there is the place's whole gang,
then him at his multipliers on its man: 14 / 16 / 18 / 18 HP, 3.0 / 3.5 / 3.5 / 2.5 fire (`order_head`, `boss_form`:
sim.gd:8067-8075, 7107-7110). Each has his own fight (data.gd:4053-4059). His fall: a web reward the first time and
issued kit at max(level, reach) + 7 (sim.gd:8300-8324). The place's first win opens the next zone (8327-8344). The
Treasurer down opens the remix (8595-8635). Today: the Bailiff 6,597,296 HP / 1,590 fire after 12 men, the Auditor
25,759,108 / 5,763 after 11, the Collector 98,186,579 / 17,899 after 10, the Treasurer 355,778,046 / 39,707 after 7.

**Loot.** Every County find is T9-weighted: T9 from level 24 (data.gd:4167; sim.gd:7175-7186), `loot_cap` 9
(7205-7206), the pick T9 50%, T8 30%, T1-T7 20% (items.gd:118-145). No themes (`c55_theme`, sim.gd:21276-21281).

**The reach.** County levels are set, not the reach's (the seventh pass, 26 Oct), and a County run never moves it
(sim.gd:8183). The signals and the County meet only in the remix.

**The card** is the board's own (county.gd:161-211, 316-372: picture, head, the issued want and six slot chips, the
Issuer and Bench links, Go). The order's three moved onto the site card in BUILD49 (site_card.gd:847-890); the 0.12.2
playtest's item 23 named the County's too (docs/status.md:366-371). Never done.

**The art on disk.** A plate and wall a place (art/fight_county/, 744 x 320 and 744 x 256; run_view.gd:41-42, 840-842);
the zones' gangs (art/fight/gang_the_<zone>_{a,b}_{stand,fire,down}.png; run_view.gd:653-658, 846-848); the heads'
figures (art/fight/head_the_<head>_{stand,fire,down}.png) and portraits (art/people/the_<head>.png). **No dens**:
art/fight_boss/ has the campaign's four and the order's three.

**The map.** art/map/county.png, 512 x 424 drawn x4 (county.gd:25-26, 41-42, 232-233); its pins, zones and names are
constants (51-65). It shares the Map's pan and the card's put-away (county.gd:101, 603-643). **Not shared**: the places
from a data file (map_view.gd:956-1050), the F3/F5 tool (map_placement.gd; `can_place` is the Map's only,
map_view.gd:1086-1089), the pins' "· 2/3" / "· New" (map_view.gd:360-393).

Missing from the tree: docs/design/county_map_brief.md (county.gd:2 cites it), and any 6 Nov entry in this copy's
docs/status.md (its newest is 5 Nov, 0.13.3).

## 2. The stages

- **A stage is 1/3, 2/3 or 3/3 on a County place.** The 1/3 at 40 + 3 a place (40, 43 ... 73), each stage 2 levels
  up (COUNTY_STAGE_LEVELS 2); the Treasury's 2/3 is 75, today's Treasury. The level is the finds' item level and the
  card's figure; the fight's figures come from the row (§3), not the curve.
- **What a stage changes.** HP and fire a man x1.22 (DEPTH_HOSTILE, data.gd:3734). Pay, drops and quality as a signal
  of the stage's level, as today: x1.04 XP, +6 drop points, +20% quality a stage. The gangs stay the place's. Its own
  backdrop (§5), finds (§4) and foot line (a line a stage in Words.COUNTY_WORDS; the language pass).
- **What opens.** Each stage needs the one before and the zone's issued want. **2/3 opens the next place**; on a zone's
  last place **2/3 opens the head's own fight**, and his fall the next zone. No level gate (a stage's gate formula tops
  out at 49 past 50): the issued want stays the County's gate.
- **3/3 is for the grind**: it gates nothing and sits a level and x1.10 HP over the next 1/3. The "+1 level a win" goes
  (open call 2).
- **"Run it ×N"** shut till a stage is cleared; **Kev's wagers** on a stage's first clear and a head's fight (FIX55's
  rules, sim.gd:10517-10519, 21305).
- **The heads**: gated on his place's 2/3, at its level; half its gangs (rounded down) at the 2/3's man, then him on the
  1/3's man (the campaign as built); his den from the first man (§5); free, as County runs are (sim.gd:8147).

**How the code extends.** `a55_done` is keyed by a site index loaded through `int(k)` (sim.gd:21188-21196), so the
County gets its own state beside it:

- **Data** (data.gd:4034-4050): each row gains `gangs`, `man_hp`, `man_dps` (its 1/3 as fought); `level` is the 1/3's;
  a head's `hp` / `dps` stay his multipliers. New: COUNTY_STAGE_LEVELS 2, COUNTY_THEMES (§4).
- **State** (beside sim.gd:20929): `cs_done` (place key -> 0-3), `cs_pick`, `cs_new`, `county_heads` (zone -> falls),
  saved in `a55_save` as `"county"` with string keys, loaded with defaults. `order_beaten[k]` stays the wins count. The
  head's falls move from `order_beaten[the last place]` to `county_heads[z]`, which `county_zone_open` and
  `county_done` read (sim.gd:8243-8246, 8286-8287); `county_head_key` stays for the remix.
- **API**: `county_stage_level/_open/_block(k, s)` ("After 1/3", "After the Toll Plaza 2/3", "After the Bailiff", the
  want), `county_stage_pick(k)`, `set_county_pick(k, s)`, and `county_head_fight_open/_block/_preview/_odds(z)`,
  `start_county_head(z)` (mirrors of sim.gd:21090-21262). `order_sig(k)` carries `stage` (and `chead`), its depth from
  the stage's level.
- **The fight**: a County branch in `depth_figures` (sim.gd:7215): HP and fire the row's man x 1.22^(stage - 1), the
  pool its `gangs` (halved on `chead`), tier 9; pay, drops, quality as today. `effective` (7369-7377) forms him only on
  `chead`, on the 1/3's man.
- **The clear**: `_county_done` (sim.gd:8327) moves `cs_done`, says "taken" at a place's first 2/3, marks the next
  place New (the next zone's first on a head's fall); `_county_down` (8300) only on `chead`.

## 3. The numbers re-cut

The campaign's three rules. **(a)** The ends hold: the Toll Plaza 1/3 is today's (3,208,700 / 3,610), the Treasury 3/3
today's Treasury (138,358,129 / 111,181). **(b)** A stage is x1.22. **(c)** A place's 1/3 to the next is a fixed R =
(138,358,129 / 3,208,700 / 1.22^2)^(1/11) = **1.358** in HP, (111,181 / 3,610 / 1.22^2)^(1/11) = **1.317** in fire. So
1/3, 2/3, next 1/3 steps x1.22, then **x1.113** (HP) / **x1.080** (fire). **The zone gaps are that same step**: a
zone's door is its head and its issued want, not a jump in numbers.

**Gangs** one count a zone (open call 4): 12, 11, 10, 9. A man then never steps more than x1.24 (a zone gap: x1.113 x
12/11 to 10/9). HP a man = whole HP / gangs. XP a clear = 1.3 x gangs x XP a kill at the level. "(top)": the 3/3's
quarter at T9 alone (§4).

| Place | Stage | Level | Gangs | HP a man | Fire a man | Whole HP | Whole fire | Tier | XP a clear |
|---|---|---|---|---|---|---|---|---|---|
| The Toll Plaza | 1/3 | 40 | 12 | 267,392 | 301 | 3,208,700 | 3,610 | 9 | 865 |
| | 2/3 | 42 | 12 | 326,218 | 367 | 3,914,614 | 4,404 | 9 | 900 |
| | 3/3 | 44 | 12 | 397,986 | 448 | 4,775,829 | 5,373 | 9 (top) | 936 |
| The Distribution Centre | 1/3 | 43 | 12 | 363,122 | 396 | 4,357,468 | 4,755 | 9 | 918 |
| | 2/3 | 45 | 12 | 443,009 | 483 | 5,316,111 | 5,801 | 9 | 955 |
| | 3/3 | 47 | 12 | 540,471 | 590 | 6,485,655 | 7,077 | 9 (top) | 993 |
| The Truck Stop | 1/3 | 46 | 12 | 493,126 | 522 | 5,917,514 | 6,262 | 9 | 974 |
| | 2/3 | 48 | 12 | 601,614 | 637 | 7,219,367 | 7,640 | 9 | 1,013 |
| | 3/3 | 50 | 12 | 733,969 | 777 | 8,807,628 | 9,321 | 9 (top) | 1,054 |
| The Container Port | 1/3 | 49 | 11 | 730,553 | 750 | 8,036,082 | 8,248 | 9 | 947 |
| | 2/3 | 51 | 11 | 891,275 | 915 | 9,804,020 | 10,063 | 9 | 986 |
| | 3/3 | 53 | 11 | 1,087,355 | 1,116 | 11,960,904 | 12,277 | 9 (top) | 1,025 |
| The Ferry Terminal | 1/3 | 52 | 11 | 992,103 | 988 | 10,913,133 | 10,864 | 9 | 1,005 |
| | 2/3 | 54 | 11 | 1,210,366 | 1,205 | 13,314,022 | 13,254 | 9 | 1,046 |
| | 3/3 | 56 | 11 | 1,476,646 | 1,470 | 16,243,107 | 16,170 | 9 (top) | 1,088 |
| The Customs Shed | 1/3 | 55 | 11 | 1,347,292 | 1,301 | 14,820,216 | 14,309 | 9 | 1,067 |
| | 2/3 | 57 | 11 | 1,643,697 | 1,587 | 18,080,663 | 17,457 | 9 | 1,110 |
| | 3/3 | 59 | 11 | 2,005,310 | 1,936 | 22,058,409 | 21,297 | 9 (top) | 1,155 |
| The Golf Club | 1/3 | 58 | 10 | 2,012,610 | 1,885 | 20,126,099 | 18,846 | 9 | 1,029 |
| | 2/3 | 60 | 10 | 2,455,384 | 2,299 | 24,553,841 | 22,992 | 9 | 1,071 |
| | 3/3 | 62 | 10 | 2,995,569 | 2,805 | 29,955,686 | 28,050 | 9 (top) | 1,114 |
| The Gated Close | 1/3 | 61 | 10 | 2,733,158 | 2,482 | 27,331,577 | 24,822 | 9 | 1,092 |
| | 2/3 | 63 | 10 | 3,334,452 | 3,028 | 33,344,524 | 30,283 | 9 | 1,136 |
| | 3/3 | 65 | 10 | 4,068,032 | 3,695 | 40,680,319 | 36,945 | 9 (top) | 1,182 |
| The Manor | 1/3 | 64 | 10 | 3,711,674 | 3,269 | 37,116,736 | 32,693 | 9 | 1,159 |
| | 2/3 | 66 | 10 | 4,528,242 | 3,989 | 45,282,417 | 39,886 | 9 | 1,206 |
| | 3/3 | 68 | 10 | 5,524,455 | 4,866 | 55,244,549 | 48,660 | 9 (top) | 1,255 |
| The Counting House | 1/3 | 67 | 9 | 5,600,571 | 4,784 | 50,405,143 | 43,060 | 9 | 1,107 |
| | 2/3 | 69 | 9 | 6,832,697 | 5,837 | 61,494,275 | 52,533 | 9 | 1,152 |
| | 3/3 | 71 | 9 | 8,335,891 | 7,121 | 75,023,015 | 64,090 | 9 (top) | 1,198 |
| The Bullion Vault | 1/3 | 70 | 9 | 7,605,669 | 6,302 | 68,451,022 | 56,714 | 9 | 1,175 |
| | 2/3 | 72 | 9 | 9,278,916 | 7,688 | 83,510,247 | 69,191 | 9 | 1,222 |
| | 3/3 | 74 | 9 | 11,320,278 | 9,379 | 101,882,501 | 84,414 | 9 (top) | 1,272 |
| The Treasury | 1/3 | 73 | 9 | 10,328,625 | 8,300 | 92,957,625 | 74,698 | 9 | 1,247 |
| | 2/3 | 75 | 9 | 12,600,922 | 10,126 | 113,408,302 | 91,132 | 9 | 1,297 |
| | 3/3 | 77 | 9 | 15,373,125 | 12,353 | 138,358,129 | 111,181 | 9 (top) | 1,349 |

For example, the Customs Shed's 1/3 is 3,208,700 x 1.358^5 = 14,820,216 (a man 1,347,292), x1.113 over the Ferry
Terminal's 2/3; today it's x1.70. Against today's curve at the same level the rows run 0.72-1.05 in HP and 0.52-1.24 in
fire; the softest is the Big Houses' fire, today's steepest step.

**The heads** (him on the 1/3's man, his gang on the 2/3's):

| Head | Gate | Level | His gang | Him (HP / fire) | Today (HP / fire, after the whole place) |
|---|---|---|---|---|---|
| The Bailiff | The Truck Stop 2/3 | 48 | 6 x 601,614 HP, 637 | 6,903,766 / 1,566 | 6,597,296 / 1,590, after 12 |
| The Auditor | The Customs Shed 2/3 | 57 | 5 x 1,643,697, 1,587 | 21,556,677 / 4,553 | 25,759,108 / 5,763, after 11 |
| The Collector | The Manor 2/3 | 66 | 5 x 4,528,242, 3,989 | 66,810,124 / 11,443 | 98,186,579 / 17,899, after 10 |
| The Treasurer | The Treasury 2/3 | 75 | 4 x 12,600,922, 10,126 | 185,915,250 / 20,750 | 355,778,046 / 39,707, after 7 |

The Bailiff is as today; each later head is lighter (the Treasurer's whole fight 236M HP against 494M; Matt made her
"the County's one wall" on 27 Oct). Mechanics, issued drop and first-fall reward unchanged.

**The length.** The cheapest way through is 24 stages and 4 heads, 28 runs, against 12 today (open call 5). Act two's
County levels (act_two.md §6: "40-45, 50-55, 60-65, 70-75") become 40-50, 49-59, 58-68, 67-77; the heads 48, 57, 66, 75.

## 4. Themed finds

**The rule** is the campaign's (stages.md §5): 60% of a stage's plain gear finds from the place's list (THEME_SHARE,
data.gd:4349), the head's fight on his place's list. COUNTY_THEMES is keyed by place key (SITE_THEMES by a TIERS name,
data.gd:4351); `c55_theme` reads it on a County stage.

**The spread** is in the lists, since everything is T9: the Motorway's lean T7-T8, the Treasury's nearly all T9. A
slot with no T9 on its list hands T9's share to its T8 (items.gd:128-145); the item level (5% a level, items.gd:582)
does most of the climbing. The issued kit's six bases stay off (data.gd:4002-4015).

**At 3/3**, a tier up can't pass T9 (`loot_cap`): instead a quarter of its plain finds roll from the list's T9 alone,
STAGE_TIER_UP as a "top tier" pick (`c55_tier_up`, sim.gd:21284; open call 3).

| Place | On its list now (tier) | Gaps: new bases (slot, tier) |
|---|---|---|
| The Toll Plaza | Demolition bar 7, Breaching shotgun 7, Rescue axe 8, Service rifle 8; Close quarters pistol 7; High-cut helmet 7, Search-team helmet 8; Turnout coat 7; Firefighter's gloves 7; Hostage-rescue rig 8; Assault pack 7; Glass insulator 7 | Highways coat (Armour 8), Cat's eye (Charm 8) |
| The Distribution Centre | Chain-driven repeater 7, Workshop gauss 8, Bench-made autocannon 8, The engineer's piece 9; Arctic helmet 7 (the cold store); Military plate carrier 7; Abseiling gloves 8; Clamshell pack 7, Mountain-troop bergen 8; Glass insulator 7 | Loading hook (Secondary 8), Picker's harness (Rig 8) |
| The Truck Stop | Breaching shotgun 7, Entry shotgun 8, Door ram 9, Siege shotgun 9; Cavalry revolver 7, Overcoat machine pistol 8; Search-team helmet 8; Plainclothes vest 7; Close-combat gloves 7; Breacher's rig 8; Long-range bergen 7; Gold cigarette case 8 | Enforcement vest (Armour 9), Seized keys (Charm 9) |
| The Container Port | Big-game rifle 7, Heavy-barrel rifle 8, Bench-made autocannon 8; Arctic helmet 7 (the reefers); Military plate carrier 7; Abseiling gloves 8, Flight-deck gloves 8; Shield-team rig 8; Long-range bergen 7; Glass insulator 7 | Lashing bar (Primary 9), Port hard hat (Helmet 8) |
| The Ferry Terminal | Marine shotgun 7, Dragon's-breath gun 8; Consular PDW 7; Arctic helmet 7; Chainmail shark suit 9; Flight-deck gloves 8; Hostage-rescue rig 8; Alpine pack 8, Freefall pack 9; Diamond tiepin 7 | Crew lifejacket (Rig 8), Duty-free bag (Backpack 8) |
| The Customs Shed | Briefcase SMG 7, Security service SMG 7, Spiral-mag SMG 8; Legation machine pistol 7, Overcoat machine pistol 8; CBRN helmet 8; Plainclothes vest 7, Tailored body armour 8, CBRN suit 8; Strongroom bag 8; Diamond tiepin 7, Uncut diamond 9 | Examiner's gloves (Gloves 9), Seizure bag (Backpack 9) |
| The Golf Club | Big-game rifle 7, Heavy-barrel rifle 8; Ambassador's revolver 8; Ghillie hood 7; Tailored body armour 8; Dress uniform gloves 9; Royal escort rig 9; Alpine pack 8; Signet ring 7, Diamond tiepin 7, Gold cigarette case 8 | Sidelock shotgun (Primary 9), Shooting jacket (Armour 8), Cartridge bag (Backpack 8) |
| The Gated Close | Close protection SMG 8, Special forces SMG 9; Bodyguard's pistol 8, Embassy PDW 8, Protection squad PDW 9; Search-team helmet 8, Surveillance helmet 9; Tailored body armour 8, State protection vest 9; Counter-sniper gloves 8; Counter-terror rig 7, Shield-team rig 8; Assault pack 7; Signet ring 7 | Gate fob (Charm 8) |
| The Manor | Big-game rifle 7, Felling axe 7, Civic mace 8, Court sword 9, Castle guard rifle 9; Cavalry revolver 7, Field marshal's revolver 9; Ghillie hood 7; Dress uniform gloves 9; Royal escort rig 9; Wax-sealed bag 9; Regimental medal 8, Sword knot 8, Apothecary's vial 9 | Deerstalker (Helmet 8), Estate tweeds (Armour 9) |
| The Counting House | Briefcase SMG 7, Ministerial SMG 9; Legation machine pistol 7, Overcoat machine pistol 8; Plainclothes vest 7, Tailored body armour 8; Counter-terror rig 7; Strongroom bag 8; Diamond tiepin 7, Gold cigarette case 8 | Cashier's visor (Helmet 8), Sleeve guards (Gloves 8) |
| The Bullion Vault | Entry shotgun 8, Combat shotgun 9, Siege shotgun 9, Special forces SMG 9; Protection squad PDW 9; Special forces helmet 8, Full EOD helmet 9; Special forces plates 8, Full EOD suit 9; EOD gauntlets 9, Special forces gloves 9; Shield-team rig 8; Ingot sack 7, Strongroom bag 8, Wax-sealed bag 9; Uncut diamond 9 | Vault guard's carbine (Primary 9), Small ingot (Charm 9) |
| The Treasury | Prototype rifle 9, Castle guard rifle 9, Ministerial SMG 9; Protection squad PDW 9, Crown PDW 9, Field marshal's revolver 9; Surveillance helmet 9; State protection vest 9; Dress uniform gloves 9; Royal escort rig 9; Wax-sealed bag 9; Uncut diamond 9, Apothecary's vial 9 | Treasury guard's helmet (Helmet 9), Despatch box (Backpack 9) |

The bases are from data.gd (Primary 311-551, Secondary 552-669, Helmet 670-709, Armour 710-759, Gloves 760-793, Rig
794-833, Backpack 834-875, Charm 876-914). **24 new bases**: 4 guns (Loading hook, Lashing bar, Sidelock shotgun,
Vault guard's carbine), 5 helmets, 4 armour, 2 gloves, 2 rigs, 4 packs, 3 charms; stats by role against their tier's
neighbours; borrowed pictures through ART_AS (data.gd:2136) till the art; the language pass first. Names checked
against data.gd and words.gd ("Toll token" became "Cat's eye": too near "Arcade token").

## 5. The art

Test art first (CLAUDE.md): each stage on its place's pair, each head on his place's plate, till Matt has read the slice;
then the manifests by art.flag, linted (docs/art/pixellab_lessons.md).

**The keys.** art/fight_county/<place>_2_plate.png / _3_plate.png on the place's wall, as BUILD57's: RunView's scene
key reads a County stage (run_view.gd:840-842, 596-602) and `stage_base` learns the County's slugs (606-616). A den is
art/fight_boss/the_<head>_{plate,cover}.png, from the first man (`head_den`, 628-636, taught `chead`).

**Today's lesson (6 Nov):** a stage plate styled on its own place's plate comes back a near-copy. Each takes **another
place of the same zone** as its style image, and says in words what must differ.

| Place (style image) | 2/3 | 3/3 |
|---|---|---|
| The Toll Plaza (the_distribution_centre) | Behind the booths: the cash office, blank tills and an open safe, a window onto the canopy. Indoors, no canopy view | Past the barriers on the open carriageway: abandoned cars, a jack-knifed tanker in plain paint, the gantry's panels blank |
| The Distribution Centre (the_truck_stop) | The loading yard in rain: trailers backed onto bays, a shunter cab, pallets under sheeting. Outdoors, no racking | The mezzanine pick floor: conveyors, roll cages, plain unprinted totes, strip lights. Up high, not the floor racking |
| The Truck Stop (the_toll_plaza) | The lorry park at night: cabs with their curtains drawn, a fuel island, puddles under floodlights. Outdoors, no cafe | The drivers' showers and the Bailiff's lock-up: a tiled corridor, a caged room of boxes and keys on hooks |
| The Container Port (the_ferry_terminal) | The quay under the crane: a ship's plain hull towering, lashing bars and a bin of twist-locks. The water's edge, not the stacks | The reefer row at night: refrigerated containers on power posts, their plain panels lit |
| The Ferry Terminal (the_customs_shed) | The car deck inside the ferry: lanes of abandoned cars and a coach, chains and chocks, the bow door half down | The upper lounge: bolted seats, a ship's shop counter with blank shelves and a blank fascia, salt-streaked windows on a grey sea |
| The Customs Shed (the_container_port) | The seized goods cage: caged bays of crates, rolled carpets, plain unlabelled bottles | The long office: filing cabinets, a counting table of blank ledgers, a window onto the shed |
| The Golf Club (the_gated_close) | The clubhouse bar: panelling, honours boards painted blank with no names, brass taps, plain bottles | The far fairway and the greenkeeper's sheds: a mower, a pond, a lookout built of scaffold |
| The Gated Close (the_manor) | Inside one house: an open kitchen with an island, glass doors onto the garden, sofas barricading them | The gatehouse: a guards' cabin of dark blank screens, the barrier arm down, a kennel |
| The Manor (the_golf_club) | The stable yard: cobbles, a clock tower with a plain face and no numbers, horseboxes | The library: tall shelves of books with blank spines, a ladder, a desk heaped with papers, every page blank |
| The Counting House (the_bullion_vault) | The basement note store: cages of bundled plain grey-green notes, a sorting machine, no faces or numbers | The managers' gallery: glass offices looking down on the long room. From above, not along it |
| The Bullion Vault (the_treasury) | The loading bay: plain armoured vans backed in, a weighbridge, a steel shutter half up | The deepest vault: safe-deposit doors floor to ceiling, plain with no numbers, one wall blown open |
| The Treasury (the_counting_house) | The print room: presses, sheets of plain grey-green notes drying on racks | The steps and the square: columns, a barricade of plain armoured vans, a flag with no device |

Every plate: the County kit's first-person crouching view and its three-figure layout, filling the canvas to all four
edges, no figures, every board, panel, screen and label blank (the lettering lessons: no "sign", no shop by name, plain
clocks, notes and labels).

**The dens** (plate and wall each; style image the zone's first place):

| Head | Plate | Wall |
|---|---|---|
| The Bailiff | The Truck Stop's back office as his: keys on hooks by the hundred, wheel clamps, boxed seized goods | A row of steel lockers, doors dented |
| The Auditor | A glass-walled audit room: stacks of blank ledgers, a long table, a plain wall chart | A row of grey filing cabinets, drawers out |
| The Collector | The Manor's study: a fire lit, a safe open, a desk of blank ledgers | A heavy desk tipped on its side |
| The Treasurer | The chamber under the dome: her desk on a dais, plain printing plates | A grey marble balustrade |

**Costs** (pixellab_lessons.md's table): 24 plates at 744 x 320, $0.15 each, $3.60. 4 dens, plate and wall, $1.20. 24
item icons at their footprint x 64 px (under 65k px), $0.08 each, $1.92. 4 hands at 280 x 210 (Loading hook, Lashing
bar, Sidelock shotgun, Vault guard's carbine; the reroll template, no style image, big_revolver.png the reference),
$0.32. **$7.04, about $9 with rerolls.** 56 jobs is about 1-1.5 h at `--parallel 3`. The map is Matt's own painting, no
cost.

## 6. The UI

Mockups on the canvas at 1920 x 1080, rendered and fit-checked, Matt's word before the build (CLAUDE.md).

- **The County's card is the site card** (closing the 0.12.2 playtest's item 23). county.gd's card (161-211, 316-372)
  goes; the board hosts `show_order` (site_card.gd:859-890) with the picker (225-240, 465-523): "1/3 · 2/3 · 3/3" and
  the picked stage's level, "Head" on a zone's last place, shut "After 2/3". The issued want, its six chips and the two
  links go in the card's "what it takes" block. The card's own checks run over a County place.
- **The pins**: "Toll Plaza · 2/3", the done colour at 3/3, "· New" breathing on a place a 2/3 or a head's fall opened,
  till picked: map_view.gd's `pin_mark` / `_show_new` / `pulse_alpha` (360-393), shared, not copied. A head's place
  keeps its diamond.
- **The map**: Matt's 688 x 384 painting at art/map/county.png (the old kept as county_old_512x424.png, not loaded or
  exported), drawn x2 as the Map (map_view.gd:29); LAND, PAINT_SIZE, MAP_AT go (county.gd:25-26, 41). Places, zone names
  and shapes from **data/county_places.tres** (map_places.gd's schema, `sites` the twelve places), today's constants
  rescaled as the fallback. **F3/F5/F4 on the County**: county.gd answers map_placement.gd's calls (`all_places`,
  `placed`, `place_of`, `set_place`, `set_placing`, `paint_size`, `can_place`, `on_screen`, `relay`, the save path).
- **Words** (the language pass): the 24 stage lines, the gates ("After the Toll Plaza 2/3", "After the Bailiff"), the
  24 bases.
- Smoke fit checks: the picker and Head on a County card at both window sizes, the want chips under it, "· New", and the
  longest pin ("The Distribution Centre · 3/3").

## 7. What else moves

- **The bot** (tests/bot.gd:478-500): the County's next uncleared stage at FIRST, the head after the 2/3 at FIRST, its
  highest cleared stage at PUSH; `order_backed_off` keyed by place and stage (514-528). The issued-kit wear holds
  (bot.gd:647-671).
- **The smoke**: `_county_checks` (tests/smoke.gd:28063-28480) moves to the site card and the Bailiff's own fight
  (28287, 28303); `_u51_county_checks` (39278-39356) to the new painting. The odds-settle read (34487-34489) and the
  ladder check (24516-24517: 90/95/100 over the County's top, now 77) hold. New: x1.22 a stage; 2/3 opens the next
  place or the head; 3/3 nothing; a head's fall the next zone; the want on every stage; the theme share and the top-tier
  quarter; a stage plate on its wall and a den from the first man (fixtures, as BUILD57's); places from
  data/county_places.tres and F3/F5 saving there (as BUILD52's); every pin in its zone; §6's fits.
- **The remix** (sim.gd:8595-8635) keeps its own levels; `county_done` reads `county_heads`.
- **Act two's levels** (act_two.md §6) and the balance gates' gate 18 (docs/design/balance_gates.md) read stages. No
  pass (CLAUDE.md, 2 Nov).
- **SAVE_VERSION: no bump if Matt's save hasn't reached the Issue** when this lands: the new state loads with
  defaults, and a save with no County progress isn't left wrong. With a County win on it, the head keys change
  meaning: 26 to 27 (scripts/ui/main.gd:54), no migration. **VERSION** 0.14.1 (scripts/ui/menu.gd:181).

## 8. The build

One release, 0.14.1. Each phase is a commit with the smoke green and a reviewer on the diff, and the three-stage review
runs at the end (CLAUDE.md).

0. **The canvas** (first, Matt's word): the County card on the site card with the picker, Head and the want chips;
   the board's pins with their marks.
1. **Builder A, the sim**: §2's data, state, API and fight; the heads' own fights; wagers and "Run it ×N" on a County
   stage (a repeat of a place is new plumbing: `repeat` holding a place key, each run `deploy_order`); the bot; the save.
2. **Builder U, the UI**: the card's fold and picker, the pins' marks, the stage and den keys; the map's data file,
   F3/F5 and x2 drawing, on today's painting rescaled till Matt's is in.
3. **Builder C, the finds**: COUNTY_THEMES, the top-tier quarter, the 24 bases after the language pass.
4. **Art**: the four manifests by art.flag, after Matt reads the slice on test art.

Each of 1-3 is a stages builder's size: about 1 h to build, 1-1.5 h to review, in parallel (U and C on A's names).
About a day with the canvas round; the art about 1.5 h of running.

**Open calls for Matt (Claude's recommendation first):**

1. **The County's figures**: from its own rows, x1.22 a stage with today's ends (§3). Or keep the curve, a stage two
   levels (x1.254), where the host sites' shapes keep today's uneven steps.
2. **"+1 level a win"**: goes, a stage's level fixed and the 3/3 the grind. Or kept on the 3/3 only.
3. **The 3/3's "tier up" at T9**: a quarter of its finds from the list's T9 alone. Or +1 rarity on that quarter instead.
4. **Gangs**: one count a zone (12 / 11 / 10 / 9, no man jumping more than x1.24). Or the host sites' (7 to 14, a man
   up to x1.6 between places).
5. **The length**: 28 runs through the County against 12, taken as the longer County (act two's 9 h target to be read
   from Matt's play). Or trim, for example with the head's gate at the place's 1/3.
6. **"Run it ×N" on the County** in this build (new plumbing). Or after Matt's play, leaving the County on watched runs.

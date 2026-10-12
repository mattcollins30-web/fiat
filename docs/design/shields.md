# Guard: overheal and shields (12 Oct, built the same day; numbers in the pass)

Matt, 12 Oct: an overheal for the Paramedic, and a version of it for the other classes, so that protection isn't
only resist, armour and HP. **Design only. It's built before the next balance pass**, with over the cap
(docs/design/over_the_cap.md).

## 1. What there is now

- **The layers:** armour (physical, `a/(a+100)`), the resists (the elements, capped at 75), max HP, regen, life a
  kill, meds.
- **Overheal already exists in one place:** Transfusion, the Paramedic's Shifts capstone, turns a med's overflow into
  armour for the run, two HP to one (`m["bonus_armour"]`).
- **Other one-off guards:** Not today (the first killing hit leaves you on half HP), Clean hands (nothing lands for
  three seconds after a med), Held (no second takes more than a tenth of you).

## 2. The rule: Guard

- **Guard** is a second bar over HP. Their fire, and whatever they've left burning or bleeding on you, comes off
  Guard first and HP after. It's taken after armour and resists, so it's on top of them, not instead of them.
- **Its cap** is 15% of max HP (`GUARD_SHARE`; 25% at first, cut after the first read, 12 Oct), raised by `guard_pct`.
- Nothing fills it by itself. **Each class has its own way to fill it** (section 3), and the affixes give everyone a
  little.
- **It lasts the run.** It doesn't decay, and it's gone at the extract or the death. The cap is what stops it running
  away. A save mid-run keeps it: `m["guard"]` saves with the mission, and an older save reads 0.
- **A wound** is HP crossing a quarter, as now, so Guard is what keeps a runner unwounded.
- **The survival % and the dry runs** count it: the odds are the fight's own code.

First figures, for the pass: a 25% cap, and the class sources below.

## 3. Where it comes from

### The Paramedic: overheal, the class's own

- **The class line gains it:** "healing past full is Guard". That covers meds, regen, Walk it off, a kill's life and
  Nan's Cardigan.
- The class line becomes: "+10% damage; meds heal 50% more and are used by themselves under 40% HP; healing past full
  is Guard".
- **Transfusion (the capstone) changes.** Its overflow-to-armour goes, because the class does overflow now. It
  becomes: *"Guard holds half your max HP, and a med fills it to the top."* The node id stays, so a save keeps the
  point.
- **Shifts' empty cell (column 5, row 1): "Overtime"**, a notable: *Guard holds 50% more; while you have Guard, meds
  take half the time.*

### The other four: one notable each, in a class tree's empty column-5 cell

| Class | Tree | Node | Words | Why it's theirs |
| --- | --- | --- | --- | --- |
| Doorman | The door | Squared up | Every gang, as they arrive: Guard of 15% of your max HP | the door's first moment |
| Poacher | Stalking | In the hide | The first of every gang down: Guard of 15% of your max HP | the first-shot class |
| Scrapper | Stripping | Sheet metal | Every cache searched: Guard of 6% of your max HP | the search class: scrap bolted on |
| Drifter | Moving on | Breather | While no one's on you, Guard refills a tenth of its cap a second | the pace class: it recovers between gangs |

- Each costs 4 points (a column-5 notable).
- Each is in the tree that already plays that way. The Doorman's Muscle is full, so his goes in The door.
- A runner with a second class (the second past) can take the other's too.

### The affixes: anyone's, a little

| Affix | Words | Slots | Range |
| --- | --- | --- | --- |
| `guard_gang` | Guard at every gang (% of max HP) | Armour, Helmet | 2-8 |
| `guard_pct` | Guard holds more | Rig, Armour | 10-50 |
| `overflow` | what this heals past full is Guard | Medical (on the rarer meds, like `heal_pct`) | - |

The med's `overflow` is how a non-Paramedic gets overheal. It's one line on a med, read when that med heals.

### The uniques

No new ones in this pass. Two would grow into it naturally: Nan's Cardigan (3% a second back: the Paramedic's runs
it straight into Guard) and the Paramedic's Bumbag. Matt may want a Guard unique later, a core-band rig or helmet.

### The Yard: optional, Matt's call

The Clinic's Drip heals 1% a second on a run. With Guard, a Paramedic's Drip overflows into it, so the Drip needs
nothing new.

## 4. In the sim

- **`m["guard"]`, and `guard_cap() = max_hp() × (GUARD_SHARE + tree and node shares) × (1 + guard_pct / 100)`.**
- **`_guard(m, amount)`** adds to it, capped.
  - Callers: `_heal`'s overflow (the Paramedic, or a med with `overflow`), each gang's arrival (Squared up,
    `guard_gang`), the first of a gang down (In the hide), a cache (Sheet metal), and the tick while nothing's on you
    (Breather).
- **In `_tick`**, before `hp -= incoming × dt`: the damage comes off Guard first, and the rest off HP.
  - Held, Clean hands and Not today keep their order: Held caps the second before Guard takes it, Clean hands zeroes
    it, and Not today reads HP.
- **Transfusion's `bonus_armour`** goes. A mission saved mid-run with it reads it as 0.

## 5. On screen

- **The HP bar** gets a Guard layer. A pale steel band sits over the HP fill from the right, its width Guard over max
  HP, and the HP figure reads "312 + 80".
  - It's on the top bar, the run screen's Operator card, and the Runner's body.
  - A runner without Guard sees nothing new.
- **The run screen's numbers:** what Guard takes shows in Guard's colour, not red. The log gets a line when Guard
  breaks: "Guard gone".
- **The Stats sheet:** a Guard row (its cap, and where it comes from).
- **The pick panel's deltas:** "+6% Guard a gang".
- **Mockups on the design canvas before the build:** the bar with and without Guard, a full Guard over full HP, and
  Guard breaking.

## 6. The checks (smoke)

- Guard takes a hit before HP, and the rest goes to HP.
- Guard is capped at its cap.
- A Paramedic's overflow fills it, and a Doorman's doesn't (unless the med has `overflow`).
- Each class's node fills it at its moment: a gang, the first down, a cache, the quiet.
- Transfusion fills it to the top on a med and doubles the cap.
- It's gone at the extract.
- A save mid-run keeps it; an old save reads 0.
- The dry runs count it: the survival % rises with Guard.
- The bar's Guard band fits, and HP with Guard reads "a + b".

## 7. The pass

- **Deaths and wounds** are the gates it moves. The Paramedic has been the slowest class to the Bank. Guard is
  defence, so expect fewer wounds before more speed.
- The pass decides the 25% cap, the class sources' shares and the affixes' ranges.
- Watch the Drifter: Breather and +10% pace both reward the gaps between gangs.

## 8. For Matt

1. Is "Guard" the right name? Others: Cover, Padding, Second skin.
2. Should the Paramedic's overheal be the class line (my lean), or a node?
3. Transfusion: repointed to Guard as above, or kept as armour with Guard beside it?
4. Are the four classes' sources (Squared up, In the hide, Sheet metal, Breather) right for them?
5. Should Guard last the run with no decay (my lean), or drain slowly?

Matt, 12 Oct: agreed across the board - "Guard", the Paramedic's class line, Transfusion repointed, the four sources,
no decay. Built; the Stats sheet's Guard row and the run screen's Guard-coloured numbers are left (the HP bar's band,
the top bar's "+N" and "Guard gone" are in). What was built: docs/status.md, 12 Oct.

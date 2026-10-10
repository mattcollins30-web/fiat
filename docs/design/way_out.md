# The way out (10 Oct 2026, concept - not built)

From Matt's playtest: early extraction should cost something - "maybe its own timer and a gang you have to see
off?" Agreed with Matt (10 Oct): **the way out, on the run's clock**. Board: Run-P (B) on the design canvas.

## 1. What it is

- Today *Get out now* before the clear is free and instant: a run that goes badly is walked away from at no cost,
  so the run's clock (docs/design/timers.md) only bites a runner who stays.
- With the way out, *Get out now* before the clear starts a **20 s extract**. The gangs on the runner are left
  behind (their heads stay unkilled: no loot, no deeds for them), and **one last gang - the site's own gang at its
  depth, the size of the first lot - stands at the door**.
- **See them off inside the 20 s** and the run comes home with the pack, as an extract today.
- **The 20 s run out with one of them standing**: a **time-out** exactly as the run's clock has it (the pack lost,
  two random pieces of worn kit with it, the runner alive).
- **Down**: a death, as now.
- The 20 s also run on the run's clock: if the clock has less than 20 s left, the way out is that long. So a run
  that is nearly out of time is in the same place either way, and nothing about the way out buys time.
- **After the clear, *Get out now* is free and instant**, as now. So are the leaves that happen after the clear:
  Hit and run, auto-run and "fill up then go". Stand and fight still holds the runner until the clear, so it
  never meets the way out.

## 2. On screen (Run-P B)

- The button says its price before it's pressed: **Get out now · 0:20 and a last gang** (after the clear it is
  plain *Get out now*).
- Pressed: the band's headline becomes the extract counting down in amber (*Getting out · 0:14*); the fight box
  shows the way-out gang (kicker *to the way out · see them off*); the button greys to *Getting out*.
- The log: *Making for the way out, N at the door*, then *Seen off - out with the pack* / *Out of time at the door*.
- The odds strip doesn't change: it reads the run, not the way out.

## 3. Numbers to set in the balance pass

- `WAY_OUT_S` 20, the size of the door gang (the first lot's size, so the Lookout's Flares, Trapline and the
  Poacher's snare shrink it as they shrink the first lot), and its depth (the site's).
- The dry runs behind the odds and the bot: the bot leaves early today when a run turns (`tests/bot.gd`); with
  the way out that leave can lose the pack, so its "run's going badly" test has to look at whether it can see
  off a gang in 20 s. Read the balance gate's deaths and time-outs after it - an early leave now has a cost, so
  both may rise a little.

## 4. Open for Matt

- 20 s flat, or growing with the tier (as the run's clock does)?
- Should the door gang carry the site's Radio words (a tougher site, a tougher door)? The concept says yes, since
  it's the site's own gang.

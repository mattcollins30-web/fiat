#!/usr/bin/env python3
"""The balance summary: reads every docs/balance/*.txt that tools/balance.bat
wrote, takes the GATES line from each (one JSON object a build; the probe's
carries the loot figures), and writes docs/balance/summary.md: the gates
table from docs/design/concept.md with each row read red or green, then a
line a build with its firsts, odds and economy, so the pass can be read
without opening the raw files.

    python3 tools/balance_summary.py            # docs/balance -> docs/balance/summary.md

The gate figures are the concept's defaults; change them here when the pass
settles them. Deaths (the player's own, from the playtest save) is not a bot
figure and is left to Matt's count.
"""
import glob
import json
import os
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FOLDER = os.path.join(ROOT, "docs", "balance")

BANK_BAND = 1.5          # slowest to the bank within this many times the fastest
KEYSTONE_BY = 2.0        # hour
CAPSTONE_BY = 4.0        # hour
ODDS_FLOOR = 0.6         # survival at every open tier in the kit the tier before drops
ELITE_SHARE = 0.03       # at +35% quality
ELITE_SHARE_PLAIN = 0.02
FINDS_RATIO = (1.20, 1.30)   # finds a search at +25% quantity, against plain
CASH_SINK = 3.0          # cash in hand at the end, times the top bench level
DEPTH_FROM = 4.0         # depths an hour from this hour to the end: at least one
WOUNDS = (0.10, 0.25)    # share of runs ending wounded
SCRAP = (1.0, 3.0)       # scrap in hand at hour 4 against the dearest craft (we read the end)


def read_gates():
    builds = []
    probe = None
    for path in sorted(glob.glob(os.path.join(FOLDER, "*.txt"))):
        g = None
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                if line.startswith("GATES "):
                    try:
                        g = json.loads(line[6:])
                    except json.JSONDecodeError:
                        g = None
        if g is None:
            builds.append({"build": os.path.basename(path)[:-4], "missing": True})
        elif g.get("build") == "probe":
            probe = g
        else:
            builds.append(g)
    return builds, probe


def hours(v):
    return "never" if v is None or v < 0 else "%.1f h" % v


def mark(ok):
    return "GREEN" if ok else "RED"


def main():
    builds, probe = read_gates()
    full = [b for b in builds if not b.get("missing")]
    if not full and probe is None:
        print("no GATES lines under docs/balance; run tools\\balance.bat first", file=sys.stderr)
        return 1
    rows = []
    notes = []

    # the bank's band
    banks = [b["bank_at"] for b in full if b["bank_at"] >= 0]
    never = [b["build"] for b in full if b["bank_at"] < 0]
    if full:
        ok = not never and banks and max(banks) <= BANK_BAND * min(banks)
        text = "fastest %s, slowest %s" % (hours(min(banks)), hours(max(banks))) if banks else "no build reached the bank"
        if never:
            text += "; never: " + ", ".join(never)
        rows.append(("The bank's band", "slowest within %.1fx the fastest" % BANK_BAND, text, ok))

    # the keystone, the capstone
    for key, name, by in (("keystone_at", "The keystone", KEYSTONE_BY), ("capstone_at", "The capstone", CAPSTONE_BY)):
        if not full:
            continue
        late = [(b["build"], b[key]) for b in full if b[key] < 0 or b[key] > by]
        ok = not late
        if ok:
            text = "every build by %s (latest %s)" % (hours(by), hours(max(b[key] for b in full)))
        else:
            text = "late: " + ", ".join("%s %s" % (n, hours(h)) for n, h in late)
        rows.append((name, "by hour %.0f, every build" % by, text, ok))

    # no reds: the odds reader at every open tier
    if full:
        reds = []
        for b in full:
            for tier, surv in b.get("odds", []):
                if surv < ODDS_FLOOR:
                    reds.append("%s T%d %.0f%%" % (b["build"], tier, surv * 100))
        rows.append(("No reds", "no open tier under %.0f%%" % (ODDS_FLOOR * 100), ("; ".join(reds) if reds else "every open tier at or over the floor"), not reds))

    # the probe's two
    if probe is not None:
        es, esp = probe["elite_share"], probe["elite_share_plain"]
        ok = es >= ELITE_SHARE and esp >= ELITE_SHARE_PLAIN
        rows.append(("Loot quality visible", "Elite share %.1f%% at +35%% quality (%.1f%% plain)" % (ELITE_SHARE * 100, ELITE_SHARE_PLAIN * 100),
                     "%.2f%% boosted, %.2f%% plain" % (es * 100, esp * 100), ok))
        fr = probe["finds_ratio"]
        ok = FINDS_RATIO[0] <= fr <= FINDS_RATIO[1]
        rows.append(("Quantity honest", "finds at +25%% quantity %.2f to %.2f times plain" % FINDS_RATIO,
                     "%.2f (%.2f against %.2f a search)" % (fr, probe["finds_boosted"], probe["finds_plain"]), ok))
    else:
        rows.append(("Loot quality visible", "", "no probe read", False))
        rows.append(("Quantity honest", "", "no probe read", False))

    # cash sink
    if full:
        over = [(b["build"], b["cash_end"], b["top_bench"]) for b in full if b["cash_end"] > CASH_SINK * b["top_bench"]]
        text = "; ".join("%s holds £%d against a £%d top bench" % o for o in over) if over else "every build under %.0fx the top bench (most £%d)" % (CASH_SINK, max(b["cash_end"] for b in full))
        rows.append(("Cash sink", "cash in hand at the end no more than %.0fx the top bench level" % CASH_SINK, text, not over))

    # depth pace
    if full:
        slow = []
        for b in full:
            span = max(0.0, b.get("elapsed_h", b["hours"]) - DEPTH_FROM)
            late = [c for c in b.get("depth_clears", []) if c[0] >= DEPTH_FROM]
            pace = (len(late) / span) if span > 0 else 0.0
            b["_pace"] = pace
            if span > 0 and pace < 1.0:
                slow.append("%s %.1f/h" % (b["build"], pace))
        if all(b.get("elapsed_h", b["hours"]) <= DEPTH_FROM for b in full):
            rows.append(("Depth pace", "at least one depth an hour from hour %.0f" % DEPTH_FROM, "read shorter than %.0f h; not measured" % DEPTH_FROM, None))
        else:
            rows.append(("Depth pace", "at least one depth an hour from hour %.0f" % DEPTH_FROM, "; ".join(slow) if slow else "every build at a depth an hour or better", not slow))

    rows.append(("Deaths", "one every N hours at Matt's risk", "from the playtest save, not the bot; Matt's count", None))

    # wounds
    if full:
        off = []
        for b in full:
            share = (b["wounded_runs"] / b["runs"]) if b["runs"] else 0.0
            b["_wounds"] = share
            if not WOUNDS[0] <= share <= WOUNDS[1]:
                off.append("%s %.0f%%" % (b["build"], share * 100))
        rows.append(("Wounds", "%.0f to %.0f%% of runs end wounded" % (WOUNDS[0] * 100, WOUNDS[1] * 100), "; ".join(off) if off else "every build in the band", not off))

    # scrap economy
    if full:
        off = []
        for b in full:
            crafts = (b["scrap_end"] / b["dearest_build"]) if b.get("dearest_build") else 0.0
            b["_crafts"] = crafts
            if not SCRAP[0] <= crafts <= SCRAP[1]:
                off.append("%s %.1f crafts" % (b["build"], crafts))
        rows.append(("Scrap economy", "scrap in hand worth %.0f to %.0f of the dearest craft" % SCRAP, "; ".join(off) if off else "every build in the band", not off))

    reds = sum(1 for r in rows if r[3] is False)
    out = []
    out.append("# Balance summary")
    out.append("")
    out.append("Written %s by tools/balance_summary.py from %d build reads%s. %s" % (
        time.strftime("%Y-%m-%d %H:%M"), len(full), " and the probe" if probe else " (no probe)",
        ("%d RED." % reds) if reds else "No reds."))
    missing = [b["build"] for b in builds if b.get("missing")]
    if missing:
        out.append("")
        out.append("No GATES line in: " + ", ".join(missing) + " (the read crashed or was cut short; see its .txt).")
    out.append("")
    out.append("| Gate | Green when | Read | |")
    out.append("| --- | --- | --- | --- |")
    for name, green, text, ok in rows:
        out.append("| %s | %s | %s | %s |" % (name, green, text, "—" if ok is None else mark(ok)))
    out.append("")
    out.append("## The builds")
    out.append("")
    out.append("| Build | Hours | Bank | Keystone | Capstone | Level | Best tier (depth) | Runs | Deaths | Wounded | Cash | Top bench | Scrap (crafts) | Depths/h after %.0f | Odds by tier | Kit |" % DEPTH_FROM)
    out.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
    for b in full:
        depth = b["best_depth"][b["best_tier"]] if b.get("best_depth") and b.get("best_tier", -1) >= 0 and b["best_tier"] < len(b["best_depth"]) else 0
        odds = " ".join("T%d %.0f%%" % (t, s * 100) for t, s in b.get("odds", []))
        out.append("| %s | %.1f (%.0f s wall) | %s | %s | %s | %d | %d (%d) | %d | %d | %.0f%% | £%d | £%d | %d (%.1f) | %.1f | %s | %s |" % (
            b["build"], b.get("elapsed_h", b["hours"]), b.get("wall_s", 0), hours(b["bank_at"]), hours(b["keystone_at"]), hours(b["capstone_at"]),
            b.get("level", 0), b.get("best_tier", 0), depth, b["runs"], b["deaths"], b.get("_wounds", 0) * 100,
            b["cash_end"], b["top_bench"], b["scrap_end"], b.get("_crafts", 0), b.get("_pace", 0), odds, b.get("kit", "")))
    out.append("")
    out.append("Depth clears as [hour, tier, depth]:")
    out.append("")
    for b in full:
        out.append("- %s: %s" % (b["build"], ", ".join("%.1f T%d d%d" % tuple(c) for c in b.get("depth_clears", [])) or "none"))
    out.append("")
    path = os.path.join(FOLDER, "summary.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print("\n".join(out[:out.index("## The builds") - 1]))
    print("-> " + os.path.relpath(path, ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())

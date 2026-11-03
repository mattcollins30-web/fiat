"""The skill web's layout (docs/design/skill_web.md, 3 Nov): writes scripts/sim/web_layout.gd.
Run: python3 tools/make_skill_web.py (from the repo root). The canvas rounds used the same geometry."""
import math, json, os, sys
C = 500
def P(r, a): return (C + r * math.cos(math.radians(a)), C + r * math.sin(math.radians(a)))
def Q(c, r, a): return (c[0] + r * math.cos(math.radians(a)), c[1] + r * math.sin(math.radians(a)))
def ang(p, q): return math.degrees(math.atan2(q[1] - p[1], q[0] - p[0]))
CLASSES = [("Poacher", -90, "Stalking", "Snares"), ("Paramedic", -30, "Triage", "Shifts"), ("Scrapper", 30, "Stripping", "Fencing"),
           ("Drifter", 90, "Moving on", "Luck"), ("Doorman", 150, "Muscle", "The door"), ("Recruit", 210, "Ordnance", "Drill")]
ELEMS = [("The cold", -60), ("Live", 0), ("Petrol", 60), ("Blades", 120), ("Knuckles", 180), ("The Rat Man", 240)]
PITCH = "The Pitch"
N, L = {}, []
def add(slot, p, kind, tree, name="", pool="", region=""):
    N[slot] = {"slot": slot, "at": [round(p[0] - C, 1), round(p[1] - C, 1)], "kind": kind, "tree": tree, "name": name, "pool": pool, "region": region}
def link(a, b): L.append([a, b])
SKILLS = {   # a class tree's hung skills, in today's order (data.gd WEB_EXTRA)
 "Stalking": ["Flush them out", "Go to ground", "One for the pot"], "Snares": ["Collared", "Gin trap", "Decoy", "Net every hole"],
 "Triage": ["Antidote", "Adrenaline", "Major incident"], "Shifts": ["Two sugars", "Sedative dart", "Strapped up", "Code blue"],
 "Stripping": ["Hot work", "Breakdown", "Short circuit"], "Fencing": ["Bung", "Knock-off kit", "Back of the van", "Everything must go"],
 "Moving on": ["Look lively", "Elbow room", "Gone"], "Luck": ["Coin toss", "Close shave", "Chancer", "Jackpot"],
 "Muscle": ["Headbutt", "Brace", "Barred"], "The door": ["Not on the list", "Shutters down", "Pat down", "Chucking-out time"],
 "Ordnance": ["Flashbang", "Smoke", "Danger close"], "Drill": ["Suppressing fire", "Make ready", "Stand to", "Fire and manoeuvre"],
}
KEY3 = {"Poacher": "Snare and wait", "Paramedic": "Jab", "Scrapper": "Breaker's yard", "Drifter": "On a roll", "Doorman": "Bin lid", "Recruit": "Firing blanks"}
# an element's two hung notables with a rule of their own (the plain figures' hangs go): on the run's first and last smalls
EL_HANGS = {"The cold": ["Deep freeze", "Brittle"], "Live": ["Capacitor", "Overload"], "Petrol": ["Oil drum", "Backdraught"],
            "Blades": ["Serrated", "Arterial"], "Knuckles": [None, "Floored"], "The Rat Man": ["Takes its time", "Catching"]}
def place(slot, name, kind, tree):
    s = N[slot]; assert not s["name"], (slot, s["name"], name)
    s["name"] = name; s["kind"] = kind; s["tree"] = tree; s["pool"] = ""
# the centre
add("C", (C, C), "notable", PITCH, "The dog's share", region="centre")
STAT = {"L": "stat:hp", "G": "stat:guard", "P": "stat:pace"}
GATES = {0: "Double tap", 1: "Second wind", 2: "Pack horse", 3: "Word of mouth"}     # Word of mouth on g3 (3 Nov, the review of build 47: its rule was off the web)
for k, (nm, a) in enumerate(ELEMS):
    add(f"h{k}", P(50, a), "small", PITCH, pool=STAT["LGP"[k % 3]], region="centre")
    add(f"o{k}-", P(92, a - 15), "small", PITCH, pool=STAT["LGP"[(2 * k) % 3]], region="centre")
    add(f"o{k}+", P(92, a + 15), "small", PITCH, pool=STAT["LGP"[(2 * k + 1) % 3]], region="centre")
    if k in GATES: add(f"g{k}", P(128, a), "notable", PITCH, GATES[k], region="centre")
    else: add(f"g{k}", P(128, a), "small", PITCH, pool="filler", region="centre")     # an open gate: a small until it's designed
# Long walks and Circuits fold into the life nodes (the spec): the inner ring's two life smalls, their own values
place("h0", "Long walks", "small", PITCH); place("h3", "Circuits", "small", PITCH)
for k in range(6):
    n = (k + 1) % 6
    for a, b in [("C", f"h{k}"), (f"h{k}", f"h{n}"), (f"h{k}", f"o{k}-"), (f"h{k}", f"o{k}+"), (f"o{k}-", f"o{k}+"), (f"o{k}+", f"o{n}-"), (f"o{k}-", f"g{k}"), (f"o{k}+", f"g{k}")]: link(a, b)
# the element flowers
ENAMES = {
 "The cold": {"0": "De-icer", "1": "Frost", "3": "A hard winter", "5": "Numb", "7": "Wind chill", "n": "Chill", "2": "Poacher's snare", "6": "Paramedic's ice", "4": "Cold hands", "rN": "Thermals", "ks": "Frozen solid", "cap": "Shatter"},
 "Live": {"0": "Sparks", "1": "Charge", "3": "Off the mains", "5": "Amps", "7": "Volts", "n": "Current", "2": "Paramedic's paddles", "6": "Scrapper's mains", "4": "Earthed", "rN": "Rubber soles", "ks": "Daisy chain", "cap": "Arc"},
 "Petrol": {"0": "A can of it", "1": "Rags", "3": "Siphoned", "5": "Wick", "7": "Fumes", "n": "Lit", "2": "Scrapper's torch", "6": "Drifter's can", "4": "On your hands", "rN": "Fireproof", "ks": "Spreads", "cap": "Wildfire"},
 "Blades": {"0": "Stanley knife", "1": "An edge", "3": "Sharpened", "5": "Deep", "7": "Nicked", "n": "Opened up", "2": "Drifter's razor", "6": "Doorman's glass", "4": "Blood up", "rN": "Scar tissue", "ks": "Won't stop", "cap": "Bleed out"},
 "Knuckles": {"0": "Bare hands", "1": "Wraps", "3": "Half a brick", "5": "Thick skull", "7": "Weight behind it", "n": "Stagger", "2": "Doorman's knuckles", "6": "Recruit's boots", "4": "Heavy", "rN": "Thick-skinned", "ks": "Bust them up", "cap": "Flattened"},
 "The Rat Man": {"0": "Under the sink", "1": "Bait", "3": "Council issue", "5": "Cumulative", "7": "Slow acting", "n": "Dosed", "2": "Recruit's gas", "6": "Poacher's bait", "4": "Rat's share", "rN": "Immune", "ks": "Builds", "cap": "Lingers"},
}
for k, (nm, a) in enumerate(ELEMS):
    c = P(200, a); E = ENAMES[nm]; reg = "el:" + nm
    for i in range(8):
        kind = "notable" if i in (2, 4, 6) else "small"
        add(f"e{k}_{i}", Q(c, 44, a + 180 + i * 45), kind, nm, E[str(i)], region=reg)
    add(f"e{k}_n", c, "notable", nm, E["n"], region=reg)
    for i in range(8): link(f"e{k}_{i}", f"e{k}_{(i + 1) % 8}")
    link(f"g{k}", f"e{k}_0"); link(f"e{k}_0", f"e{k}_n")
    prev = f"e{k}_4"
    for s, r, kind in [("r1", 266, "small"), ("r2", 288, "small"), ("rN", 310, "notable"), ("r3", 332, "small"), ("ks", 356, "keystone"), ("cap", 388, "capstone")]:
        add(f"e{k}_{s}", P(r, a), kind, nm, E.get(s, ""), pool="" if s in E else "filler", region=reg); link(prev, f"e{k}_{s}"); prev = f"e{k}_{s}"
    for s, h in zip(("r1", "r3"), EL_HANGS[nm]):
        if h: place(f"e{k}_{s}", h, "notable", nm)
# the classes: four flowers each
CNAMES = {   # start, Sn, S4, Ln, Lpair, L2, Lkey, Rn, Rpair, R2, Rkey, Fn, F2, F3, cap
 "Poacher": ["Clean shot", "Early doors", "In the hide", "Rifleman", "Rat bait", "Clocked", "One shot", "Quiet feet", "Cold snap", "Twine", "Trapline", "Night work", "Poached", None, "Dead quiet"],
 "Paramedic": ["Tourniquet", "Second shift", "Double shift", "Fast work", "Ice pack", "Worst first", "Field surgery", "Walk it off", "Defib", "Clocking off", "Not today", "Walking wounded", "Transfusion", None, "Clean hands"],
 "Scrapper": ["Ring main", "Workbench", "Sheet metal", "Bodger", "Live wire", "Salvage", "Nothing wasted", "Magpie", "Blowtorch", "Back pocket", "Buyer's market", "Quiet hands", "The lot", "Hoarder", "Jerry-rigged"],
 "Drifter": ["Duck and weave", "Light fingers", "Breather", "Spray", "Bottle and rag", "B-roads", "Never there", "Dead man's shoes", "Cut-throat", "Spare change", "All or nothing", "Hit and run", "Loaded dice", None, "Ghost"],
 "Doorman": ["Shoulder charge", "Through the lot", "Squared up", "Shotgunner", "Glassing", "Off the canvas", "Bodyline", "Chokepoints", "Hands on", "Last orders", "One at a time", "Loud", "Iron", "Stand and fight", "Held"],
 "Recruit": ["Lob one in", None, "Double time", "Cook it off", "Brute force", None, "Grenadier", "Cover me", "Tear gas", None, "Quick march", "Blast burns", "Passing-out parade", None, "Ringing ears"],
}
KEYS = ["start", "Sn", "S4", "Ln", "Lpair", "L2", "Lkey", "Rn", "Rpair", "R2", "Rkey", "Fn", "F2", "F3", "cap"]
def nearest(c, o, toward):
    t = ang(c, toward); return min(range(8), key=lambda i: abs(((o + 180 + i * 45) - t + 180) % 360 - 180))
START = {}
for j, (nm, a, lt, rt) in enumerate(CLASSES):
    cen = {"S": P(300, a), "L": P(372, a - 17), "R": P(372, a + 17), "F": P(440, a)}
    tree_of = {"S": lt, "L": lt, "R": rt, "F": rt}
    o = {c: ang((C, C), p) for c, p in cen.items()}
    for c, p in cen.items():
        for i in range(8): add(f"k{j}_{c}{i}", Q(p, 34, o[c] + 180 + i * 45), "small", tree_of[c], pool=("class:" + tree_of[c]) if c in "LR" else "filler", region="class:" + nm)
        add(f"k{j}_{c}n", p, "notable", tree_of[c], region="class:" + nm)
        for i in range(8): link(f"k{j}_{c}{i}", f"k{j}_{c}{(i + 1) % 8}")
        link(f"k{j}_{c}0", f"k{j}_{c}n")
    sl = nearest(cen["S"], o["S"], cen["L"]); sr = nearest(cen["S"], o["S"], cen["R"])
    ls = nearest(cen["L"], o["L"], cen["S"]); rs = nearest(cen["R"], o["R"], cen["S"])
    lf = nearest(cen["L"], o["L"], cen["F"]); rf = nearest(cen["R"], o["R"], cen["F"])
    fl = nearest(cen["F"], o["F"], cen["L"]); fr = nearest(cen["F"], o["F"], cen["R"])
    link(f"k{j}_S{sl}", f"k{j}_L{ls}"); link(f"k{j}_S{sr}", f"k{j}_R{rs}")
    link(f"k{j}_L{lf}", f"k{j}_F{fl}"); link(f"k{j}_R{rf}", f"k{j}_F{fr}")
    lp = nearest(cen["L"], o["L"], Q(cen["L"], 50, a - 100)); rp = nearest(cen["R"], o["R"], Q(cen["R"], 50, a + 100))
    lk = rk = 4
    ul = {0, ls, lf, lp}; ur = {0, rs, rf, rp}
    if lk in ul: lk = next(i for i in (3, 5) if i not in ul)
    if rk in ur: rk = next(i for i in (5, 3) if i not in ur)
    l2 = next(i for i in (6, 2, 7, 1) if i not in ul | {lk}); r2 = next(i for i in (2, 6, 1, 7) if i not in ur | {rk})
    f2 = next(i for i in (2, 6, 3, 5) if i not in {0, 4, fl, fr}); f3 = next(i for i in (6, 2, 5, 3) if i not in {0, 4, fl, fr, f2})
    slot = dict(start="S0", Sn="Sn", S4="S4", Ln="Ln", Lpair=f"L{lp}", L2=f"L{l2}", Lkey=f"L{lk}", Rn="Rn", Rpair=f"R{rp}", R2=f"R{r2}", Rkey=f"R{rk}", Fn="Fn", F2=f"F{f2}", F3=f"F{f3}", cap="F4")
    kind = dict(start="start", Lkey="keystone", Rkey="keystone", cap="capstone")
    for key, name in zip(KEYS, CNAMES[nm]):
        s = N[f"k{j}_{slot[key]}"]
        if name:
            s["name"] = name; s["kind"] = kind.get(key, "notable"); s["pool"] = ""
            if key == "Lpair": s["pair"] = "left"
            if key == "Rpair": s["pair"] = "right"
        else:
            s["kind"] = "small"; s["pool"] = "filler"     # an open slot (the Recruit's, the far flowers' third): a small for now
    START[nm] = f"k{j}_S0"
    # the skills that hang off notables (BUILD47-W, the builder's call: the spec keeps them, its table had no slot for
    # them): the left tree's three on the start's flower's left side, the right tree's first three on its right side,
    # its fourth and the class's third keystone on the far flower's two free sides (the keystone toward the left tree)
    ls_, rs_ = SKILLS[lt], SKILLS[rt]
    for i, nmx in zip((1, 2, 3), ls_[:3]): place(f"k{j}_S{i}", nmx, "notable", lt)
    for i, nmx in zip((5, 6, 7), rs_[:3]): place(f"k{j}_S{i}", nmx, "notable", rt)
    free = [i for i in range(1, 8) if i not in {4, fl, fr, f2, f3}]
    assert len(free) == 2, (nm, free)
    free.sort(key=lambda i: math.dist(Q(cen["F"], 34, o["F"] + 180 + i * 45), cen["L"]))
    place(f"k{j}_F{free[0]}", KEY3[nm], "keystone", lt)
    place(f"k{j}_F{free[1]}", rs_[3], "notable", rt)
# the joins: four steps from a class's start to the facing side of each of its elements; the Pitch's smalls go on the second step
PITCH_SMALLS = ["Dry fire", "Zeroing", "Knowing the streets", "Keen eyes", "Stashing"]
pi = 0
for k, (nm, a) in enumerate(ELEMS):
    for s, i, j in [("L", 2, k), ("R", 6, (k + 1) % 6)]:
        p = N[f"e{k}_{i}"]["at"]; q = N[f"k{j}_S0"]["at"]; prev = f"k{j}_S0"
        for n in range(1, 5):
            pos = (C + q[0] + (p[0] - q[0]) * n / 5, C + q[1] + (p[1] - q[1]) * n / 5)
            nmx, pool = "", "filler"
            if n == 2 and pi < len(PITCH_SMALLS): nmx, pool = PITCH_SMALLS[pi], ""; pi += 1
            add(f"x{k}{s}{n}", pos, "small", PITCH if nmx else nm, nmx, pool, region="join")
            link(prev, f"x{k}{s}{n}"); prev = f"x{k}{s}{n}"
        link(prev, f"e{k}_{i}")
# the empty notables (a flower centre with no name): small fillers
for s in N.values():
    if s["kind"] == "notable" and not s["name"]: s["kind"] = "small"; s["pool"] = s["pool"] or "filler"
# checks
adj = {}
for a, b in L: adj.setdefault(a, set()).add(b); adj.setdefault(b, set()).add(a)
for st in START.values():
    seen = {st}; todo = [st]
    while todo:
        x = todo.pop()
        for y in adj[x]:
            if y not in seen: seen.add(y); todo.append(y)
    assert len(seen) == len(N), (st, len(seen), len(N))
names = [s["name"] for s in N.values() if s["name"]]
assert len(names) == len(set(names)), [n for n in names if names.count(n) > 1]
if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "scripts/sim/web_layout.gd"
    lines = ["## The skill web's layout (docs/design/skill_web.md, 3 Nov). Generated by tools/make_skill_web.py - don't edit by hand.",
             "## A slot: its place (web units, the centre at 0,0, 12 o'clock up), its kind, the tree its node belongs to, the node's",
             "## name (today's node, found by name) or a pool for an unnamed small (class:<tree> - that tree's smalls in order;",
             "## stat:hp / stat:guard / stat:pace - the centre's rings; filler - FILLERS), its region, and a pair's side.",
             "class_name WebLayout", "", "const SLOTS := ["]
    for s in N.values(): lines.append("\t" + json.dumps(s, ensure_ascii=False) + ",")
    lines += ["]", "", "const LINKS := ["]
    for a, b in L: lines.append("\t[%s, %s]," % (json.dumps(a), json.dumps(b)))
    lines += ["]", "", "const STARTS := " + json.dumps(START), ""]
    open(out, "w", encoding="utf-8").write("\n".join(lines))
    print(len(N), "slots", len(L), "links", len(names), "named", "pitch smalls placed", pi)

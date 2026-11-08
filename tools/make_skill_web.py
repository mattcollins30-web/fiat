"""The skill web's layout, version two (docs/design/skill_web.md, 4 Nov): writes scripts/sim/web_layout.gd.
Run: python3 tools/make_skill_web.py (from the repo root). The places and the joins are the agreed layout's
(docs/design/skill_web_layout.json, the canvas's round six); this fills each place with its node ("The places
filled") and gives every lesser node its track's pool. Version one (3 Nov, the petals) is in git history."""
import math, json, sys
SRC = "docs/design/skill_web_layout.json"
CLASSES = [("Poacher", -90, "Stalking", "Snares"), ("Paramedic", -30, "Triage", "Shifts"), ("Scrapper", 30, "Stripping", "Fencing"),
           ("Drifter", 90, "Moving on", "Luck"), ("Doorman", 150, "Muscle", "The door"), ("Recruit", 210, "Ordnance", "Drill")]
ELEMS = [("The cold", -60), ("Live", 0), ("Petrol", 60), ("Blades", 120), ("Knuckles", 180), ("The Rat Man", 240)]
PITCH = "The Pitch"
SKILLS = {   # a class tree's skills, in today's order (data.gd WEB_EXTRA)
 "Stalking": ["Flush them out", "Go to ground", "One for the pot"], "Snares": ["Collared", "Gin trap", "Decoy", "Net every hole"],
 "Triage": ["Antidote", "Adrenaline", "Major incident"], "Shifts": ["Two sugars", "Sedative dart", "Strapped up", "Code blue"],
 "Stripping": ["Hot work", "Breakdown", "Short circuit"], "Fencing": ["Bung", "Knock-off kit", "Back of the van", "Everything must go"],
 "Moving on": ["Look lively", "Elbow room", "Gone"], "Luck": ["Coin toss", "Close shave", "Chancer", "Jackpot"],
 "Muscle": ["Headbutt", "Brace", "Barred"], "The door": ["Not on the list", "Shutters down", "Pat down", "Chucking-out time"],
 "Ordnance": ["Flashbang", "Smoke", "Danger close"], "Drill": ["Suppressing fire", "Make ready", "Stand to", "Fire and manoeuvre"],
}
# the template's places (the Poacher's slot names in the layout) and each class's node for them (skill_web.md "The places filled")
CNAMES = {   # start, corner notable, staying up, Ln, Lpair, L2, Lkey, Rn, Rpair, R2, Rkey, finds 1, finds 2, capstone, corner keystone
 "Poacher": ["Clean shot", "Early doors", "In the hide", "Rifleman", "Rat bait", "Clocked", "One shot", "Quiet feet", "Cold snap", "Twine", "Trapline", "Night work", "Poached", "Dead quiet", "Snare and wait"],
 "Paramedic": ["Tourniquet", "Second shift", "Double shift", "Fast work", "Ice pack", "Worst first", "Field surgery", "Walk it off", "Defib", "Clocking off", "Not today", "Walking wounded", "Transfusion", "Clean hands", "Jab"],
 "Scrapper": ["Ring main", "Workbench", "Sheet metal", "Bodger", "Live wire", "Salvage", "Nothing wasted", "Magpie", "Blowtorch", "Back pocket", "Buyer's market", "Quiet hands", "The lot", "Jerry-rigged", "Breaker's yard"],
 "Drifter": ["Duck and weave", "Light fingers", "Breather", "Spray", "Bottle and rag", "B-roads", "Never there", "Dead man's shoes", "Cut-throat", "Spare change", "All or nothing", "Hit and run", "Loaded dice", "Ghost", "On a roll"],
 "Doorman": ["Shoulder charge", "Through the lot", "Squared up", "Shotgunner", "Glassing", "Off the canvas", "Bodyline", "Chokepoints", "Hands on", "Last orders", "One at a time", "Loud", "Iron", "Held", "Bin lid"],
 "Recruit": ["Lob one in", "Bulled boots", "Double time", "Cook it off", "Brute force", "Fuse cut short", "Grenadier", "Cover me", "Tear gas", "By the numbers", "Quick march", "Blast burns", "Passing-out parade", "Ringing ears", "Firing blanks"],
}
PLACES = ["start", "N", "hide", "rifleman", "ratbait", "clocked", "oneshot", "quiet", "coldsnap", "twine", "trapline", "nightwork", "poached", "deadquiet", "K"]
STARTER = {"Poacher": "Still hands", "Paramedic": "Steady pulse", "Scrapper": "Nose for parts", "Drifter": "Light feet", "Doorman": "Heavy hands", "Recruit": "Pull the pin"}
FINDS_LESSER = {"Scrapper": "Hoarder", "Doorman": "Stand and fight"}     # version one's third far notable, stepped down in a finds cluster
# the elements' columns: the cluster's node (skill_web.md's element table and "The places filled")
ENAMES = {   # conv, n, tip, res, ks, cap; the low pair (fL, fR), beside the tip (eL, eR), before the keystone (hL, hR); four smalls (fL, fR, eL, hL clusters)
 "The cold": ["De-icer", "Chill", "Cold hands", "Thermals", "Frozen solid", "Shatter", "Chilblains", "Sleet", "Deep freeze", "Brittle", "Black ice", "Brass monkeys", "Frost", "A hard winter", "Numb", "Wind chill"],
 "Live": ["Sparks", "Current", "Earthed", "Rubber soles", "Daisy chain", "Arc", "Live rail", "Stripped wire", "Capacitor", "Overload", "Crossed wires", "Fuse box", "Charge", "Off the mains", "Amps", "Volts"],
 "Petrol": ["A can of it", "Lit", "On your hands", "Fireproof", "Spreads", "Wildfire", "Accelerant", "Flashpoint", "Oil drum", "Backdraught", "Forecourt", "Bonfire night", "Rags", "Siphoned", "Wick", "Fumes"],
 "Blades": ["Stanley knife", "Opened up", "Blood up", "Scar tissue", "Won't stop", "Bleed out", "Honed", "Whetstone", "Serrated", "Arterial", "Paper cuts", "Shiv", "An edge", "Sharpened", "Deep", "Nicked"],
 "Knuckles": ["Bare hands", "Stagger", "Heavy", "Thick-skinned", "Bust them up", "Flattened", "Knuckleduster", "Shin pads", "Low blow", "Floored", "Sucker punch", "Bare-knuckle", "Wraps", "Half a brick", "Thick skull", "Weight behind it"],
 "The Rat Man": ["Under the sink", "Dosed", "Rat's share", "Immune", "Builds", "Lingers", "Strychnine", "Tainted", "Takes its time", "Catching", "Nest", "Rat run", "Bait", "Council issue", "Cumulative", "Slow acting"],
}
EPLACES = ["conv", "n", "tip", "res", "ks", "cap", "fL", "fR", "eL", "eR", "hL", "hR", "fL.0", "fR.0", "eL.0", "hL.0"]
# the pair halves in a column, by the class each faces: pairL the class anticlockwise of the element, pairR the clockwise one
EPAIRS = {"The cold": ["Poacher's snare", "Paramedic's ice"], "Live": ["Paramedic's paddles", "Scrapper's mains"], "Petrol": ["Scrapper's torch", "Drifter's can"],
          "Blades": ["Drifter's razor", "Doorman's glass"], "Knuckles": ["Doorman's knuckles", "Recruit's boots"], "The Rat Man": ["Recruit's gas", "Poacher's bait"]}
# the centre: the dog's share, the inner ring (life, Guard, pace, twice, on the elements' lines), the outer ring under the starts
CENTRE = {"C": "The dog's share", "h0": "Circuits", "h1": "Chin down", "h2": "Good boots", "h3": "Home ground", "h4": "Elbows in", "h5": "Shortcuts",
          "o0": "Double tap", "o1": "Second wind", "o2": "Pack horse", "o3": "Word of mouth", "o4": "Market day", "o5": "Well stocked",
          # the Pitch's named lesser nodes: Long walks in a life cluster, the kettle in Second wind's, the rest one an outer cluster
          "h3.0": "Long walks", "o1.0": "The kettle", "o0.0": "Dry fire", "o2.0": "Zeroing", "o3.0": "Knowing the streets", "o4.0": "Stashing", "o5.0": "Keen eyes"}
RING_STAT = {0: "stat:hp", 1: "stat:guard", 2: "stat:pace"}
# the nodes version one moved out of their own tree (its far flower and its corner were the other tree's): they stay in
# version one's, so their ids go on as "Tree/<n>" (BUILD49-W: "ids keep Tree/Node where today's node goes on")
V1_TREE = {"Early doors": "Stalking", "Dead quiet": "Snares", "Night work": "Snares", "Double shift": "Triage", "Second shift": "Triage",
           "Clean hands": "Shifts", "Walking wounded": "Shifts", "Jerry-rigged": "Fencing", "Quiet hands": "Fencing", "Light fingers": "Moving on",
           "Ghost": "Luck", "Hit and run": "Luck", "Squared up": "Muscle", "Through the lot": "Muscle", "Iron": "The door", "Loud": "The door",
           "Double time": "Ordnance", "Ringing ears": "Drill", "Blast burns": "Drill"}


def main(out):
    lay = json.load(open(SRC, encoding="utf-8"))
    nodes, links = lay["nodes"], lay["links"]
    nodes, links, fams = w68_shape(nodes, links)      # (BUILD68-W) the web's shape: S's notables placed, the roads shortened, the fillers' families
    names = {}                                        # layout id -> name
    for j, (c, a, lt, rt) in enumerate(CLASSES):
        for p, nm in zip(PLACES, CNAMES[c]):
            names[f"c{j}:{p}"] = nm
        for p, nm in zip(["flush", "ground", "pot"], SKILLS[lt]):
            names[f"c{j}:{p}"] = nm
        for p, nm in zip(["collared", "gin", "decoy", "net"], SKILLS[rt]):
            names[f"c{j}:{p}"] = nm
        names[f"c{j}:s.0"] = STARTER[c]
        if c in FINDS_LESSER:
            names[f"c{j}:nightwork.0"] = FINDS_LESSER[c]
    for k, (e, a) in enumerate(ELEMS):
        for p, nm in zip(EPLACES, ENAMES[e]):
            names[f"e{k}:{p}"] = nm
        names[f"e{k}:pairL"], names[f"e{k}:pairR"] = EPAIRS[e]
    names.update(CENTRE)
    for sid, (nm, _cls, _th) in W68_PLACED.items():
        names[sid] = nm                               # (BUILD68-W) S's six notables, each on its class's road
    slots = []
    for sid, n in nodes.items():
        assert sid in names or n["kind"] == "small", ("a big place with no node", sid)
        nm = names.get(sid, "")
        base = sid.split(".")[0]
        reg, th = n["region"], n["theme"]
        s = {"slot": sid, "at": [round(n["at"][0], 1), round(n["at"][1], 1)], "kind": n["kind"], "tree": "", "name": nm, "pool": "", "track": "",
             "region": "", "theme": th}
        if reg == "centre":
            s["region"], s["tree"] = "centre", PITCH
            s["theme"] = "centre"
            if not nm:
                s["pool"] = RING_STAT[int(base[1]) % 3] if base[0] == "h" else RING_STAT[(len(slots)) % 3]     # a life / Guard / pace cluster's own; the roads and the outer ring in turn
        elif reg in dict(ELEMS):
            s["region"], s["tree"], s["theme"] = "el:" + reg, reg, "el"
            if not nm:
                s["track"] = "el"
        else:
            j = [c for c, *_ in CLASSES].index(reg)
            c, a, lt, rt = CLASSES[j]
            s["region"] = "class:" + c
            d = (math.cos(math.radians(a)), math.sin(math.radians(a)))
            left = d[0] * n["at"][1] - d[1] * n["at"][0] < 0                  # the class's left side: anticlockwise of its line
            s["tree"] = lt if left else rt
            if not nm:
                s["track"] = th if th in ("dmg", "ctl", "skill", "def", "loot") else ("dmg" if left else "ctl")
                if s["track"] == "dmg":
                    s["pool"] = "class:" + lt                                 # the attack track: the left tree's own smalls first
                elif s["track"] == "ctl":
                    s["pool"] = "class:" + rt                                 # the other track: the right tree's
        if sid in fams:
            s["fam"] = fams[sid]                      # (BUILD68-W) the filler's family: the notable its path leads to (data.gd FILLER_FAMILIES)
        if nm:
            s["tree"] = V1_TREE.get(nm, "")                                   # a named node stays in its own tree (data.gd finds it by name), or version one's
            if nm in EPAIRS.get(reg, []) or sid.endswith(":ratbait") or sid.endswith(":coldsnap"):
                s["pair"] = "left" if (sid.endswith("pairL") or sid.endswith(":ratbait")) else "right"
        slots.append(s)
    starts = {c: f"c{j}:start" for j, (c, *_) in enumerate(CLASSES)}
    # checks: every place named once, every node reachable from every start, every join between two nodes
    adj = {}
    for a, b in links:
        assert a in nodes and b in nodes, (a, b)
        adj.setdefault(a, set()).add(b); adj.setdefault(b, set()).add(a)
    for st in starts.values():
        seen = {st}; todo = [st]
        while todo:
            x = todo.pop()
            for y in adj.get(x, ()):
                if y not in seen: seen.add(y); todo.append(y)
        assert len(seen) == len(nodes), (st, len(seen), len(nodes))
    nl = [s["name"] for s in slots if s["name"]]
    assert len(nl) == len(set(nl)), [n for n in nl if nl.count(n) > 1]
    lines = ["## The skill web's layout, version two (docs/design/skill_web.md, 4 Nov). Generated by tools/make_skill_web.py from",
             "## docs/design/skill_web_layout.json - don't edit by hand. A slot: its place (web units, the centre at 0,0, y down), its",
             "## kind, its node's name (today's node, found by name, in its own tree or version one's) or for a lesser node the tree it goes in and its",
             "## pool (class:<tree> - that tree's own smalls in order; stat:hp / stat:guard / stat:pace - the centre's) and track",
             "## (dmg / ctl / skill / def / loot / el - data.gd TRACK_FILLERS once the pool's dry), its region, its theme (the track",
             "## the screen colours it by), a pair half's side, and (BUILD68-W) a filler's family - the notable its path leads to",
             "## (data.gd FILLER_FAMILIES). BUILD68-W reshaped the layout as it's read: S's six notables on roads, the roads shorter.",
             "class_name WebLayout", "", "const SLOTS := ["]
    for s in slots:
        lines.append("\t" + json.dumps(s, ensure_ascii=False) + ",")
    lines += ["]", "", "const LINKS := ["]
    for a, b in links:
        lines.append("\t[%s, %s]," % (json.dumps(a), json.dumps(b)))
    lines += ["]", "", "const STARTS := " + json.dumps(starts), ""]
    open(out, "w", encoding="utf-8").write("\n".join(lines))
    print(len(slots), "slots", len(links), "links", len(nl), "named")


# ------------------------------------------------------------------ BUILD68-W (8 Nov): the web's shape
# docs/design/endgame_rail.md section 3: "themed fillers by the notable each path leads to (3-4 kinds rotating), shorter
# paths, a check that no path repeats a node more than twice in a row". The agreed layout (round six) stays the source;
# this reshapes it as it's read: S's six new notables each take a road node on its class's track (a bare notable, as a
# keystone sits); every road (a run of lesser nodes outside the clusters' wheels) keeps half its nodes, rounded down -
# a one-node road goes, its two ends joined - the kept ones spaced evenly along the old line (the centre's roads half,
# rounded up: its spokes between the rings keep their node, or the centre would lose most of its life, Guard and pace); and every lesser node is
# given its family: the theme of the notable its path leads to (a wheel's its own hub; a road's the end further from
# its region's anchor - the class's start, or the centre).
W68_PLACED = {   # road slot -> (name, class, theme): builder S's notables (data.gd S68_NOTABLES), one a class
    "c0:p117": ("Between the eyes", "Poacher", "dmg"),         # the attack track, Rifleman to Clocked
    "c2:p117": ("Elbow grease", "Scrapper", "dmg"),            # the attack track, Bodger to Salvage
    "c5:p130": ("Covering fire", "Recruit", "ctl"),    # the Drill track, Cover me to By the numbers
    "c4:p130": ("Body count", "Doorman", "dmg"),               # the door's track, Chokepoints to Last orders
    "c3:p130": ("Ride your luck", "Drifter", "dmg"),           # the Luck track, Dead man's shoes to Spare change
    "c1:p139": ("Change of dressing", "Paramedic", "def"),     # up the middle, Double shift to Code blue
}
CENTRE_STAT = {"h0": "hp", "h3": "hp", "h1": "guard", "h4": "guard", "h2": "pace", "h5": "pace"}


def _ring(sid):
    return "." in sid.split(":")[-1]


def w68_shape(nodes, links):
    nodes = {k: dict(v) for k, v in nodes.items()}
    for sid, (nm, cls, th) in W68_PLACED.items():
        assert nodes[sid]["kind"] == "small" and nodes[sid]["region"] == cls, sid
        nodes[sid].update({"kind": "notable", "theme": th})
    adj = {k: set() for k in nodes}
    for a, b in links:
        adj[a].add(b); adj[b].add(a)
    road = lambda s: nodes[s]["kind"] == "small" and not _ring(s)
    # the roads: runs of two-link road nodes between their ends (a wheel, a big node, or a road node where roads meet)
    seen, chains = set(), []
    for s in nodes:
        if s in seen or not road(s) or len(adj[s]) != 2:
            continue
        seen.add(s)
        run = [s]
        ends = []
        for side in sorted(adj[s]):
            prev, cur, part = s, side, []
            while road(cur) and len(adj[cur]) == 2 and cur not in seen:
                seen.add(cur); part.append(cur)
                prev, cur = cur, [x for x in adj[cur] if x != prev][0]
            ends.append(cur)
            run = (part[::-1] + run) if not ends[1:] else (run + part)
        chains.append((ends[0], run, ends[1]))
    gone = set()
    for a, run, b in chains:
        assert a != b, ("a road that loops", run)
        keep = len(run) // 2 if any(nodes[x]["region"] != "centre" for x in run) else (len(run) + 1) // 2     # the centre's spokes keep their one node
        pts = [nodes[a]["at"]] + [nodes[x]["at"] for x in run] + [nodes[b]["at"]]
        seg = [math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1)]
        total = sum(seg)
        def along(f):                                  # the point a share f of the way along the old line
            d = f * total
            for i, ln in enumerate(seg):
                if d <= ln or i == len(seg) - 1:
                    u = d / ln if ln > 0 else 0.0
                    return [pts[i][0] + (pts[i + 1][0] - pts[i][0]) * u, pts[i][1] + (pts[i + 1][1] - pts[i][1]) * u]
                d -= ln
        kept = run[:keep]
        for i, x in enumerate(kept):
            nodes[x]["at"] = along((i + 1) / (keep + 1))
        for x in run[keep:]:
            gone.add(x)
        seq = [a] + kept + [b]
        for x in run:
            for y in list(adj[x]):
                adj[y].discard(x)
            adj[x] = set()
        for i in range(len(seq) - 1):
            if seq[i] != seq[i + 1]:
                adj[seq[i]].add(seq[i + 1]); adj[seq[i + 1]].add(seq[i])
    nodes = {k: v for k, v in nodes.items() if k not in gone}
    out = []
    for a, b in links:                                 # the layout's order where a join stands, then the new joins
        if a in nodes and b in nodes and b in adj[a] and [a, b] not in out and [b, a] not in out:
            out.append([a, b])
    for a in nodes:
        for b in sorted(adj[a]):
            if [a, b] not in out and [b, a] not in out:
                out.append([a, b])
    # the families: each lesser node's notable, by its path
    def dist_from(src):
        d, q = {src: 0}, [src]
        while q:
            nq = []
            for x in q:
                for y in adj[x]:
                    if y not in d:
                        d[y] = d[x] + 1; nq.append(y)
            q = nq
        return d
    anchor = {}
    for j, (c, *_r) in enumerate(CLASSES):
        anchor[c] = dist_from(f"c{j}:start")
    anchor["centre"] = dist_from("C")
    def hub(x):                                        # a wheel's member: its hub; a big node: itself
        if nodes[x]["kind"] != "small":
            return x
        if _ring(x):
            h = x.rsplit(".", 1)[0]
            return h if h in nodes else x.split(":")[0] + ":start"
        return None
    def fam_of(h, x):
        n = nodes[h]
        reg, th = n["region"], n["theme"]
        if th == "start":                              # the start's wheel: its own slot's track
            th, reg = nodes[x]["theme"], nodes[x]["region"]
        if reg == "centre":
            return "centre:" + CENTRE_STAT.get(h, "mix")
        if reg in dict(ELEMS):
            return "el:" + reg
        return {"dmg": "atk:", "ctl": "oth:"}.get(th, th + ":") + reg if th in ("dmg", "ctl") else th
    fams = {}
    for x in nodes:
        if nodes[x]["kind"] != "small":
            continue
        if _ring(x):
            fams[x] = fam_of(hub(x), x)
            continue
        reach, todo, ends = {x}, [x], set()        # a road node: the ends of its road (through other road nodes)
        while todo:
            y = todo.pop()
            for z in adj[y]:
                if z in reach:
                    continue
                if road(z):
                    reach.add(z); todo.append(z)
                else:
                    ends.add(hub(z))
        reg = nodes[x]["region"]
        dd = anchor[reg] if reg in anchor else anchor["centre"]
        lead = max(sorted(ends), key=lambda h: dd.get(h, 0))
        fams[x] = fam_of(lead, x)
    return nodes, out, fams


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "scripts/sim/web_layout.gd")

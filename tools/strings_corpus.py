"""Every player-facing string in the game, by screen, for the language pass (18 Oct, Matt: "a language and general
UI pass ... a caps pass across the game"). Read-only: it reads scripts/ and writes docs/language/strings.md (to read)
and docs/language/strings.tsv (for the reviewers). Run from the project folder: python tools/strings_corpus.py

What counts as player-facing is a guess from the source, not the running game: a string literal that is not a
dictionary key, not an identifier (stat names, node names, paths), not inside print/assert/push_error, and not a
font weight or theme name. A data field known to be internal ("stat", "effect", "type" ...) is left out; a field known
to be read ("name", "words", "short" ...) is kept even when it is one lower-case word. Noise is cheaper than a miss.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "language")

# Where each file shows: the screen a reader would call it.
SCREENS = {
    "words.gd": "Shared words (radio, reports, chronicle, intros)",
    "data.gd": "Game data (items, perks, rooms, sites)",
    "items.gd": "Item names and tooltips",
    "sim.gd": "Run reports, events and messages",
    "main.gd": "Camp shell (top row, rail, toasts)",
    "missions.gd": "Map",
    "run.gd": "Run screen (fight)",
    "run_view.gd": "Run screen (fight)",
    "barracks.gd": "Barracks (character, perks)",
    "vendor.gd": "Fence (vendor)",
    "workshop.gd": "Workshop",
    "radio.gd": "Radio",
    "radio_line.gd": "Radio",
    "stats_room.gd": "Stats",
    "came_back.gd": "Came back (run report)",
    "armoury.gd": "Armoury",
    "atlas.gd": "Atlas",
    "inventory.gd": "Inventory",
    "containers.gd": "Inventory",
    "item_head.gd": "Item tooltip",
    "item_cell.gd": "Item tooltip",
    "yard_town.gd": "Yard",
    "yard_tree.gd": "Yard",
    "yard_works.gd": "Yard",
    "people.gd": "People (crew)",
    "intro.gd": "Intro",
    "opening.gd": "Opening",
    "room_intro.gd": "Room intros",
    "menu.gd": "Menu",
    "tier_guide.gd": "Tier guide",
    "crates_panel.gd": "Crates",
    "event_panel.gd": "Run screen (fight)",
    "event_prop.gd": "Run screen (fight)",
    "orders_panel.gd": "Armoury",
    "rules_panel.gd": "Armoury",
    "pick_panel.gd": "Pick panel",
    "mythic_moment.gd": "Mythic moment",
    "fight_slots.gd": "Fight slots",
    "fight_placement.gd": "Fight slots",
    "chips.gd": "Chips",
    "band.gd": "Chips",
    "card.gd": "Cards",
    "fmt.gd": "Number formats",
}

SKIP_FILES = {"palette.gd", "ui.gd", "sound.gd", "juice.gd", "node_glyphs.gd", "sketch.gd", "body.gd", "rail_button.gd"}
INTERNAL_FIELDS = {"stat", "effect", "type", "id", "key", "mount", "rule", "learn", "joint", "band", "kind", "tree",
                   "element_tree", "element", "res", "shape", "from", "art", "icon", "slug", "sfx", "zone_type",
                   "salvage", "ammo", "pay", "slot", "base", "class2", "unlock", "gate", "need", "room", "on", "pool", "site_type", "tone"}
READ_FIELDS = {"name", "words", "short", "sentence", "sum", "paper", "label", "title", "line", "lines", "flavour",
               "blurb", "say", "said", "text", "head", "kicker", "hint", "desc", "what", "why", "verb", "noun"}
NOT_WORDS = {"Regular", "Medium", "SemiBold", "Bold", "normal", "hover", "pressed", "focus", "disabled", "panel",
             "font_color", "font_hover_color", "font_pressed_color", "font_size", "font", "pressed", "true", "false"}
IDENT = re.compile(r"^[a-z0-9_./:#%-]*$")
TRIVIAL = re.compile(r"^[\W\d_%sdf.+\-x·:/ ]*$")
DEBUG_CALL = re.compile(r"\b(print|prints|printerr|push_error|push_warning|assert|_check|_fail|check)\s*\(")
UI_CALL = re.compile(r"(UI\.\w+|\.text\s*=|tooltip_text|\bLabel\b|\bButton\b|_label|_title|_chip|_tile|_line|_say|_toast|headline)")
RECT = re.compile(r"Rect2\(([^()]*)\)")


def strings_in(line):
    """The string literals on a line (start, end, text), and where its comment starts."""
    out = []
    i = 0
    n = len(line)
    while i < n:
        c = line[i]
        if c == "#":
            return out, i
        if c in "\"'":
            if line.startswith(c * 3, i):
                return out, n          # a triple string (shader code): never player text here
            q = c
            j = i + 1
            buf = []
            while j < n and line[j] != q:
                if line[j] == "\\" and j + 1 < n:
                    buf.append({"n": "\n", "t": "\t", "\"": "\"", "'": "'", "\\": "\\"}.get(line[j + 1], line[j + 1]))
                    j += 2
                    continue
                buf.append(line[j])
                j += 1
            prefix = line[i - 1] if i > 0 else ""
            out.append((i, j + 1, "".join(buf), prefix))
            i = j + 1
            continue
        i += 1
    return out, n


def field_of(line, start):
    """The dictionary key a value sits under: "name": "The Bank" -> name."""
    m = re.search(r"\"(\w+)\"\s*:\s*$", line[:start])
    return m.group(1) if m else ""


def keep(text, line, s, e, field, prefix):
    after = line[e:].lstrip()
    before = line[:s].rstrip()
    if after.startswith(":") and not before.endswith("?"):
        return False                                   # a dictionary key
    if prefix in "&^$@":
        return False                                   # StringName / NodePath literals
    if field in INTERNAL_FIELDS:
        return False
    if not re.search(r"[A-Za-z]", text) or text in NOT_WORDS or TRIVIAL.match(text):
        return False
    if text.startswith(("res://", "user://", "ui_")):
        return False
    if field in READ_FIELDS:
        return True
    if IDENT.match(text):
        return False                                   # an identifier, a path, a format with no words
    if re.search(r"(==|!=|\bin|\bmatch|\bhas|\bget|\bfind|\bbegins_with|\bends_with)\s*\(?\s*$", before):
        if " " not in text:
            return False                               # compared, looked up: a key, not shown
    if before.endswith("[") and after.startswith("]") and " " not in text:
        return False                                   # an index: d["Primary"]
    if re.match(r"^[A-Z][a-z]+$", text) and re.search(r"(==|!=)\s*$", before):
        return False
    return True


def room_of(line):
    m = RECT.search(line)
    if not m:
        return ""
    parts = [p.strip() for p in m.group(1).split(",")]
    if len(parts) == 4:
        return "w=%s h=%s" % (parts[2], parts[3])
    return ""


def scan(path, rel):
    rows = []
    owner = ""          # the const or func the line sits in
    entry = ""          # the nearest "name" in a data entry, so a perk's words say whose they are
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    for ln, line in enumerate(lines, 1):
        m = re.match(r"^(?:static\s+)?func\s+(\w+)", line) or re.match(r"^const\s+(\w+)", line) or re.match(r"^var\s+(\w+)", line)
        if m:
            owner = m.group(1)
            entry = ""
        stripped = line.lstrip()
        if stripped.startswith("#"):
            continue
        found, _ = strings_in(line)
        code = line
        if DEBUG_CALL.search(code.split("#")[0]) and not UI_CALL.search(code):
            continue
        for s, e, text, prefix in found:
            field = field_of(line, s)
            if field == "name":
                entry = text
            if not keep(text, line, s, e, field, prefix):
                continue
            rows.append({
                "screen": SCREENS.get(os.path.basename(rel), "Other: " + os.path.basename(rel)),
                "file": rel,
                "line": ln,
                "owner": owner,
                "entry": entry if field != "name" else "",
                "field": field,
                "room": room_of(line),
                "chars": len(text),
                "text": text,
            })
    return rows


def main():
    rows = []
    for sub in ("scripts/sim", "scripts/ui"):
        d = os.path.join(ROOT, sub)
        for name in sorted(os.listdir(d)):
            if not name.endswith(".gd") or name in SKIP_FILES:
                continue
            rows += scan(os.path.join(d, name), sub + "/" + name)
    seen = {}
    kept = []
    for r in rows:                                     # the same words in the same place once, with a count
        k = (r["file"], r["owner"], r["field"], r["text"])
        if k in seen:
            seen[k]["times"] += 1
            continue
        r["times"] = 1
        seen[k] = r
        kept.append(r)
    rows = kept
    os.makedirs(OUT, exist_ok=True)
    order = list(dict.fromkeys(SCREENS.values()))
    rows.sort(key=lambda r: (order.index(r["screen"]) if r["screen"] in order else 99, r["file"], r["line"]))
    with open(os.path.join(OUT, "strings.tsv"), "w", encoding="utf-8", newline="\n") as f:
        f.write("id\tscreen\tfile\tline\towner\tentry\tfield\troom\tchars\ttext\n")
        for i, r in enumerate(rows, 1):
            r["id"] = "S%04d" % i
            t = r["text"].replace("\t", "\\t").replace("\n", "\\n")
            f.write("\t".join([r["id"], r["screen"], r["file"], str(r["line"]), r["owner"], r["entry"], r["field"],
                               r["room"], str(r["chars"]), t]) + "\n")
    with open(os.path.join(OUT, "strings.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("# Every player-facing string\n\nMade by tools/strings_corpus.py from the source; do not edit by hand. "
                "%d strings. Room is the label's box where the source gives it (w, h in px).\n" % len(rows))
        screen = None
        owner = None
        for r in rows:
            if r["screen"] != screen:
                screen = r["screen"]
                owner = None
                f.write("\n## %s\n" % screen)
            if (r["file"], r["owner"]) != owner:
                owner = (r["file"], r["owner"])
                f.write("\n**%s** · %s\n\n" % (r["owner"] or "(top)", r["file"]))
            bits = [r["id"], "L%d" % r["line"]]
            if r["entry"]:
                bits.append(r["entry"])
            if r["field"]:
                bits.append(r["field"])
            if r["room"]:
                bits.append(r["room"])
            if r["times"] > 1:
                bits.append("x%d" % r["times"])
            t = r["text"].replace("\n", "⏎").replace("|", "\\|")
            f.write("- `%s` %s\n" % (" ".join(bits), t))
    counts = {}
    for r in rows:
        counts[r["screen"]] = counts.get(r["screen"], 0) + 1
    for k, v in sorted(counts.items(), key=lambda kv: -kv[1]):
        print("%5d  %s" % (v, k))
    print("%5d  total" % len(rows))


if __name__ == "__main__":
    sys.exit(main())

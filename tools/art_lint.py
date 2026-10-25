"""The art manifests' lint (25 Oct, the tools review item 14): run before any manifest goes to Matt.

  python3 tools/art_lint.py                       every tools/pixellab_*manifest.json
  python3 tools/art_lint.py tools/pixellab_x.json  just those (seeds are still checked against every manifest)

Checks, each a row in the table:
  seed      no two different outputs share a seed, across every manifest (the lessons: no two jobs share a seed).
            The same output on the same seed in two manifests (a test and its set) is one job, not a clash.
  size      width x height within the API's cap: about 512x512's worth (262,144 px; make_fight_kit_manifest.py's
            note - pixellab_batch_v2.gd sends the size as given and holds no cap of its own); the 1-direction object
            at 16-256 px square; an animate job's first frame at 256 px or under.
  ref       every style_image, reference_images, style_images and first_frame file is on disk (res:// is the repo root).
  ui        no output under art/ui/: Matt's painted UI art is never written over (art/ui_new/ is where new icons go).
  out       no output twice in one manifest; across manifests, the same output only as the same job (same seed and
            words: a test and its set), never two different jobs writing one file.

Exit 1 on any problem, 0 when clean. Python 3 stdlib only."""
import glob
import json
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AREA_CAP = 512 * 512
OBJECT_MIN, OBJECT_MAX = 16, 256
FRAME_MAX = 256


def rel(path):
    return os.path.relpath(path, ROOT).replace(os.sep, "/")


def disk(res):
    """A res:// (or repo-relative) path's file on disk."""
    p = str(res)
    if p.startswith("res://"):
        p = p[len("res://"):]
    return os.path.join(ROOT, *p.split("/"))


def png_size(path):
    try:
        with open(path, "rb") as f:
            head = f.read(24)
        if head[:8] == b"\x89PNG\r\n\x1a\n":
            return struct.unpack(">II", head[16:24])
    except OSError:
        pass
    return None


def load(path):
    try:
        with open(path, encoding="utf-8") as f:
            m = json.load(f)
    except (OSError, ValueError) as e:
        return None, "unreadable: %s" % e
    if not isinstance(m, dict) or not isinstance(m.get("jobs"), list):
        return None, "not a JSON object with a 'jobs' array"
    return m["jobs"], None


def main(argv):
    every = sorted(glob.glob(os.path.join(ROOT, "tools", "pixellab_*manifest.json")))
    if argv:
        chosen = []
        for a in argv:     # a path (from here or the repo root) or a bare name in tools/
            a = disk(a) if a.startswith("res://") else a
            tries = [a, os.path.join(ROOT, a), os.path.join(ROOT, "tools", a)]
            p = next((t for t in tries if os.path.isfile(t)), a)
            chosen.append(os.path.abspath(p))
    else:
        chosen = [os.path.abspath(p) for p in every]
    scope = set(chosen)
    problems = []      # (check, manifest, output, detail)

    def bad(check, man, out, detail):
        problems.append((check, rel(man), out, detail))

    # Every manifest is read (the seeds are global); the per-job checks run on the chosen ones.
    jobs_of = {}
    for path in sorted(set(every) | scope):
        jobs, err = load(path)
        if err:
            if path in scope:
                bad("read", path, "-", err)
            continue
        jobs_of[path] = jobs

    by_seed = {}       # seed -> {out: [(manifest, words)]}
    by_out = {}        # out -> [(manifest, seed, words)]
    n_jobs = 0
    for path, jobs in jobs_of.items():
        seen_here = set()
        for i, j in enumerate(jobs):
            if not isinstance(j, dict):
                if path in scope:
                    bad("read", path, "job %d" % i, "not an object")
                continue
            out = str(j.get("out", "")).strip()
            words = j.get("description", "")
            seed = j.get("seed")
            if seed is not None:
                by_seed.setdefault(int(seed), {}).setdefault(out, []).append(path)
            by_out.setdefault(out, []).append((path, seed, words))
            if path not in scope:
                continue
            n_jobs += 1
            label = out or "job %d" % i
            if not out:
                bad("out", path, label, "no 'out'")
            elif out in seen_here:
                bad("out", path, out, "written twice in this manifest")
            seen_here.add(out)
            norm = out.replace("\\", "/").lstrip("./")
            if norm.startswith("res://"):
                norm = norm[len("res://"):]
            if norm.startswith("art/ui/"):
                bad("ui", path, out, "under art/ui/ - Matt's painted UI art is never overwritten (use art/ui_new/)")
            endpoint = j.get("endpoint", "generate-image-v2")
            w, h = j.get("width"), j.get("height")
            if endpoint == "create-1-direction-object":
                if not j.get("style_images") and not (OBJECT_MIN <= int(w or 64) <= OBJECT_MAX):
                    bad("size", path, out, "object size %s outside %d-%d" % (w, OBJECT_MIN, OBJECT_MAX))
            elif endpoint != "animate-with-text-v3":
                w, h = int(w or 64), int(h or 64)
                if w * h > AREA_CAP:
                    bad("size", path, out, "%dx%d = %d px, over the cap of %d" % (w, h, w * h, AREA_CAP))
            refs = []
            if j.get("style_image"):
                refs.append(("style_image", j["style_image"]))
            refs += [("reference_images", r) for r in (j.get("reference_images") or [])]
            refs += [("style_images", r) for r in (j.get("style_images") or [])]
            if j.get("first_frame"):
                refs.append(("first_frame", j["first_frame"]))
            for field, r in refs:
                f = disk(r)
                if not os.path.isfile(f):
                    bad("ref", path, out, "%s not on disk: %s" % (field, r))
                elif field == "first_frame":
                    size = png_size(f)
                    if size and max(size) > FRAME_MAX:
                        bad("size", path, out, "first frame %dx%d, over %d px" % (size[0], size[1], FRAME_MAX))

    collisions = 0
    for seed, outs in sorted(by_seed.items()):
        if len(outs) < 2:
            continue
        if not any(p in scope for ps in outs.values() for p in ps):
            continue
        collisions += 1
        names = sorted(outs)
        where = "; ".join("%s (%s)" % (o, ", ".join(sorted({rel(p).replace("tools/", "") for p in outs[o]}))) for o in names)
        first = next(p for ps in outs.values() for p in ps if p in scope)
        bad("seed", first, names[0], "seed %d shared by %d outputs: %s" % (seed, len(names), where))

    for out, uses in sorted(by_out.items()):
        mans = {p for p, _s, _w in uses}
        if len(mans) < 2 or not (mans & scope):
            continue
        jobs = {(s, w) for _p, s, w in uses}
        if len(jobs) > 1:
            seeds = sorted({str(s) for _p, s, _w in uses})
            bad("out", next(p for p in sorted(mans) if p in scope), out,
                "written by %d different jobs in %s (seeds %s)" % (len(jobs), ", ".join(sorted(rel(p).replace("tools/", "") for p in mans)), ", ".join(seeds)))

    # The table.
    print("art_lint: %d manifest(s), %d job(s) checked (seeds against all %d manifests)" % (len(scope), n_jobs, len(jobs_of)))
    if not problems:
        print("CLEAN: no problems.")
        return 0
    cw = max(5, max(len(p[0]) for p in problems))
    mw = min(48, max(8, max(len(p[1]) for p in problems)))
    ow = min(56, max(6, max(len(p[2]) for p in problems)))
    print("%-*s  %-*s  %-*s  %s" % (cw, "CHECK", mw, "MANIFEST", ow, "OUTPUT", "PROBLEM"))
    print("%s  %s  %s  %s" % ("-" * cw, "-" * mw, "-" * ow, "-" * 7))
    order = {"read": 0, "ui": 1, "ref": 2, "size": 3, "out": 4, "seed": 5}
    for check, man, out, detail in sorted(problems, key=lambda p: (order.get(p[0], 9), p[1], p[2])):
        print("%-*s  %-*s  %-*s  %s" % (cw, check, mw, man.replace("tools/", ""), ow, out, detail))
    counts = {}
    for p in problems:
        counts[p[0]] = counts.get(p[0], 0) + 1
    print()
    print("PROBLEMS: %d (%s); %d seed(s) shared between different outputs." % (
        len(problems), ", ".join("%s %d" % (k, counts[k]) for k in sorted(counts, key=lambda k: order.get(k, 9))), collisions))
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

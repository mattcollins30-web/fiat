"""The sounds' peak levels (21 Oct, Matt's playtest: rifle shots inaudible - the takes peaked at -29 to -33 dB against
the shotgun's 0). Lists every take in art/sound_new by peak; with --fix, lifts the fight's one-shots (shot_, swing_,
incoming, dry_click) that peak under FLOOR up to TARGET, re-encoded in place at 128k. Needs ffmpeg on the path."""
import os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "art", "sound_new")
FIGHT = ("shot_", "swing_", "incoming", "dry_click")
FLOOR = -6.0
TARGET = -1.0


def peak(path):
    out = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af", "volumedetect", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    m = re.search(r"max_volume: ([-0-9.]+) dB", out)
    return float(m.group(1)) if m else None


def main():
    fix = "--fix" in sys.argv
    rows = []
    for nm in sorted(os.listdir(DIR)):
        if not nm.endswith(".mp3"):
            continue
        p = peak(os.path.join(DIR, nm))
        rows.append((p, nm))
    rows.sort(key=lambda r: (r[0] is None, r[0] or 0.0))
    low = []
    for p, nm in rows:
        print(("%6.1f  %s" % (p, nm)) if p is not None else ("   -    %s (ffmpeg read no level)" % nm))
        if nm.startswith(FIGHT) and p is not None and p < FLOOR:
            low.append((p, nm))
    if not low:
        print("every fight one-shot peaks at %.0f dB or over" % FLOOR)
        return 0
    print("under the floor (%.0f dB): %s" % (FLOOR, ", ".join(nm for _, nm in low)))
    if not fix:
        return 1
    for p, nm in low:
        src = os.path.join(DIR, nm)
        tmp = src + ".tmp.mp3"
        gain = TARGET - p
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", src, "-af", "volume=%.1fdB" % gain,
                        "-b:a", "128k", tmp], check=True)
        os.replace(tmp, src)
        print("lifted %s by %.1f dB to %.1f" % (nm, gain, peak(src)))
    return 0


if __name__ == "__main__":
    sys.exit(main())

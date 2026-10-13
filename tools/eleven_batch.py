"""Runs tools/sound_manifest.json through ElevenLabs' sound-effects API (POST /v1/sound-generation) on Matt's machine.
The key is read from tools/elevenlabs_secret.txt (one line; gitignored) - never printed, never written anywhere else.
Writes art/sound_new/<id>.mp3 and skips what's there. Standard library only.

  python tools/eleven_batch.py              all of it
  python tools/eleven_batch.py --dry-run    the list and the seconds, nothing sent
  python tools/eleven_batch.py --only shot_pistol --only kill   one sound (all its takes) or one take (shot_pistol_2)
  python tools/eleven_batch.py --force      remake even if the file's there (with --only, usually)"""
import json, os, sys, time, urllib.request, urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "sound_manifest.json")
SECRET = os.path.join(ROOT, "tools", "elevenlabs_secret.txt")
OUT = os.path.join(ROOT, "art", "sound_new")
URL = "https://api.elevenlabs.io/v1/sound-generation?output_format=%s"


def main(argv):
    dry = "--dry-run" in argv
    force = "--force" in argv
    only = [argv[i + 1] for i, a in enumerate(argv) if a == "--only" and i + 1 < len(argv)]
    m = json.load(open(MANIFEST, encoding="utf-8"))
    jobs = [j for j in m["jobs"] if not only or j["id"] in only or j["sound"] in only]
    os.makedirs(OUT, exist_ok=True)
    todo = [j for j in jobs if force or not os.path.exists(os.path.join(OUT, j["id"] + ".mp3"))]
    print("%d jobs, %d to make (%.0f s of sound), %d already on disk" % (len(jobs), len(todo), sum(j["duration_seconds"] for j in todo), len(jobs) - len(todo)))
    if dry:
        for j in todo:
            print("  %-22s %5.1f s%s  %s" % (j["id"], j["duration_seconds"], " loop" if j["loop"] else "     ", j["text"][:70]))
        return 0
    if not os.path.exists(SECRET):
        print("No key: put your ElevenLabs API key on one line in tools/elevenlabs_secret.txt")
        return 1
    key = open(SECRET, encoding="utf-8").read().strip()
    made, failed = 0, []
    for n, j in enumerate(todo):
        body = {"text": j["text"], "duration_seconds": j["duration_seconds"], "prompt_influence": j["prompt_influence"],
                "model_id": m.get("model_id", "eleven_text_to_sound_v2")}
        if j["loop"]:
            body["loop"] = True
        req = urllib.request.Request(URL % m.get("output_format", "mp3_44100_128"), data=json.dumps(body).encode("utf-8"),
                                     headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"}, method="POST")
        for attempt in range(3):
            try:
                with urllib.request.urlopen(req, timeout=120) as r:
                    data = r.read()
                open(os.path.join(OUT, j["id"] + ".mp3"), "wb").write(data)
                made += 1
                print("[%d/%d] %s  %d KB" % (n + 1, len(todo), j["id"], len(data) // 1024))
                break
            except urllib.error.HTTPError as e:
                msg = e.read().decode("utf-8", "replace")[:300]
                if e.code == 429 and attempt < 2:
                    print("  busy (429), waiting 10 s"); time.sleep(10); continue
                print("[%d/%d] %s  FAILED %d: %s" % (n + 1, len(todo), j["id"], e.code, msg))
                if e.code in (401, 403):
                    print("The key was refused: check it's in tools/elevenlabs_secret.txt and has Sound Effects access.")
                    return 1
                failed.append(j["id"]); break
            except Exception as e:
                if attempt < 2:
                    time.sleep(3); continue
                print("[%d/%d] %s  FAILED: %s" % (n + 1, len(todo), j["id"], e)); failed.append(j["id"])
    print("Done: %d made, %d failed%s" % (made, len(failed), (": " + " ".join(failed)) if failed else ""))
    return 0 if not failed else 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

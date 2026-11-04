#!/bin/bash
# canvas_look.sh <project dir> <Board> <w> <h> : renders one design-canvas board (<project dir>/<Board>.dc.html, its
# pictures beside it as ./x.png) in the real canvas viewer (the frame emulator) and prints a screenshot's path - the
# fit check every mockup gets before Matt sees it (22 Oct). Needs the frame emulator (/opt/frame-emulator) and a Design
# artifact's type files read once into $S/artifact-files/<id> (set SHELL_ROOT to that folder).
. "$(dirname "$0")/env.sh"
P=$1; b=$2; C=$S/chk_$b
rm -rf $C; mkdir -p $C/project; cp $P/$b.dc.html $C/project/; cp $P/*.png $C/project/ 2>/dev/null
python3 -c "import json,sys;b,w,h=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]);json.dump({'v':3,'title':'chk','launch':{'view':'focused','file':b+'.dc.html'},'pages':[],'boards':{b+'.dc.html':{'x':0,'y':0,'w':w,'h':h}},'order':[b+'.dc.html'],'notes':{},'designSystems':[]},open(sys.argv[4],'w'))" $b $3 $4 $C/project/canvas.json
chmod -R a+rX $C
SHELL_DIR=$(ls -d /opt/frame-emulator/cache/shell/*/* | head -1); RUNTIME_DIR=$(ls -d /opt/frame-emulator/cache/runtime-* | head -1)
/usr/bin/python3 -I - "$C" "$3" "$4" "$SHELL_ROOT" "$SHELL_DIR" "$RUNTIME_DIR" <<'PY'
import json, os, subprocess, tempfile, sys
C,w,h,root,shell,rt=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),sys.argv[4],sys.argv[5],sys.argv[6]
from playwright.sync_api import sync_playwright
os.environ.setdefault("NO_PROXY", "127.0.0.1,localhost"); os.environ.pop("NODE_OPTIONS", None)
out = tempfile.mkdtemp(prefix="look-", dir="/opt/frame-emulator/run")
serve = subprocess.Popen(["/usr/local/bin/frame-emulator", "serve", root, "--shell-dir", shell, "--runtime-dir", rt, "--contract", "0.2.47", "--caps-from-meta", "--project", C+"/project"], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
try:
    ready = json.loads(serve.stdout.readline())
    with sync_playwright() as pw:
        page = pw.chromium.connect_over_cdp(ready["cdp"]).contexts[0].new_page()
        page.set_viewport_size({"width": w + 200, "height": h + 260})
        page.goto(ready["shellUrl"]); page.wait_for_timeout(7000)
        page.screenshot(path=out + "/look.png"); print(out + "/look.png")
finally:
    serve.terminate(); serve.wait(timeout=10)
PY

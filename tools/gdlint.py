"""The GDScript warnings check (14 Oct, Matt: "a way of checking in the future and clearing before commits").

The editor shows warnings in its Debugger when the game runs; a headless run (the smoke) prints none. This asks the
editor's language server instead: it starts Godot headless as an editor with the server on, opens every .gd in the
project (docs/, .godot/ and addons/ left out), and prints each warning or error as file:line: CODE message, then a
total. Run before every commit; the total should be 0.

usage: python3 tools/gdlint.py <godot executable> <project dir> [port]
Fixing one: a whole-number division that's meant gets @warning_ignore("integer_division") on the line before its
statement; a local that shadows a property or function is renamed; an unused parameter gets a leading underscore."""
import json, os, socket, subprocess, sys, time, glob
godot, proj = sys.argv[1], os.path.abspath(sys.argv[2])
port = int(sys.argv[3]) if len(sys.argv) > 3 else 6011
p = subprocess.Popen([godot, "--headless", "--editor", "--path", proj, "--lsp-port", str(port)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
s = None
for _ in range(120):
    try:
        s = socket.create_connection(("127.0.0.1", port), timeout=2); break
    except OSError:
        time.sleep(1)
if s is None:
    p.kill(); sys.exit("no language server")
s.settimeout(0.5)
buf = b""
def send(obj):
    body = json.dumps(obj).encode()
    s.sendall(b"Content-Length: %d\r\n\r\n" % len(body) + body)
def read_all(wait):
    global buf
    out = []; end = time.time() + wait
    while time.time() < end:
        try:
            chunk = s.recv(65536)
            if chunk: buf += chunk
        except socket.timeout:
            pass
        while b"\r\n\r\n" in buf:
            head, rest = buf.split(b"\r\n\r\n", 1)
            n = int([l for l in head.split(b"\r\n") if l.lower().startswith(b"content-length")][0].split(b":")[1])
            if len(rest) < n: break
            out.append(json.loads(rest[:n])); buf = rest[n:]
    return out
uri = lambda f: "file://" + f
send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"processId": None, "rootUri": uri(proj), "capabilities": {}}})
read_all(3)
send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
files = sorted(f for f in glob.glob(proj + "/**/*.gd", recursive=True) if "/.godot/" not in f and "/docs/" not in f and "/addons/" not in f)
diags = {}
for f in files:
    send({"jsonrpc": "2.0", "method": "textDocument/didOpen", "params": {"textDocument": {"uri": uri(f), "languageId": "gdscript", "version": 1, "text": open(f, encoding="utf-8").read()}}})
    for m in read_all(1.5):
        if m.get("method") == "textDocument/publishDiagnostics":
            diags[m["params"]["uri"]] = m["params"]["diagnostics"]
for m in read_all(4):
    if m.get("method") == "textDocument/publishDiagnostics":
        diags[m["params"]["uri"]] = m["params"]["diagnostics"]
p.kill()
total = 0
for u in sorted(diags):
    for d in diags[u]:
        total += 1
        rel = u.replace(uri(proj) + "/", "")
        print("%s:%d: %s %s" % (rel, d["range"]["start"]["line"] + 1, d.get("code", ""), d["message"]))
print("TOTAL %d in %d files of %d" % (total, sum(1 for u in diags if diags[u]), len(files)))

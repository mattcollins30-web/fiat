# The Steam Deck (and the window), so it is not chased again

Written 8 Oct 2026 after four cuts. Greenhorn hit the same thing first; its notes are in
`greenhorn/scripts/autoload/game_manager.gd` (`_apply_native_window_size`). Fiat's fix is
`main._fit_window_to_screen`, run first in `_ready`.

## The symptom

In **game mode** on the Deck (gamescope, no window manager) the lower part of the screen takes no
clicks — the rail from the Fence down, the low cards — while everything renders fine. **Desktop mode**
on the same Deck is fine, because a window manager fits the window itself. Controls set to mouse only.

## The mechanism

gamescope places the window at the pixel size it asks for, scales it to the 1280 × 800 panel, and
reports the pointer back in panel pixels, which the engine's content-scale transform reads as if they
were already window coordinates. The error is zero at the origin and grows down the screen.

## The fix

On Linux only, at boot: set the window **windowed**, then `window.size =
DisplayServer.screen_get_size(window.current_screen)` and `window.position` at the screen's origin,
and let the stretch (`canvas_items`, `expand`) do the scaling as it would on any 16:10 monitor. The
canvas becomes 1920 × 1200; the rail runs to the log's bottom as designed.

## The traps (each one cost a cut)

1. **A gate.** "Only if the window is bigger than the screen" never fires: gamescope never reports
   that. Do it unconditionally on Linux.
2. **A maximized window.** `project.godot` had `window/size/mode=2`. That defeats the fix twice: the
   X11 display server ignores a resize of a maximized window, and gamescope follows the window's
   requested mode and sets its own screen to 1920 × 1080, so `screen_get_size` equals the window and
   there is nothing smaller to size to — the foot read "1920×1080 → 1920×1080". It is now
   `window/size/mode.windows=2`, a feature override: Windows opens maximized, Linux opens windowed, as
   Greenhorn's does. Any project going to the Deck should open windowed on Linux.
3. **Windows.** Never change window geometry or mode from script on an exported Windows build under
   GL Compatibility: Greenhorn isolated a hard segfault over ten export cycles (`Window.size`,
   `DisplayServer.window_set_size` and a pure mode switch all crash). Windows never has the Deck bug.
   Gate on `OS.get_name() == "Linux"`.
4. **Guessing.** The thing that settled it was a line on the title's foot — the window and the canvas
   as the game sees them, "1280×800 → 1920×1200" when right. Read it from the Deck in game mode before
   theorising. It stays (`menu.gd`, the foot's right label).

## Testing

`tests/deck.gd` under a 1280 × 800 X screen (`xvfb-run -s "-screen 0 1280x800x24" godot --path . -s
tests/deck.gd`) proves the sizing path and that every rail row ends inside the window; it needs a
display, so it is not in the headless smoke, and it cannot imitate gamescope — the Deck is the proof.

## The pck

A Linux export that wants the `.pck` beside the binary has Embed PCK off
(`binary_format/embed_pck=false` in `export_presets.cfg`, untracked). Greenhorn's presets have it on,
which is why Greenhorn runs as one file. Tick it in the editor's export dialog.

## Art in a pack

`Image.load_from_file(ProjectSettings.globalize_path("res://..."))` finds nothing inside a `.pck`:
the wordmark was missing on the Deck's builds (desktop and game mode) while the editor run had it.
Read a file's bytes through `FileAccess.get_file_as_bytes` (which reads from a pack) and
`Image.load_png_from_buffer`, then fall back to `load()` for the imported resource. `menu._load_art`.

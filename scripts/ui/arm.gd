extends RefCounted
## One ask-twice press (25 Oct, the second review: the Fence's arm outlived the room and sold what it hadn't shown).
## The first press arms a key; a second press on the same key acts only while it holds: within WINDOW_S, and with the
## same `what` (a fingerprint of what the press would act on - a count, the picked node). Another key, a changed
## `what`, the window running out, or the room hidden (`clear`) disarms it. Every ask-twice button uses one.

const WINDOW_S := 8.0

var key = null
var what := ""
var _at := 0


## A press on `k`: true when it acts (armed on `k` and `fp` still holds), false when it only arms.
func press(k, fp := "") -> bool:
	if holds(k, fp):
		key = null
		return true
	key = k
	what = fp
	_at = Time.get_ticks_msec()
	return false


## Armed on `k` for `fp`, inside the window: the button shows its second form.
func holds(k, fp := "") -> bool:
	return key != null and key == k and what == fp and Time.get_ticks_msec() - _at <= int(WINDOW_S * 1000.0)


func clear() -> void:
	key = null


## For a room's redraw signature: changes when the arm is set, used, cleared or runs out.
func sig() -> String:
	if key == null or Time.get_ticks_msec() - _at > int(WINDOW_S * 1000.0):
		return ""
	return "%s|%s" % [str(key), what]

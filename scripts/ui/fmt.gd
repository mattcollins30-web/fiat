extends RefCounted
## Turning the sim's numbers into text. Formatting only - no economics.
##
## The generic half of Pithole's: money, counts, times. The house game's own units
## (bricks, homes, square metres) come with its sim.

const MINUS := "−"
const UNIT := "tins"                # what everything is paid in (13 Oct, Matt: a game about a collapse, paid in cash, made no sense)
## The glyphs a name not yet known is scrambled into (20 Oct, Matt: "scrambled like the radio broadcasts"): ItemHead's,
## all in Inter.
## A name not yet known (Words.scramble: the sim's too, 20 Oct, the review: the sim never loads a UI script).
static func scramble(text: String) -> String:
	return preload("res://scripts/sim/words.gd").scramble(text)


## A plain quantity: 1,234 · 12,345 · 1.2M from a million up. Clade's biomass.
static func num(x: float) -> String:
	if not is_finite(x):
		return "—"
	var a := absf(x)
	var sg: String = MINUS if x < 0 else ""
	if a >= 1e15:
		var e: int = int(floor(log(a) / log(10.0)))     # a broken build's figures (21 Oct): 1.2e30, never an int's overflow
		var mant: float = snappedf(a / pow(10.0, e), 0.1)
		if mant >= 10.0:
			mant /= 10.0                      # the log a hair under the power: 10.0e29 is 1.0e30
			e += 1
		return "%s%.1fe%d" % [sg, mant, e]
	if a >= 1e12:
		return "%s%.1fT" % [sg, a / 1e12]
	if a >= 1e9:
		return "%s%.1fB" % [sg, a / 1e9]
	if a >= 1e6:
		return "%s%.1fM" % [sg, a / 1e6]
	if a < 10.0 and a != floorf(a):
		return "%s%.1f" % [MINUS if x < 0 else "", a]
	return group(int(round(x)))


## A quantity a second: +0.7/s · +12.4/s · +1,234/s.
static func rate(x: float) -> String:
	if not is_finite(x):
		return "—"
	var a := absf(x)
	if a < 100.0:
		return "+%.1f/s" % a
	return "+%s/s" % group(int(round(a)))


static func group(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return (MINUS if n < 0 else "") + s + out


## 4,816 tins · −360 tins · 1 tin · 12.4M tins from ten million up.
## After the Issue (25 Oct) every sum is fiat: "ƒ12,400" (main sets it from the sim each refresh).
static var fiat := false
static var note_fiat := 0.0           # a note's fiat after the Issue: the crews' prices read as money (main sets it)


## A sum of notes as the screen says it: "120 notes"; after the Issue, its fiat.
static func notes(n: int) -> String:
	return money(n * note_fiat) if fiat and note_fiat > 0.0 else "%s notes" % group(n)


static func money(x: float) -> String:
	if not is_finite(x):
		return "—"
	var sgn := MINUS if x < -0.5 else ""
	var a := absf(x)
	if fiat:
		return ("%sƒ%.1fM" % [sgn, a / 1e6]) if a >= 1e7 else ("%sƒ%s" % [sgn, group(int(round(a)))])
	if a >= 1e7:
		return "%s%.1fM %s" % [sgn, a / 1e6, UNIT]
	var n := int(round(a))
	return "%s%s %s" % [sgn, group(n), "tin" if n == 1 else UNIT]


## A figure short: 950 · 4.8k · 48k · 1.2M (the tiles and buttons a full "4,816 tins" runs past).
static func short_num(x: float) -> String:
	var a := absf(x)
	var sgn := MINUS if x < -0.5 else ""
	if a >= 999500.0:
		return "%s%.1fM" % [sgn, a / 1e6]
	if a >= 1e4:
		return "%s%.0fk" % [sgn, a / 1e3]
	if a >= 1e3:
		return "%s%.1fk" % [sgn, a / 1e3]
	return "%s%d" % [sgn, int(round(a))]


## Money short: "4.8k tins"; under a thousand as money() says it. After the Issue "ƒ4.8k" (the third review).
static func money_k(x: float) -> String:
	if absf(x) < 1e3:
		return money(x)
	if fiat:
		return "%sƒ%s" % [MINUS if x < -0.5 else "", short_num(absf(x))]
	return "%s %s" % [short_num(x), UNIT]


## The money's name: tins, or fiat after the Issue.
static func unit() -> String:
	return "fiat" if fiat else UNIT


## Money long to short, for UI.fit: "4,816 tins", "4.8k tins", "4.8k".
static func money_forms(x: float) -> Array:
	return [money(x), money_k(x), short_num(x)]


## When a save was made, in local time: 21 Sep, 15:02.
static func when(unix: float) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(int(unix) + bias)
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%d %s, %02d:%02d" % [d["day"], months[d["month"] - 1], d["hour"], d["minute"]]


static func pct(x: float) -> String:
	return "%d%%" % int(round(x * 100.0))


## m:ss for countdowns and the run clock.
static func mss(seconds: float) -> String:
	var s := int(max(0.0, seconds))
	@warning_ignore("integer_division")
	return "%d:%02d" % [s / 60, s % 60]


## The run clock: 45:00, then 1:12:05 past the hour.
static func clock(seconds: float) -> String:
	var s := int(max(0.0, seconds))
	if s < 3600:
		return mss(s)
	@warning_ignore("integer_division")
	return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]


## A duration as the expeditions say it (the fix round, 30 Oct: one helper, the board's and the report's): "30 min",
## "1 h 20 min", "3 h".
static func dur(seconds: float) -> String:
	var m: int = int(round(seconds / 60.0))
	@warning_ignore("integer_division")
	var h: int = m / 60
	m = m % 60
	if h == 0:
		return "%d min" % m
	return ("%d h" % h) if m == 0 else ("%d h %d min" % [h, m])


## A span in hours: 2 hours, 1 hour, 30 minutes.
static func hours(h: float) -> String:
	if h < 1.0:
		return "%d minutes" % int(round(h * 60.0))
	if absf(h - 1.0) < 0.01:
		return "1 hour"
	return "%d hours" % int(round(h))


## Time away: 5 h 46 m, 12 m, 40 s.
static func away(seconds: float) -> String:
	var s := int(seconds)
	if s >= 3600:
		@warning_ignore("integer_division")
		return "%d h %d m" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
		@warning_ignore("integer_division")
		return "%d m" % (s / 60)
	return "%d s" % s


static func days(x: float) -> String:
	if absf(x - 1.0) < 0.05:
		return "1 day"
	if x < 10.0:
		return "%.1f days" % x
	return "%d days" % int(round(x))


static func times(x: float) -> String:
	return "%.2f×" % x


## A count and its noun: 1 shift, 3 shifts.
static func count(n: int, noun: String) -> String:
	return "%s %s" % [group(n), noun if n == 1 else noun + "s"]


## The calendar: a site day since the run began, as a date - 14 Mar 2027.
static func date(start: Dictionary, day_n: float) -> String:
	var unix := Time.get_unix_time_from_datetime_dict({"year": start["year"], "month": start["month"],
			"day": start["day"], "hour": 12, "minute": 0, "second": 0})
	var d := Time.get_datetime_dict_from_unix_time(int(unix) + int(floor(day_n)) * 86400)
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%d %s %d" % [d["day"], months[d["month"] - 1], d["year"]]


## The sim's event log, in the player's words.
static func event(text: String) -> String:
	return text.replace(" - ", " — ")

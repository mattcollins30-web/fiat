extends RefCounted
## Turning the sim's numbers into text. Formatting only - no economics.
##
## The generic half of Pithole's: money, counts, times. The house game's own units
## (bricks, homes, square metres) come with its sim.

const MINUS := "−"
const UNIT := "tins"                # what everything is paid in (13 Oct, Matt: a game about a collapse, paid in cash, made no sense)


## A plain quantity: 1,234 · 12,345 · 1.2M from a million up. Clade's biomass.
static func num(x: float) -> String:
	if not is_finite(x):
		return "—"
	var a := absf(x)
	if a >= 1e6:
		return "%s%.1fM" % [MINUS if x < 0 else "", a / 1e6]
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
static func money(x: float) -> String:
	if not is_finite(x):
		return "—"
	var sign := MINUS if x < -0.5 else ""
	var a := absf(x)
	if a >= 1e7:
		return "%s%.1fM %s" % [sign, a / 1e6, UNIT]
	var n := int(round(a))
	return "%s%s %s" % [sign, group(n), "tin" if n == 1 else UNIT]


## A figure short: 950 · 4.8k · 48k · 1.2M (the tiles and buttons a full "4,816 tins" runs past).
static func short_num(x: float) -> String:
	var a := absf(x)
	var sign := MINUS if x < -0.5 else ""
	if a >= 999500.0:
		return "%s%.1fM" % [sign, a / 1e6]
	if a >= 1e4:
		return "%s%.0fk" % [sign, a / 1e3]
	if a >= 1e3:
		return "%s%.1fk" % [sign, a / 1e3]
	return "%s%d" % [sign, int(round(a))]


## Money short: "4.8k tins"; under a thousand as money() says it.
static func money_k(x: float) -> String:
	return money(x) if absf(x) < 1e3 else "%s %s" % [short_num(x), UNIT]


## Money long to short, for UI.fit: "4,816 tins", "4.8k tins", "4.8k".
static func money_forms(x: float) -> Array:
	return [money(x), money_k(x), short_num(x)]


## Income a second: +12 tins/s, +1.20 tins/s under ten, +1,234 tins/s.
static func per_s(x: float) -> String:
	if not is_finite(x):
		return "—"
	var sign := MINUS if x < -0.005 else "+"
	var a := absf(x)
	if a < 10.0:
		return "%s%.2f %s/s" % [sign, a, UNIT]
	return "%s%s %s/s" % [sign, group(int(round(a))), UNIT]


## When a save was made, in local time: 21 Sep, 15:02.
static func when(unix: float) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(int(unix) + bias)
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%d %s, %02d:%02d" % [d["day"], months[d["month"] - 1], d["hour"], d["minute"]]


## +840 tins / −1,650 tins for ledger lines.
static func signed_money(x: float) -> String:
	return ("+" if x >= 0 else "") + money(x)


static func pct(x: float) -> String:
	return "%d%%" % int(round(x * 100.0))


## m:ss for countdowns and the run clock.
static func mss(seconds: float) -> String:
	var s := int(max(0.0, seconds))
	return "%d:%02d" % [s / 60, s % 60]


## The run clock: 45:00, then 1:12:05 past the hour.
static func clock(seconds: float) -> String:
	var s := int(max(0.0, seconds))
	if s < 3600:
		return mss(s)
	return "%d:%02d:%02d" % [s / 3600, (s % 3600) / 60, s % 60]


## A span in hours: 2 hours, 1 hour, 30 minutes.
static func hours(h: float) -> String:
	if h < 1.0:
		return "%d minutes" % int(round(h * 60.0))
	if absf(h - 1.0) < 0.01:
		return "1 hour"
	return "%d hours" % int(round(h))


## The same, short, for buttons: 8 h, 30 m.
static func hours_short(h: float) -> String:
	if h < 1.0:
		return "%d m" % int(round(h * 60.0))
	return "%d h" % int(round(h))


## Time away: 5 h 46 m, 12 m, 40 s.
static func away(seconds: float) -> String:
	var s := int(seconds)
	if s >= 3600:
		return "%d h %d m" % [s / 3600, (s % 3600) / 60]
	if s >= 60:
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


## A job's pace against the first: ×1, ×1.5, ×1.25 - two places at most, as the
## tree states its ranks, so a card and the tree agree.
static func pace_level(x: float) -> String:
	return ("×%.2f" % x).rstrip("0").rstrip(".")


## A countdown in whole weeks: 12 weeks, 1 week - never 0 while something's left.
static func in_weeks(x: float) -> String:
	var n := maxi(1, ceili(x / 7.0 - 1e-6))
	return "%d week%s" % [n, "" if n == 1 else "s"]


## A countdown in whole days: 12 days, 1 day - never 0 while something's left.
static func in_days(x: float) -> String:
	var n := maxi(1, ceili(x - 1e-6))
	return "1 day" if n == 1 else "%d days" % n


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

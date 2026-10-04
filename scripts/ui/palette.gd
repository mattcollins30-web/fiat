extends RefCounted
## Every colour, size and screen measure the UI uses. Nothing else in scripts/ui
## picks a colour or a number of pixels on its own.
##
## Text contrast, checked: primary 12.8:1 on a card, secondary 6.8:1, muted 5.5:1,
## dark on amber 8.4:1 - every pair clears 4.5:1, which still holds on the Deck
## where 24 px draws at 16.

# colours
const BG := Color("15171a")
const PANEL := Color("1d2024")
const CARD := Color("23272c")
const CARD_LINE := Color("343a41")
const TEXT := Color("eceded")
const TEXT_2 := Color("a9afb6")
const TEXT_3 := Color("969da5")
const ACCENT := Color("e3a33b")       # amber - the main action on a card
const ACCENT_HOVER := Color("eeb557")
const ACCENT_PRESS := Color("c98d2c")
const ACCENT_TEXT := Color("1a1308")
const BUTTON := Color("2f353c")
const BUTTON_HOVER := Color("3a424b")
const BUTTON_PRESS := Color("262b31")
const BUTTON_OFF := Color("262a2f")
const SELECT := Color("2b3138")
const GOOD := Color("62bd8f")
const WARN := Color("e3a33b")
const BAD := Color("ee7663")
const DIM := Color(0, 0, 0, 0.72)     # behind a full-screen moment
# the place's tone (the fifth slice): the screen's grounds shift a little by
# place - neutral in the village, warmer in the town, cooler in the city; the
# amber stays the action's colour everywhere
const PLACE_BG := {"village": BG, "town": Color("18161a"), "city": Color("131619")}
const PLACE_PANEL := {"village": PANEL, "town": Color("201d20"), "city": Color("1b1f25")}

# type, px at 1080 - the Deck draws them at two-thirds, so 24 is the floor
const FLOOR := 24
const LINE := 26
const TITLE := 30
const HEADLINE := 40
const TOP := 26
const NAME := 30
# inside an item cell, where there is no picture yet: a 64 px cell can't carry
# the floor, so its words are smaller and fewer (two short lines), and read as
# a placeholder for the art, not as copy
const CELL_TEXT := 16
const CELL_TEXT_BIG := 18

# the item grid: a cell is 64 px, the footprint's unit; the pictures are made
# at footprint x 64 (tools/make_item_manifests.py), so this is the one number
# the art depends on
const CELL := 64
const CELL_GAP := 6

# the screen at 1920 x 1080 (Pithole's menu_shell.md §1)
const MARGIN := 24
const TOP_H := 64
const RAIL_W := 312
const RAIL_BTN_H := 112              # seven rooms (Pithole's menu_shell.md §16)
const RAIL_GAP := 8                  # eight rooms: 8 × 112 + 7 × 8 = 952, inside the 1080 with the top bar and a margin
const CARD_W := 372
const CARD_H := 424
const CARD_GAP := 16
const COLS := 4
const ROWS := 2
const GRID_W := COLS * CARD_W + (COLS - 1) * CARD_GAP     # 1536
const GRID_H := ROWS * CARD_H + (ROWS - 1) * CARD_GAP     # 864
const EVENTS_H := 88
const MAX_CARDS := COLS * ROWS                             # eight a room, never more

# the card (Pithole's menu_shell.md §3)
const PAD := 20
const INNER := CARD_W - 2 * PAD                            # 332
const LINES := 6
const LINE_H := 32
const BUTTON_H := 56


static func place_bg(place: String) -> Color:
	return PLACE_BG.get(place, BG)


static func place_panel(place: String) -> Color:
	return PLACE_PANEL.get(place, PANEL)


static func tone_color(tone: String) -> Color:
	match tone:
		"good":
			return GOOD
		"warn":
			return WARN
		"bad":
			return BAD
	return TEXT_2

extends Resource
## Where the Map's places sit on its painting (5 Nov, BUILD52; Matt: "can you do an f3/f5 piece for the places? some of
## the ones you've selected I'd want to move"): the Map's F3 tool (map_placement.gd) drags them, F5 saves them here
## (data/map_places.tres). Every point is in the painting's own pixels at `paint_size` (art/map/map.png, 688 x 384, drawn
## x2), so a later repaint at another size rescales them. A place not here sits where map_view.gd's own tables say.

@export var paint_size: Vector2 = Vector2.ZERO     # always written: a default isn't saved (the review: F5 dropped 688 x 384)
@export var sites: Dictionary = {}          # a site's key (the_allotments) -> its pin
@export var order: Dictionary = {}          # an order's place's key (grid) -> its diamond
@export var town: Dictionary = {}           # a town's place's key (substation) -> its square
@export var zone_names: Dictionary = {}     # a zone's key (the_outskirts) -> its name's top left
@export var zones: Dictionary = {}          # a zone's key -> its shape, a PackedVector2Array (lit, hatched, the cloud's cut)

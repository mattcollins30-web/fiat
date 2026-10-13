extends Resource
## Where the fight's figures stand on each site (13 Oct, Matt: "Greenhorn's F3/F5 placement"): the run view's F3 tool
## drags them, F5 saves them here (data/fight_slots.tres). A site key (the_allotments) -> its three slots, middle, near,
## far, each [foot x, foot y, scale] in the frame's own space (588 x 262). A site not here stands its figures where the
## view's own tables say (run_view.gd's SLOTS and SITE_*).

@export var sites: Dictionary = {}

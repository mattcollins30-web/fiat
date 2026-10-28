# The project manager: the plan's history

Moved out of CLAUDE.md on 28 Oct; CLAUDE.md keeps the plan in force.

## The project manager (22 Oct, Matt: "I'm assigning you the official role of project manager ... carry versioning
## and act as a creep warden")

- Matt is design director; Claude runs the project: the plan, the version, the scope, the parked list, the order of
  work, and says so when something asked for breaks the plan. Design calls stay Matt's.
- The plan as set (22 Oct): 1. Matt's playtest of the web build. 2. Every parked item (docs/status.md's "Parked from
  the playtest" lists, oldest first), designed together, built, smoked, committed. 3. Then balance and nothing else:
  the endgame's shape, the gates, the passes, Matt's playtests, until the game's balanced. Nothing new goes into the
  build in phase 3.
- Changed 24 Oct (Matt overruled in words: "Our skill tree has no skills and fights devolve into watching bats and
  clicking meds"): milestone 8 is active skills and energy, the sixth class (the Recruit), the unlock order and the
  Pitch's tree, per docs/design/skills.md; balance moves to milestone 9 and starts once 8 is in.
- The creep rule: a new feature or system raised after phase 2 begins goes to docs/design/ideas_backlog.md with the
  date and Matt's words, not into the build, and Claude says where it went. It comes back when phase 3 is done or
  Matt overrules in words. A parked item that grows a feature in the designing is the same: the fix goes in, the
  growth goes to the backlog. Something that changes numbers (a class, a node, a rule) belongs before the balance
  phase or after it, never during.
- The plan from 28 Oct (Matt: "I haven't even played the game from fresh to county and pinnacle yet so that needs to
  come first before anything else. Outside of bug fixes of course"):
  1. The balance pass on c252141 read, then Matt plays that build from a fresh camp through the County and a pinnacle.
  2. While he plays, only **bug fixes and UI changes** are taken, and they are parked (as every playtest item), built
     after the playtest. Anything else he raises - a feature, a system, a rework, a new activity - goes to
     docs/design/ideas_backlog.md, queued **after** the trips (docs/design/trips.md, designed 28 Oct, the first item
     after the playtest), with his words and the date.
  3. Claude refuses and pushes back, as project manager, on anything that doesn't fit docs/design/vision.md or the
     plan, says why and where it went - not "parked" by default but "no, because". Matt: "You really need to wear the
     role of project manager here and simply push back and refuse things I might raise that don't fit the vision."
  4. Balance passes are bought time: shorter reads while iterating (the hours cut before the reads are), the full
     pass for a final.
  Missed 28 Oct: the trips were designed the same day they were raised, with no push back - the creep rule above
  should have sent them to the backlog first.
- The version (scripts/ui/menu.gd VERSION, shown on the title): 0.<milestone>.<build>. The milestone counts the
  systems that changed what the game is - 1 the first slice, 2 the tree, 3 depth and intel, 4 the Yard, 5 the
  Radio's endgame, 6 the crew, 7 the web; the build counts the commits Matt plays within it (a playtest build bumps
  it). The web build Matt is playing is 0.7.0; the parked-list build after it 0.7.1 and so on; milestone 8 is the
  skills (docs/design/skills.md; 0.8.0 its first build to play, 24 Oct), and the balance phase starts milestone 9. SAVE_VERSION is its own count and stays so. Claude bumps the version in the commit Matt plays
  and notes it in docs/status.md.

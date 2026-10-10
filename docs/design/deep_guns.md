# Deep bases (10 Oct 2026, concept - not built)

From Matt's playtest: the drops top out at the Bank - "a 100 dps SMG at the bank" and nothing better past it, so
the depths have no gun to chase. Agreed with Matt (10 Oct): **new deep bases; leave the campaign as it is**.
Board: Guns-D on the design canvas.

## 1. The bases

Each gun type gets three bases past the campaign's six tiers, found only at depth. Tier 7 drops from depth 4
(where salvage starts), tier 8 from depth 8 and tier 9 from depth 12 (the pinnacles' depths). Each tier is about
+18% damage a second on the type's own line. Names are first goes - change any of them.

| Type | Its best now (tier 6) | Tier 7 · depth 4 | Tier 8 · depth 8 | Tier 9 · depth 12 |
|---|---|---|---|---|
| SMG | Riot squad's SMG 123 | Security service SMG 31 × 4.6 = 143 | Close protection SMG 34 × 4.9 = 167 | Special forces SMG 37 × 5.2 = 192 |
| Rifle | Police marksman's rifle 113 | Range rifle 96 × 1.4 = 134 | Service rifle 104 × 1.5 = 156 | Anti-materiel rifle 150 × 1.2 = 180 |
| Shotgun | Assault shotgun 115 | Breaching shotgun 34 × 4.0 = 136 | Entry shotgun 38 × 4.2 = 160 | Combat shotgun 41 × 4.6 = 189 |
| Pistol | Officer's revolver 58 | Close quarters pistol 24 × 2.8 = 67 | Bodyguard's pistol 27 × 2.9 = 78 | Special issue pistol 30 × 3.1 = 93 |
| Improvised | the best improvised | Bolt-action garage rifle | Workshop gauss | The engineer's piece |

Damage a second is damage × rate of fire. The improvised bases follow their own type's line when they are set.
Each base keeps its type's sustain (magazine and reload) shape, scaled like the tier-6 base.

## 2. How they drop

- `Data.MAX_TIER` rises from 6 to 9 for guns only. Armour, bags and rigs keep their top tier: `Items.roll` clamps
  a roll to the slot's own top tier, so a deep site never rolls an empty tier.
- A site's loot tier grows with its depth: from depth 4 it reaches 7, from depth 8 it reaches 8, and from depth 12
  it reaches 9. The campaign's sites and their drops stay as they are.
- The Fence's Arms dealer stocks deep bases at the runner's depth.
- Each base gets a line in `words.gd` and a value on the tier-6 line.

## 3. To check in the balance pass

- The depth read: how deep a plain build gets with the new bases compared with now. That figure and the depth
  pool's HP growth decide whether +18% is right.
- The run's clock at depth: it is a DPS check, so better guns there make it easier. Look at the time-outs row.

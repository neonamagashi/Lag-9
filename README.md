# Lag 9

A 2.5D (three-quarter top-down) pixel-art roguelite in Godot 4.7: a gravity witch descending the nine circles of hell to rescue her cat, Whisky. Open this folder in Godot and press F5.

The current playable slice is Limbo: the Ancient Ruins sample map, four waves of monsters, and a mimic hiding as a chest.

## Controls
| Key | Action |
|---|---|
| WASD | Move |
| Mouse | Aim |
| LMB (hold) | Pierce: comet bolts |
| RMB (hold, release) | Send: charged cone blast; enemies hitting walls, ledges or each other take impact damage |
| E | Draw: yank enemies toward you (into the crushing rings) |
| R | Rend: lift the 3 nearest enemies and tear them apart (instant kill on light and medium mobs; heavy ones and bosses take big damage) |
| Space | Snap: teleport (movement direction, or toward the cursor when standing still); stops short of walls and water |
| Q | Flip the field between Crush and Lift |
| G | Singularity (60 mana): the field grows 2.4x, everything inside slows, crush doubles, bosses lose their resistance |
| 1 | Drink whisky (heal) |
| F1 / F5 | Help / restart |

## The gravity field
Three rings, sized from her height (37 px): inner = 1x her height wide, middle = 3x, outer = 8x. Gravity works through walls and obstacles.

| Zone | Crush mode | Lift mode |
|---|---|---|
| Outer | Slowed more the deeper they go, light damage over time | Slowed |
| Middle | Barrier: enemies can't walk into it. If she walks onto them they're pinned in a struggling pose (a frame from their death animation) taking heavy damage over time. Heavy enemies (mimic) are slowed instead and can still swing. Flyers are slammed down. | Light and medium enemies float helplessly; flip back to Crush to slam them |
| Inner | Instant crush | |

- Physical projectiles (goblin bombs, skeleton swords) are crushed at the inner ring and never land. Magical ones (flying eye bolts, mushroom spores) pass through.
- Bosses (`"boss": true` in an enemy's config) push through the field with reduced damage and aren't held by the barrier, unless Singularity is active.
- Damage over time shows as purple numbers every 0.5 s.

Tuning lives at the top of `scripts/witch.gd` (abilities and ring sizes) and `scripts/enemy.gd` (enemy stats, per-zone damage, slow, scale, ranged attacks).

## Levels
Maps are built in [Tiled](https://www.mapeditor.org/) and converted with
`python3 tools/tmx2json.py <map.tmx> assets/maps/<name>.json .`
The converter repacks animated tiles and marks walls and water solid (platform tops and stairs stay walkable). `scripts/tiled_level.gd` builds the tile layers, collision and enemy pathfinding at runtime. The level is chosen by `LEVEL` at the top of `scripts/main.gd`; set it to `""` for the original placeholder dungeon room.

## Tools (Python, in `tools/`)
- `gen_back_view.py`: back-facing witch frames from the front sheets.
- `gen_cast_clean.py`: cast frames without the baked-in ground orbs, so effects follow your aim.
- `gen_sigils.py`: the field's rune ring and seven-point star.
- `gen_env.py`: placeholder dungeon pixel art.

## Tests
- `tests/play_test.tscn` (headless): checks every field rule, Rend, teleport, bosses and projectiles, then a bot plays all four waves.
- `tests/shots_vfx.tscn`: renders screenshots of each effect.

See `CREDITS.md`.

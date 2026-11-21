# Lag 9

A 2.5D (three-quarter top-down) pixel-art roguelite in Godot 4.7: a gravity witch descending the nine circles of hell to rescue her cat, Whisky. Open this folder in Godot and press F5.

Two playable areas: Limbo (the start) and the Ancient Ruins test arena (four waves plus a mimic). Switch in Settings (Esc).

## Controls
| Key | Action |
|---|---|
| WASD | Move (she floats; Shift jumps) |
| Mouse | Aim (a small rune circles her inner ring showing the direction) |
| LMB (hold) | Pierce: she thrusts an open palm and a violet beam fires from it toward the cursor, hitting everything along it |
| RMB | Grab: seize the enemy you're aiming at (any mob; bosses only if her level is at or above theirs) and hold it in front of you. RMB again (label switches to Release): hold to charge, release to fling it where you aim. While held it's crushed in an invisible fist (taking a little damage) and swings on a spring as you sweep your aim, smacking anything it hits |
| F (hold, release) | Send: a runic smoke shockwave that pushes every enemy around her outward; impacts with walls or other enemies hurt |
| T (hold, release) | Draw: the same wave pulled inward, dragging enemies into the crushing rings |
| R | Rend: lift the 3 nearest enemies and tear them apart |
| Space | Snap: teleport; the air rushes in behind her and her arrival billows smoke like dry ice |
| Shift / Mouse 5 (hold, release) | Jump: charge for height; clears ledges and objects, lands on the nearest open ground |
| Q | Flip the field between Crush and Lift |
| G | Singularity (60 mana): field grows 2.4x, black and white smoke billows beneath her |
| 1 | Drink whisky (heal) |
| E | Interact |
| Esc | Settings (switch between Limbo and the Ancient Ruins test arena) |
| F1 / F5 | Help / restart |

## Limbo (Circle 1)
The game starts here, as a scripted scene (lines in `assets/dialogue/limbo.json`; `*word*` in a line is an action cue, e.g. `*buuurp*`). Black, then a blinding flash: she arrives hungover in a pure white void and sees Whiskey wandering off north, meowing. She drifts north at a slowed, swaying pace through a crowd of about 56 souls that gets denser toward the Warden: groups muttering to each other about nothing, loners mumbling to themselves, some sitting, some wandering. The smell gets to her and she throws up (a rainbow). At the Warden, Whiskey slips past him, they talk (her thought bubbles show she isn't listening), she throws up again, and only then can she press E to Begin. The souls drift away, her field and abilities awaken, and three waves attack. Afterwards the Warden lets her pass. The whole level has reverb. Whiskey is a placeholder sprite until the real cat art arrives.

Placeholder dialogue lives in `assets/dialogue/limbo.json` (edit the lines freely). Voices are babble sounds while text types out.

## The gravity field
Three rings, sized from her height (40 px): inner = 1x her height wide, middle = 3x, outer = 8x. Gravity works through walls and obstacles.

| Zone | Crush mode | Lift mode |
|---|---|---|
| Outer | Slowed more the deeper they go, light damage over time | Slowed |
| Middle | Barrier: enemies can't walk into it. If she walks onto them they're pinned in a struggling pose (a frame from their death animation) taking heavy damage over time. Heavy enemies (mimic) are slowed instead and can still swing. Flyers are slammed down. | Light and medium enemies float helplessly; flip back to Crush to slam them |
| Inner | Instant crush | |

- Physical projectiles (goblin bombs, skeleton swords) are crushed at the inner ring and never land. Magical ones (flying eye bolts, mushroom spores) pass through.
- Bosses (`"boss": true` in an enemy's config) push through the field with reduced damage and aren't held by the barrier, unless Singularity is active.
- Damage over time shows as purple numbers every 0.5 s.

Tuning lives at the top of `scripts/witch.gd` (abilities and ring sizes) and `scripts/enemy.gd` (enemy stats, per-zone damage, slow, scale, ranged attacks).

## Enemy physics

- Thrown, pushed or pulled enemies fly until friction stops them. Anything they hit gets knocked on, by weight (a rat barely moves a mimic), and both take damage, so chains happen.
- Enemy projectiles hit whoever is in the way: a skeleton's sword or an eye's bolt will hit an ally, and goblin bombs splash every enemy nearby. A held enemy works as a shield.
- Enemies try to avoid this: they keep their distance from each other, sidestep instead of shooting through an ally, get out from under falling bombs, and dodge bodies flying their way.

## Levels
Maps are built in [Tiled](https://www.mapeditor.org/) and converted with
`python3 tools/tmx2json.py <map.tmx> assets/maps/<name>.json .`
The converter repacks animated tiles and marks walls and water solid (platform tops and stairs stay walkable). `scripts/tiled_level.gd` builds the tile layers, collision and enemy pathfinding at runtime. The level is chosen by `LEVEL` at the top of `scripts/main.gd`; set it to `""` for the original placeholder dungeon room.

## Tools (Python, in `tools/`)
- `gen_white_witch.py`: the White Witch's glowing purple eyes, back views, aim-able cast and separate beam, and the jump pose.
- `gen_limbo.py`: the souls of Limbo (skin tones, loincloths, tunics) and the cloaked figure.
- `synth_sfx.py`: snap, babble, mumble, arrival flash, push/pull waves, grab, beam, jump and land sounds.
- `gen_sigils.py`: the field's rune ring and seven-point star.
- `gen_env.py`: placeholder dungeon pixel art.

## Tests
- `tests/play_test.tscn` (headless, ruins): every field rule, Rend, teleport, grab and throw, push, pull, jump, bosses and projectiles, then a bot plays all four waves.
- `tests/limbo_test.tscn` (headless): the whole opening scene (souls, slowed walk, vomiting, the Warden conversation), Begin, and the trial battle.
- `tests/shots_scene.tscn`: screenshots of each beat of the opening scene.
- `tests/physics_test.tscn` (headless): grab squeeze and swing, thrown and pushed enemies colliding, friendly fire, line-of-fire sidestepping, dodging bombs, Lift and the slam.
- `tests/shots_v5.tscn`: screenshots (and close crops) of the back view, lean, Warden, palm cast, charge effects, grab squirm, Lift and Singularity.
- `tests/shots_vfx.tscn`: renders screenshots of each effect.

See `CREDITS.md`.

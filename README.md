# Lag 9

A gravity witch descends through the nine circles of hell to get her cat, Whisky, back. Third-person, N64-style, built in Godot 4.7.

## Run it
1. Open Godot 4.7, click **Import**, and pick this folder's `project.godot`.
2. Press **F5** to play.

## Default controls
Rebind any of these in game: press **Esc**, click a binding, then press a key or mouse button. Bindings save automatically.

| Action | Default |
|---|---|
| Move | W A S D |
| Jump: press again in the air to gravity-jump; hold to charge it higher | Mouse 5 |
| Fly: double-tap jump while airborne (double-tap again to drop) | Mouse 5 |
| Rise / descend while flying | hold Mouse 5 / Ctrl |
| Clamber | jump or push into a ledge up to 2.6 m above your feet |
| Sprint | Shift |
| Snap (dodge with i-frames) | Space |
| Pierce (hold to keep firing) | Mouse L |
| Send (tap to stagger, hold to charge) | Mouse R |
| Draw (tap to stagger, hold to charge) | E |
| Rend (aim at a target) | R |
| Singularity (costs mana) | G |
| Flip crush / lift | Q |
| Field on / off | F |
| Drink whisky | 1 |
| Camera | Mouse; scroll to zoom |

## Debug keys
F1 overlay · F2 spawn wave · F3 render scale · F4 clear enemies · `[` `]` witch level · F6 heal · F7 Snap rank · F8 Pierce rank · F9 reset cooldowns and fill mana · F10 Send/Draw rank · F11 Rend rank · F12 Singularity rank

Enemies marked `*` carry mana and drop an orb when they die. Blue bottles around the arena refill mana and respawn. The roofed room in the far corner is for testing Lift and Singularity ceiling slams.

## Tuning
All balance and movement numbers live in `data/balance.tres`. Select it in the FileSystem dock and edit the values in the Inspector, grouped by Levels, Gravity Field, Pierce, Snap, Movement, Enemies and Items.

## Models
`models/witch_rigged.glb` is the Mixamo-rigged witch (body and hair as separate meshes, 18 hair bones in 5 chains). The game prefers it over `models/witch.glb` when both exist. Her hair runs on Godot's spring bones: it hangs and lags with movement, droops in Crush and floats upward in Lift. Tune it under Hair Physics in `balance.tres` (stiffness is strongest at the roots and loosens toward the tips).

Before exporting from Blender, apply all transforms (Object > Apply > All Transforms) on every mesh and delete the default cube, so pieces land in the right place.

`models/staff.glb` is the game-ready staff (about 8k triangles, 1024 texture). The original high-detail exports live in `models/source`, which Godot ignores.

The staff floats diagonally across her back and grows from 1 m to 3 m as abilities are maxed (one step per maxed ability; F7, F8, F10, F11 and F12 cycle ranks to preview it). Its purple stone and runes glow brighter with each step. Hat and hair sway toward her gravity through a vertex shader; tune both under Staff and Hair & Hat in `balance.tres`.

## Tests
`tests/sim_test.tscn` checks the charged jump, flight, clamber, Send, Draw, Rend and Singularity, and `tests/collision_test.tscn` checks knockback damage. Both print their results. Run it from the editor, or headless with `godot --headless --path . res://tests/sim_test.tscn`.

## Audio
`audio/sfx` holds placeholder sound effects and `audio/ambient` a looping Limbo drone. All of them were synthesized by `tools/synth_sfx.py` (run `python3 tools/synth_sfx.py audio/sfx`), so there are no licensing strings attached. Replace any file with a real recording of the same name and the game picks it up automatically. Master volume is in the Esc menu.

Code plays sounds by name, for example `Sfx.play("pierce", position)`. Sounds currently hooked up: pierce, snap, whiff, jump_charge, jump_release, flight_on, flip_crush, flip_lift, send, draw, rend, singularity, dodge, witch_hurt, whisky, mana_pickup, enemy_hit, enemy_attack, impact, crush_kill, ui_click.

## Environment assets
`assets/environment/Ultimate Stylized Nature Pack` (Quaternius, CC0). Only the glTF version is kept. Add new packs the same way: one format plus the license file.

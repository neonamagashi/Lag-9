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
F1 overlay · F2 spawn wave · F3 render scale · F4 clear enemies · `[` `]` witch level · F6 heal · F7 Snap rank · F8 Pierce rank · F9 reset cooldowns and fill mana · F10 Send/Draw rank · F11 Rend rank

Enemies marked `*` carry mana and drop an orb when they die. Blue bottles around the arena refill mana and respawn. The roofed room in the far corner is for testing Lift and Singularity ceiling slams.

## Tuning
All balance and movement numbers live in `data/balance.tres`. Select it in the FileSystem dock and edit the values in the Inspector, grouped by Levels, Gravity Field, Pierce, Snap, Movement, Enemies and Items.

## Swapping in a real witch model
Export her as `models/witch.glb`, facing +Z, with her feet at the origin. The game loads it automatically in place of the placeholder.

## Tests
`tests/sim_test.tscn` checks the charged jump, flight, clamber, Send, Draw, Rend and Singularity, and `tests/collision_test.tscn` checks knockback damage. Both print their results. Run it from the editor, or headless with `godot --headless --path . res://tests/sim_test.tscn`.

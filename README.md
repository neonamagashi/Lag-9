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
| Jump (press again in the air for a gravity jump) | Mouse 5 |
| Sprint | Shift |
| Snap (dodge with i-frames) | Space |
| Pierce (hold to keep firing) | Mouse L |
| Flip crush / lift | Q |
| Field on / off | F |
| Drink whisky | 1 |
| Send, Draw, Rend, Singularity | Mouse R, E, R, G (next milestone) |
| Camera | Mouse; scroll to zoom |

## Debug keys
F1 overlay · F2 spawn wave · F3 render scale · F4 clear enemies · `[` `]` witch level · F6 heal · F7 Snap rank · F8 Pierce rank

## Tuning
All balance and movement numbers live in `data/balance.tres`. Select it in the FileSystem dock and edit the values in the Inspector, grouped by Levels, Gravity Field, Pierce, Snap, Movement, Enemies and Items.

## Swapping in a real witch model
Export her as `models/witch.glb`, facing +Z, with her feet at the origin. The game loads it automatically in place of the placeholder.

## Tests
`tests/sim_test.tscn` runs crush, lift, field-off and dodge checks and prints the results. Run it from the editor, or headless with `godot --headless --path . res://tests/sim_test.tscn`.

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
Each character has its own folder in `models/`:

| Folder | Game file | Notes |
|---|---|---|
| `witch/` | `witch_rigged.fbx`, `witch_hair.glb`, `staff.glb` | `witch_rigged.fbx` is the auto-rigged body (Mixamo skeleton, 5 ft). The game uses it first; the curly hair is pinned to her Head bone so it follows every animation. `witch_body.glb` is the unrigged fallback. |
| `gnawling/`, `glutton/`, `acolyte/`, `seer/`, `archer/` | `<name>.glb` (+ `archer/bow.glb`) | Loaded as-is; the game turns, scales and grounds each one at load (sizes live in `scripts/enemy_types.gd`). |
| `*/rigger/` | FBX zips with quad topology | Hand these to the rigger. Godot ignores these folders. |
| `source/` | Original high-detail exports | Kept for reference. Godot ignores this folder. |

Without bones, her hair sways with a vertex shader: it trails her movement, droops in Crush and floats up and out in Lift. Tune it with `split_hair_sway_amount` under Hair & Hat in `balance.tres`.

## Enemies
| Type | Height | Role |
|---|---|---|
| Gnawling | 0.65 m | Fast, fragile swarmer |
| Glutton | 3.0 m | Slow tank, heavy hits, resists knockback |
| Acolyte | 1.8 m | Keeps ~9 m away and throws fireballs (physical: her field crushes them) |
| Seer | 2.3 m, floating | Keeps ~11 m away and throws homing void bolts that pass through her field |
| Archer | 1.85 m | Keeps ~14 m away and fires fast bone arrows (physical: crushed by the field) |

Stats, ranges and cooldowns are in `scripts/enemy_types.gd`. F2 spawns a mixed wave.

## Tests
`tests/enemy_test.tscn` checks enemy fitting and projectiles with the field on and off. `tests/sim_test.tscn` checks the charged jump, flight, clamber, Send, Draw, Rend and Singularity, and `tests/collision_test.tscn` checks knockback damage. Both print their results. Run it from the editor, or headless with `godot --headless --path . res://tests/sim_test.tscn`.

## Audio
`audio/sfx` holds placeholder sound effects and `audio/ambient` a looping Limbo drone. All of them were synthesized by `tools/synth_sfx.py` (run `python3 tools/synth_sfx.py audio/sfx`), so there are no licensing strings attached. Replace any file with a real recording of the same name and the game picks it up automatically. Master volume is in the Esc menu.

Code plays sounds by name, for example `Sfx.play("pierce", position)`. Sounds currently hooked up: pierce, snap, whiff, jump_charge, jump_release, flight_on, flip_crush, flip_lift, send, draw, rend, singularity, dodge, witch_hurt, whisky, mana_pickup, enemy_hit, enemy_attack, impact, crush_kill, ui_click.

## Environment assets
`assets/environment/Ultimate Stylized Nature Pack` (Quaternius, CC0). Only the glTF version is kept. Add new packs the same way: one format plus the license file.

## Animations

`animations/` holds the Universal Animation Library packs (UAL1 + UAL2, about 86 clips). Both packs and the witch rig import through Godot's humanoid retargeting (`animations/retarget/*_bone_map.tres`, set in each file's Advanced Import > Skeleton > Retarget), so any clip plays on her.

To browse them: double-click `UAL1_Standard.glb` or `UAL2_Standard.glb` in the FileSystem dock, open the Animation tab in the import window, and press play on any clip. That previews on the mannequin; in game the same clip drives the witch.

Which clip plays when is the `ANIMS` table at the top of `scripts/witch.gd`. Swap any name there to try a different clip.

| State | Clip |
|---|---|
| Float / move | Idle_FoldArms |
| Lounge (8 s idle) | Sitting_Enter → Sitting_Idle |
| Jump / airborne / air-jump charge | NinjaJump_Start / NinjaJump_Idle / Crouch_Idle |
| Flight moving / hovering | Swim_Fwd / Swim_Idle |
| Clamber | ClimbUp_1m (sped up) |
| Snap | Shield_Dash (fast) |
| Pierce | Spell_Simple_Shoot |
| Send hold / release | Push / OverhandThrow |
| Draw hold / release | Spell_Simple_Idle / Chest_Open |
| Rend | Spell_Simple_Enter → Spell_Simple_Idle |
| Singularity | Chest_Open |
| Whisky | Consume |
| Hit | Hit_Chest |

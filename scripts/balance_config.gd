class_name BalanceConfig
extends Resource

@export_group("Levels")
@export var witch_level: int = 10
@export var level_growth: float = 1.1
@export var gap_damage_falloff: float = 0.85
@export var enemy_base_hp: float = 100.0
@export var witch_base_hp: float = 120.0

@export_group("Gravity Field")
@export var field_radius: float = 7.0
@export var field_edge_pct: float = 0.06
@export var field_center_pct: float = 0.18
@export var instant_crush_time: float = 0.25
@export var kneel_gap_max: int = 4
@export var kneel_speed_mult: float = 0.2
@export var inner_crush_frac: float = 0.4
@export var inner_crush_time: float = 0.6
@export var heavy_slow_mult: float = 0.4
@export var pin_frac: float = 0.35
@export var pinned_contact_pct: float = 0.04
@export var lift_height: float = 3.0
@export var heavy_lift_height: float = 0.6
@export var impact_min_speed: float = 6.0
@export var impact_pct_per_speed: float = 0.03

@export_group("Pierce")
@export var pierce_rank: int = 0
@export var pierce_base_damage: Array[float] = [55.0, 62.0, 70.0, 80.0]
@export var pierce_range: Array[float] = [28.0, 34.0, 40.0, 48.0]
@export var pierce_cooldown: float = 0.35

@export_group("Snap")
@export var snap_rank: int = 0
@export var snap_distance: Array[float] = [7.0, 8.0, 9.5]
@export var snap_duration: Array[float] = [0.12, 0.07, 0.035]
@export var snap_iframe_padding: float = 0.08
@export var snap_cooldown: float = 2.0

@export_group("Send")
@export var send_rank: int = 0
@export var send_cooldown: float = 2.0
@export var send_max_charge: float = 1.0
@export var send_range: Array[float] = [10.0, 12.0]
@export var send_cone_deg: float = 70.0
@export var send_force_min: float = 7.0
@export var send_force_max: Array[float] = [24.0, 30.0]
@export var send_base_damage: float = 18.0
@export var stagger_time: float = 0.6

@export_group("Draw")
@export var draw_rank: int = 0
@export var draw_cooldown: float = 2.0
@export var draw_max_charge: float = 1.0
@export var draw_range: Array[float] = [13.0, 16.0]
@export var draw_cone_deg: float = 70.0
@export var draw_force_min: float = 7.0
@export var draw_force_max: Array[float] = [20.0, 26.0]

@export_group("Rend")
@export var rend_rank: int = 0
@export var rend_cooldown: float = 22.0
@export var rend_targets: Array[int] = [1, 3, 5, 10]
@export var rend_hold_time: float = 0.8
@export var rend_base_damage: float = 260.0
@export var rend_range: float = 30.0
@export var rend_shard_damage_pct: float = 0.3

@export_group("Singularity")
@export var singularity_cooldown: float = 80.0
@export var singularity_mana_cost: float = 60.0
@export var singularity_duration: float = 6.0
@export var singularity_rank: int = 0
@export var singularity_radius_mult: Array[float] = [3.5, 4.2, 5.0]
@export var singularity_damage_mult: Array[float] = [2.5, 3.0, 3.6]
@export var singularity_time_scale: float = 0.15
@export var singularity_lift_height: float = 9.0

@export_group("Mana")
@export var max_mana: float = 100.0
@export var start_mana: float = 70.0
@export var mana_creature_chance: float = 0.3
@export var mana_drop: float = 20.0
@export var mana_bottle_amount: float = 40.0
@export var mana_bottle_respawn: float = 25.0

@export_group("Collisions")
@export var enemy_collide_min_speed: float = 5.0
@export var enemy_collide_share: float = 0.5
@export var knock_resist_per_gap: float = 0.15

@export_group("Movement")
@export var walk_speed: float = 9.5
@export var sprint_speed: float = 14.5
@export var ground_accel: float = 95.0
@export var ground_decel: float = 75.0
@export var air_accel: float = 40.0
@export var gravity: float = 28.0
@export var jump_velocity: float = 10.0
@export var jump_cut: float = 0.55
@export var coyote_time: float = 0.12
@export var jump_buffer: float = 0.12
@export var turn_speed: float = 20.0
@export var hover_height: float = 0.35
@export var base_fov: float = 72.0
@export var sprint_fov: float = 82.0

@export_group("Gravity Jump")
@export var air_jump_min_charge: float = 0.12
@export var air_jump_max_charge: float = 0.7
@export var air_jump_min_velocity: float = 11.0
@export var air_jump_max_velocity: float = 19.0
@export var double_tap_window: float = 0.28

@export_group("Flight")
@export var flight_speed: float = 11.0
@export var flight_sprint_speed: float = 17.0
@export var flight_vertical_speed: float = 7.0
@export var flight_accel: float = 45.0
@export var flight_field_mult: float = 0.45
@export var flight_mana_per_sec: float = 0.0

@export_group("Clamber")
@export var clamber_max_height: float = 2.6
@export var clamber_reach: float = 0.9
@export var clamber_time: float = 0.24

@export_group("Staff")
@export var staff_base_length: float = 1.0
@export var staff_max_length: float = 3.0
@export var staff_glow_base: float = 1.5
@export var staff_glow_per_max: float = 0.5
@export var staff_tilt_deg: float = 40.0

@export_group("Hair & Hat")
@export var sway_lift_bias: float = 1.0
@export var sway_crush_bias: float = 0.35
@export var sway_idle_bias: float = 0.15
@export var sway_inertia: float = 0.035
@export var sway_stiffness: float = 60.0
@export var sway_damping: float = 7.0
@export var hat_sway_amount: float = 0.14
@export var hair_sway_amount: float = 0.07

@export_group("Enemies")
@export var enemy_speed: float = 3.4
@export var enemy_attack_range: float = 1.7
@export var enemy_attack_cooldown: float = 1.2
@export var enemy_hit_pct: float = 0.07
@export var enemy_gravity: float = 26.0

@export_group("Items")
@export var whisky_count: int = 3
@export var whisky_heal_pct: float = 0.35

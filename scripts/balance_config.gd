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
@export var snap_distance: Array[float] = [6.0, 7.0, 8.5]
@export var snap_duration: Array[float] = [0.2, 0.11, 0.05]
@export var snap_iframe_padding: float = 0.06
@export var snap_cooldown: float = 2.0

@export_group("Movement")
@export var walk_speed: float = 7.5
@export var sprint_speed: float = 12.0
@export var ground_accel: float = 70.0
@export var ground_decel: float = 55.0
@export var air_accel: float = 28.0
@export var gravity: float = 26.0
@export var jump_velocity: float = 9.5
@export var jump_cut: float = 0.55
@export var coyote_time: float = 0.12
@export var jump_buffer: float = 0.12
@export var double_jump_charge: float = 0.14
@export var double_jump_velocity: float = 12.0
@export var turn_speed: float = 14.0
@export var hover_height: float = 0.35

@export_group("Enemies")
@export var enemy_speed: float = 3.4
@export var enemy_attack_range: float = 1.7
@export var enemy_attack_cooldown: float = 1.2
@export var enemy_hit_pct: float = 0.07
@export var enemy_gravity: float = 26.0

@export_group("Items")
@export var whisky_count: int = 3
@export var whisky_heal_pct: float = 0.35

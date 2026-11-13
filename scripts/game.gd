extends Node

var balance: BalanceConfig = preload("res://data/balance.tres")
var witch: Witch
var env: Environment
var kills := 0
var enemy_time_scale := 1.0


func rank_value(arr: Array, rank: int) -> Variant:
	return arr[clampi(rank, 0, arr.size() - 1)]


func hp_for_level(level: int) -> float:
	return balance.enemy_base_hp * pow(balance.level_growth, level - 1)


func gap_mod(gap: int) -> float:
	return 1.0 if gap <= 0 else pow(balance.gap_damage_falloff, gap)


func scaled_damage(base: float, enemy_level: int) -> float:
	var w := balance.witch_level
	return base * pow(balance.level_growth, w - 1) * gap_mod(enemy_level - w)


func field_dps(enemy_level: int, prox: float) -> float:
	var pct := lerpf(balance.field_edge_pct, balance.field_center_pct, prox * prox)
	return pct * hp_for_level(balance.witch_level) * gap_mod(enemy_level - balance.witch_level)


func impact_damage(enemy_level: int, speed: float) -> float:
	var over := maxf(0.0, speed - balance.impact_min_speed)
	return over * balance.impact_pct_per_speed * hp_for_level(balance.witch_level) * gap_mod(enemy_level - balance.witch_level)


func witch_max_hp() -> float:
	return balance.witch_base_hp * pow(balance.level_growth, balance.witch_level - 1)


func maxed_abilities() -> int:
	var b := balance
	var n := 0
	for pair in [[b.pierce_rank, b.pierce_base_damage], [b.snap_rank, b.snap_distance], [b.send_rank, b.send_range], [b.draw_rank, b.draw_range], [b.rend_rank, b.rend_targets], [b.singularity_rank, b.singularity_radius_mult]]:
		if pair[0] >= pair[1].size() - 1:
			n += 1
	return n


func staff_length() -> float:
	return lerpf(balance.staff_base_length, balance.staff_max_length, maxed_abilities() / 6.0)


func pierce_hits_to_kill(gap: int) -> int:
	var lvl := balance.witch_level + gap
	return ceili(hp_for_level(lvl) / scaled_damage(rank_value(balance.pierce_base_damage, balance.pierce_rank), lvl))

extends Node

var balance: BalanceConfig = preload("res://data/balance.tres")
var witch: Witch
var kills := 0


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


func pierce_hits_to_kill(gap: int) -> int:
	var r := clampi(balance.pierce_rank, 0, balance.pierce_base_damage.size() - 1)
	var lvl := balance.witch_level + gap
	return ceili(hp_for_level(lvl) / scaled_damage(balance.pierce_base_damage[r], lvl))

class_name EnemyTypes
extends RefCounted

const DEFAULTS := {
	"model": "",
	"extra": "",
	"height": 1.0,
	"hp_mult": 1.0,
	"speed": 3.4,
	"mass": 1.0,
	"radius": 0.45,
	"ranged": false,
	"attack_range": 1.7,
	"keep_range": 10.0,
	"fire_range": 18.0,
	"projectile": "",
	"dmg_mult": 1.0,
	"cooldown": 1.2,
	"hover": 0.0,
}

const TYPES := {
	"imp": {},
	"gnawling": {
		"model": "res://models/gnawling/gnawling.glb",
		"height": 0.65, "hp_mult": 0.6, "speed": 4.8, "mass": 0.6, "radius": 0.3,
		"attack_range": 1.3, "dmg_mult": 0.6, "cooldown": 0.8,
	},
	"glutton": {
		"model": "res://models/glutton/glutton.glb",
		"height": 3.0, "hp_mult": 3.0, "speed": 2.1, "mass": 3.0, "radius": 0.95,
		"attack_range": 2.8, "dmg_mult": 2.2, "cooldown": 2.0,
	},
	"acolyte": {
		"model": "res://models/acolyte/acolyte.glb",
		"height": 1.8, "hp_mult": 0.9, "speed": 2.8, "radius": 0.4,
		"ranged": true, "keep_range": 9.0, "fire_range": 16.0, "projectile": "fireball",
		"dmg_mult": 0.9, "cooldown": 2.4,
	},
	"seer": {
		"model": "res://models/seer/seer.glb",
		"height": 2.3, "hp_mult": 1.1, "speed": 2.2, "radius": 0.4,
		"ranged": true, "keep_range": 11.0, "fire_range": 18.0, "projectile": "void",
		"dmg_mult": 1.0, "cooldown": 3.2, "hover": 0.35,
	},
	"archer": {
		"model": "res://models/archer/archer.glb", "extra": "res://models/archer/bow.glb",
		"height": 1.85, "hp_mult": 0.8, "speed": 3.0, "radius": 0.4,
		"ranged": true, "keep_range": 14.0, "fire_range": 24.0, "projectile": "arrow",
		"dmg_mult": 0.8, "cooldown": 1.9,
	},
}


static func config(kind: String) -> Dictionary:
	var out: Dictionary = DEFAULTS.duplicate()
	out.merge(TYPES.get(kind, {}), true)
	return out

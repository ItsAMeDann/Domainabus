extends Node

## Global game state manager, weapon telemetry tracker, dan AI data bridge

# -- Game State --
var current_wave:int = 0
var is_game_over:bool = false

# -- Weapon Usage Telemetry --
var weapon_telemetry:Dictionary = {
	"beta_lactam_shots": 0,
	"cipro_blast_shots": 0,
	"macrolide_pulse_shots": 0
}

# -- Survived Pathogen Data --
var survived_pathogens:Array = []

# -- Spawn Rate Config (tweakable oleh AI API) --
var default_spawn_config: Dictionary = {
	"bacteriophage": { "weight": 1.0, "interval": 3.0 },
	"spirillum":     { "weight": 0.5, "interval": 4.0 },
	"coccus":        { "weight": 0.3, "interval": 5.0 },
}
var spawn_config: Dictionary = default_spawn_config.duplicate(true)

# Record a weapon fire event for telemetry
func record_weapon_fire(weapon_id:String) -> void:
	if weapon_telemetry.has(weapon_id):
		weapon_telemetry[weapon_id] += 1


# Record an enemy's survival data when it dies
func record_pathogen_survival(data:Dictionary) -> void:
	survived_pathogens.append(data)


# Build the full AI request payload for the Python backend
func get_ai_payload() -> Dictionary:
	return {
		"wave_number": current_wave,
		"weapon_telemetry": weapon_telemetry.duplicate(),
		"survived_pathogens": survived_pathogens.duplicate(),
		"current_spawn_config": spawn_config.duplicate(true)
	}

# Apply new configuration from AI API
func apply_ai_config(config: Dictionary) -> void:
	if config.has("spawn_config"):
		var new_spawn_config = config["spawn_config"]
		for key in new_spawn_config:
			if spawn_config.has(key):
				spawn_config[key]["weight"] = new_spawn_config[key].get("weight", spawn_config[key]["weight"])
				spawn_config[key]["interval"] = new_spawn_config[key].get("interval", spawn_config[key]["interval"])

# Reset telemetry between waves
func reset_wave_telemetry() -> void:
	for key in weapon_telemetry:
		weapon_telemetry[key] = 0
	survived_pathogens.clear()


# Full game reset
func reset_game() -> void:
	current_wave = 0
	is_game_over = false
	spawn_config = default_spawn_config.duplicate(true)
	reset_wave_telemetry()

extends Node

## Global game state manager, weapon telemetry tracker, and AI data bridge

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
		"survived_pathogens": survived_pathogens.duplicate()
	}


# Reset telemetry between waves
func reset_wave_telemetry() -> void:
	for key in weapon_telemetry:
		weapon_telemetry[key] = 0
	survived_pathogens.clear()


# Full game reset
func reset_game() -> void:
	current_wave = 0
	is_game_over = false
	reset_wave_telemetry()

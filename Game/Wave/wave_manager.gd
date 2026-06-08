extends Node

signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal wave_timer_tick(time_left: float)
signal enemies_count_changed(count: int)
signal inter_wave_countdown(time_left: float) ## Signal baru untuk countdown antar wave

const BACTERIOPHAGE_SCENE := preload("res://Game/Enemy/bacteriophage.tscn")
const COCCUS_SCENE := preload("res://Game/Enemy/coccus.tscn")
const SPIRILLUM_SCENE := preload("res://Game/Enemy/spirillum.tscn")

var current_wave: int = 0
var enemies_alive: int = 0
var is_between_waves: bool = false
var wave_duration: float = 30.0

@export var inter_wave_delay: float = 5.0 ## Durasi jeda antar wave (detik)

@onready var inter_wave_timer: Timer = $WaveTimer

var wave_duration_timer: Timer
var spawn_tick_timer: Timer

# To keep track of the last time we spawned each type
var last_spawn_times: Dictionary = {
	"bacteriophage": 0.0,
	"spirillum": 0.0,
	"coccus": 0.0
}

# Evolved population template pool received from the AI backend
var current_wave_pathogens: Array = []
var is_waiting_for_input: bool = false

func _ready() -> void:
	add_to_group("wave_manager")
	
	if inter_wave_timer:
		inter_wave_timer.wait_time = inter_wave_delay
		inter_wave_timer.timeout.connect(_on_inter_wave_timer_timeout)
		
	wave_duration_timer = Timer.new()
	wave_duration_timer.one_shot = true
	wave_duration_timer.timeout.connect(_on_wave_duration_timeout)
	add_child(wave_duration_timer)
	
	spawn_tick_timer = Timer.new()
	spawn_tick_timer.wait_time = 0.5
	spawn_tick_timer.timeout.connect(_on_spawn_tick)
	add_child(spawn_tick_timer)

	# Connect network manager callbacks
	NetworkManager.ai_prediction_received.connect(_on_ai_prediction_received)
	print("[WaveManager] Connected to NetworkManager.")

func _process(_delta: float) -> void:
	# Emit wave duration countdown
	if not wave_duration_timer.is_stopped():
		wave_timer_tick.emit(wave_duration_timer.time_left)
	
	# Emit inter-wave countdown ketika timer antar wave berjalan
	if inter_wave_timer and not inter_wave_timer.is_stopped():
		inter_wave_countdown.emit(inter_wave_timer.time_left)

func start_game() -> void:
	is_between_waves = false
	current_wave = 0
	enemies_alive = 0
	Global.reset_game()
	start_next_wave()

func start_next_wave() -> void:
	is_between_waves = false
	current_wave += 1
	Global.current_wave = current_wave
	
	# Reset countdown display
	inter_wave_countdown.emit(0.0)
	
	wave_started.emit(current_wave)
	
	# Reset spawn trackers
	var current_time = Time.get_ticks_msec() / 1000.0
	for key in last_spawn_times:
		last_spawn_times[key] = current_time
	
	# Calculate duration: 30s base, +3s per wave, cap at 90s
	wave_duration = min(30.0 + (current_wave - 1) * 3.0, 90.0)
	wave_duration_timer.start(wave_duration)
	spawn_tick_timer.start()
	
	# Initial spawn burst
	_spawn_enemies_from_config(3 + current_wave)

func _on_spawn_tick() -> void:
	if Global.is_game_over:
		return
	_spawn_enemies_from_config(1)

func _spawn_enemies_from_config(base_amount: int) -> void:
	# If we have an evolved population pool from AI, draw from it first
	var current_time = Time.get_ticks_msec() / 1000.0
	var config = Global.spawn_config
	if not current_wave_pathogens.is_empty():
		for type in config.keys():
			var type_config = config[type]
			var interval: float = type_config.get("interval", 3.0)
			var weight: float = type_config.get("weight", 1.0)

			# Check if it's time to spawn this type
			if current_time - last_spawn_times[type] >= interval:
				last_spawn_times[type] = current_time

				# Determine amount based on weight and base_amount
				var amount = int(base_amount * weight)
				if randf() < fmod(base_amount * weight, 1.0):
					amount += 1

				for i in range(amount):
					var template: Dictionary = current_wave_pathogens.pick_random()
					var pathogen_type: String = template.get("class_type", "bacteriophage").to_lower()
					var genes: Dictionary = template.get("genes", {}).duplicate()

					var scene: PackedScene = null
					match pathogen_type:
						"bacteriophage":
							scene = BACTERIOPHAGE_SCENE
						"spirillum":
							scene = SPIRILLUM_SCENE
						"coccus":
							scene = COCCUS_SCENE
						_:
							scene = BACTERIOPHAGE_SCENE

					var spawn_pos := _get_random_edge_position()
					_spawn_single_enemy(scene, spawn_pos, genes)

					print(
						"[WaveManager] Evolved AI enemy spawned. ",
						"Config Type: ", type,
						", Actual Type: ", pathogen_type,
						", Genes: ", genes
					)
		return
	# Fallback to default procedural spawning if AI pool is empty
	var resistance_base: float = clamp((current_wave - 1) * 0.05, 0.0, 0.7)
	
	for type in config.keys():
		var type_config = config[type]
		var interval: float = type_config.get("interval", 3.0)
		var weight: float = type_config.get("weight", 1.0)
		
		# Check if it's time to spawn this type
		if current_time - last_spawn_times[type] >= interval:
			last_spawn_times[type] = current_time
			
			# Determine amount based on weight and base_amount
			# Add random chance to spawn extra based on weight remainder
			var amount = int(base_amount * weight)
			if randf() < fmod(base_amount * weight, 1.0):
				amount += 1
				
			if amount > 0:
				_spawn_type(type, amount, resistance_base)

func _spawn_type(type: String, amount: int, resistance_base: float) -> void:
	var scene: PackedScene
	var genes: Dictionary = {}
	
	match type:
		"bacteriophage":
			scene = BACTERIOPHAGE_SCENE
			genes = {
				"res_beta_lactam": resistance_base + randf() * 0.1,
				"res_cipro": resistance_base * 0.5 + randf() * 0.1,
				"res_macrolide": resistance_base * 0.3 + randf() * 0.1
			}
		"spirillum":
			if current_wave < 2: return # Introduce later
			scene = SPIRILLUM_SCENE
			genes = {
				"res_beta_lactam": resistance_base * 0.2 + randf() * 0.1,
				"res_cipro": resistance_base * 0.3 + randf() * 0.1,
				"res_macrolide": resistance_base + randf() * 0.1
			}
		"coccus":
			if current_wave < 3: return # Introduce later
			scene = COCCUS_SCENE
			genes = {
				"res_beta_lactam": resistance_base * 0.4 + randf() * 0.1,
				"res_cipro": resistance_base + randf() * 0.1,
				"res_macrolide": resistance_base * 0.4 + randf() * 0.1
			}
		_:
			return
			
	for i in range(amount):
		var spawn_pos := _get_random_edge_position()
		_spawn_single_enemy(scene, spawn_pos, genes)

func _get_random_edge_position() -> Vector2:
	var width := 1920.0
	var height := 1080.0
	var edge_offset := 80.0
	
	var side := randi() % 4
	var pos := Vector2.ZERO
	
	match side:
		0: # Top (inside)
			pos.x = randf_range(edge_offset, width - edge_offset)
			pos.y = edge_offset
		1: # Bottom (inside)
			pos.x = randf_range(edge_offset, width - edge_offset)
			pos.y = height - edge_offset
		2: # Left (inside)
			pos.x = edge_offset
			pos.y = randf_range(edge_offset, height - edge_offset)
		3: # Right (inside)
			pos.x = width - edge_offset
			pos.y = randf_range(edge_offset, height - edge_offset)
			
	return pos

func _spawn_single_enemy(scene: PackedScene, pos: Vector2, genes: Dictionary) -> void:
	if not scene:
		return
		
	var enemy := scene.instantiate() as CharacterBody2D
	enemy.global_position = pos
	
	if enemy.has_method("set_genes"):
		enemy.set_genes(genes)
		
	var container := get_tree().get_first_node_in_group("enemy_container")
	if container:
		container.add_child(enemy)
	else:
		get_tree().current_scene.add_child(enemy)
		
	enemy.tree_exited.connect(_on_enemy_died)
	
	enemies_alive += 1
	enemies_count_changed.emit(enemies_alive)

func _on_enemy_died() -> void:
	if Global.is_game_over:
		return
	enemies_alive = max(0, enemies_alive - 1)
	enemies_count_changed.emit(enemies_alive)
	
	if is_between_waves and enemies_alive <= 0:
		call_deferred("_on_all_enemies_dead")

func _on_wave_duration_timeout() -> void:
	if Global.is_game_over:
		return
	spawn_tick_timer.stop()
	is_between_waves = true
	wave_timer_tick.emit(0.0)
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("_on_died"):
				enemy._on_died()
			else:
				enemy.queue_free()
	
	if enemies_alive <= 0:
		call_deferred("_on_all_enemies_dead")

func _on_all_enemies_dead() -> void:
	if not is_inside_tree() or Global.is_game_over:
		return
		
	wave_ended.emit(current_wave)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		var health = player.get_node("HealthComponent")
		if health.has_method("heal_full"):
			health.heal_full()
			
	var payload := Global.get_ai_payload()
	var json_string = JSON.stringify(payload, "\t")
	print("=== WAVE ENDED: FULL AI TELEMETRY PAYLOAD ===\n", json_string)
	
	# Map payload to the keys expected by app.py
	var mapped_payload := {
		"wave_number": payload.get("wave_number", 1),
		"weapon_telemetry": {
			"beta_lactam_shots": payload.get("weapon_telemetry", {}).get("beta_lactam_shots", 0),
			"macrolide_pulse_shots": payload.get("weapon_telemetry", {}).get("macrolide_pulse_shots", 0),
			"cipro_blast_shots": payload.get("weapon_telemetry", {}).get("cipro_blast_shots", 0)
		},
		"survived_pathogens": [],
		"default_spawn_config": Global.default_spawn_config,
		"min_spawn_config": Global.min_spawn_config
	}
	
	for pathogen in payload.get("survived_pathogens", []):
		mapped_payload["survived_pathogens"].append({
			"class_type": pathogen.get("class_type", ""),
			"survival_time": pathogen.get("survival_time", 0.0),
			"damage_dealt": pathogen.get("damage_dealt", 0.0),
			"genes": pathogen.get("genes", {}).duplicate()
		})
		
	# Trigger the HTTP request asynchronously via NetworkManager
	print("[WaveManager] Transmitting wave data to Flask backend...")
	NetworkManager.send_telemetry(mapped_payload)
	
	Global.reset_wave_telemetry()

func _on_inter_wave_timer_timeout() -> void:
	# Inter-wave timer is unused under input-based progression, but kept as a signal callback fallback
	start_next_wave()

func _on_ai_prediction_received(success: bool, response_data: Dictionary) -> void:
	if Global.is_game_over:
		return

	var avg_beta := 0.0
	var avg_macro := 0.0
	var avg_cipro := 0.0
	var counts := {"bacteriophage": 0, "spirillum": 0, "coccus": 0}
	var dominant_type := "bacteriophage"

	if success:
		print("[WaveManager] HTTP Success: Received evolved pathogen population.")
		current_wave_pathogens = response_data.get("pathogen_population", [])
		print("[WaveManager] Pathogen population pool loaded: ", current_wave_pathogens.size(), " templates.")
		
		if response_data.has("spawn_config"):
			Global.spawn_config = response_data.get("spawn_config")
			print("[WaveManager] Global spawn configurations updated via AI: ", Global.spawn_config)
		if response_data.has("dominant_threat"):
			dominant_type = response_data.get("dominant_threat")
			print("[WaveManager] Dominant threat is now: ", dominant_type)
		
		if not current_wave_pathogens.is_empty():
			for p in current_wave_pathogens:
				var genes = p.get("genes", {})
				avg_beta += genes.get("res_beta_lactam", 0.0)
				avg_macro += genes.get("res_macrolide", 0.0)
				avg_cipro += genes.get("res_cipro", 0.0)
				
				var type: String = p.get("class_type", "bacteriophage").to_lower()
				counts[type] = counts.get(type, 0) + 1
				
			var n := current_wave_pathogens.size()
			avg_beta = (avg_beta / n) * 100.0
			avg_macro = (avg_macro / n) * 100.0
			avg_cipro = (avg_cipro / n) * 100.0
	else:
		print("[WaveManager] HTTP Failed: Using procedural spawning fallback.")
		current_wave_pathogens.clear()
		avg_beta = clamp(current_wave * 5.0, 0.0, 75.0)
		avg_macro = clamp(current_wave * 3.5, 0.0, 75.0)
		avg_cipro = clamp(current_wave * 2.0, 0.0, 75.0)
		counts["bacteriophage"] = 5
	
	# UI Representation
	var stats_text := "WAVE %d CLEARED!\n\n" % current_wave
	stats_text += "Evolved Bacterial Resistance Stats:\n"
	stats_text += "• Beta-lactam Res: %.0f%%\n" % avg_beta
	stats_text += "• Macrolide Res: %.0f%%\n" % avg_macro
	stats_text += "• Cipro Res: %.0f%%\n\n" % avg_cipro
	stats_text += "Dominant Threat: %s\n\n" % dominant_type.capitalize()
	stats_text += "Press [SPACE] or [ENTER] to start Wave %d" % (current_wave + 1)

	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_inter_wave_stats"):
		hud.show_inter_wave_stats(stats_text)
	
	is_waiting_for_input = true

func _unhandled_input(event: InputEvent) -> void:
	if Global.is_game_over:
		return
		
	if is_waiting_for_input:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_SPACE):
			is_waiting_for_input = false
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_node("Control/Center/InterWaveLabel"):
				hud.get_node("Control/Center/InterWaveLabel").visible = false
			start_next_wave()

extends Node

signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal wave_timer_tick(time_left: float)
signal enemies_count_changed(count: int)

const BACTERIOPHAGE_SCENE := preload("res://Game/Enemy/bacteriophage.tscn")
const COCCUS_SCENE := preload("res://Game/Enemy/coccus.tscn")
const SPIRILLUM_SCENE := preload("res://Game/Enemy/spirillum.tscn")

var current_wave: int = 0
var enemies_alive: int = 0
var is_between_waves: bool = false
var wave_duration: float = 30.0

@onready var inter_wave_timer: Timer = $WaveTimer

var wave_duration_timer: Timer
var spawn_tick_timer: Timer

# To keep track of the last time we spawned each type
var last_spawn_times: Dictionary = {
	"bacteriophage": 0.0,
	"spirillum": 0.0,
	"coccus": 0.0
}

func _ready() -> void:
	add_to_group("wave_manager")
	
	if inter_wave_timer:
		inter_wave_timer.timeout.connect(_on_inter_wave_timer_timeout)
		
	wave_duration_timer = Timer.new()
	wave_duration_timer.one_shot = true
	wave_duration_timer.timeout.connect(_on_wave_duration_timeout)
	add_child(wave_duration_timer)
	
	spawn_tick_timer = Timer.new()
	spawn_tick_timer.wait_time = 0.5
	spawn_tick_timer.timeout.connect(_on_spawn_tick)
	add_child(spawn_tick_timer)

func _process(_delta: float) -> void:
	if not wave_duration_timer.is_stopped():
		wave_timer_tick.emit(wave_duration_timer.time_left)

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
	_spawn_enemies_from_config(1)

func _spawn_enemies_from_config(base_amount: int) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var config = Global.spawn_config
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
	enemies_alive = max(0, enemies_alive - 1)
	enemies_count_changed.emit(enemies_alive)
	
	if is_between_waves and enemies_alive <= 0:
		call_deferred("_on_all_enemies_dead")

func _on_wave_duration_timeout() -> void:
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
	if not is_inside_tree():
		return
		
	wave_ended.emit(current_wave)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		var health = player.get_node("HealthComponent")
		if health.has_method("heal_full"):
			health.heal_full()
			
	var payload = Global.get_ai_payload()
	var best_fitness: float = -1.0
	var best_pathogen: Dictionary = {}
	
	for pathogen in payload.survived_pathogens:
		var fitness = pathogen.survival_time + (pathogen.damage_dealt * 5.0)
		if fitness > best_fitness:
			best_fitness = fitness
			best_pathogen = pathogen
			
	if not best_pathogen.is_empty():
		print("Mengirimkan (ship) AI dengan fitness stats tertinggi: ", best_pathogen)
		# TODO: Integrate with backend using this best pathogen
	
	Global.reset_wave_telemetry()
	
	if inter_wave_timer:
		inter_wave_timer.start()

func _on_inter_wave_timer_timeout() -> void:
	start_next_wave()

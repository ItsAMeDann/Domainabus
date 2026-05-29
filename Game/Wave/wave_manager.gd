extends Node

signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal enemies_count_changed(count: int)

const BACTERIOPHAGE_SCENE := preload("res://Game/Enemy/bacteriophage.tscn")
const COCCUS_SCENE := preload("res://Game/Enemy/coccus.tscn")
const SPIRILLUM_SCENE := preload("res://Game/Enemy/spirillum.tscn")

var current_wave: int = 0
var enemies_alive: int = 0
var is_between_waves: bool = false

@onready var wave_timer: Timer = $WaveTimer

func _ready() -> void:
	add_to_group("wave_manager")
	if wave_timer:
		wave_timer.timeout.connect(_on_wave_timer_timeout)

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
	
	var composition := _generate_wave_composition(current_wave)
	_spawn_enemies(composition)

func _generate_wave_composition(wave_num: int) -> Array[Dictionary]:
	var composition: Array[Dictionary] = []
	var total_count := 3 + wave_num * 2
	
	var bacteriophage_count :int= 0
	var spirillum_count :int= 0
	var coccus_count :int= 0
	
	if wave_num <= 2:
		bacteriophage_count = total_count
	elif wave_num <= 4:
		spirillum_count = randi() % (wave_num) + 1
		bacteriophage_count = total_count - spirillum_count
	else:
		coccus_count = randi() % (wave_num - 3) + 1
		spirillum_count = randi() % (wave_num - 2) + 1
		bacteriophage_count = max(0, total_count - spirillum_count - coccus_count)
	
	var resistance_base :float= clamp((wave_num - 1) * 0.05, 0.0, 0.7)
	
	if bacteriophage_count > 0:
		composition.append({
			"scene": BACTERIOPHAGE_SCENE,
			"count": bacteriophage_count,
			"genes": {
				"res_beta_lactam": resistance_base + randf() * 0.1,
				"res_cipro": resistance_base * 0.5 + randf() * 0.1,
				"res_macrolide": resistance_base * 0.3 + randf() * 0.1
			}
		})
		
	if spirillum_count > 0:
		composition.append({
			"scene": SPIRILLUM_SCENE,
			"count": spirillum_count,
			"genes": {
				"res_beta_lactam": resistance_base * 0.2 + randf() * 0.1,
				"res_cipro": resistance_base * 0.3 + randf() * 0.1,
				"res_macrolide": resistance_base + randf() * 0.1
			}
		})
		
	if coccus_count > 0:
		composition.append({
			"scene": COCCUS_SCENE,
			"count": coccus_count,
			"genes": {
				"res_beta_lactam": resistance_base * 0.4 + randf() * 0.1,
				"res_cipro": resistance_base + randf() * 0.1,
				"res_macrolide": resistance_base * 0.4 + randf() * 0.1
			}
		})
		
	return composition

func _spawn_enemies(composition: Array[Dictionary]) -> void:
	for item in composition:
		var scene: PackedScene = item["scene"]
		var count: int = item["count"]
		var genes: Dictionary = item["genes"]
		
		for i in range(count):
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
	if is_between_waves:
		return
		
	enemies_alive = max(0, enemies_alive - 1)
	enemies_count_changed.emit(enemies_alive)
	
	if enemies_alive <= 0:
		call_deferred("_on_all_enemies_dead")

func _on_all_enemies_dead() -> void:
	if not is_inside_tree():
		return
	is_between_waves = true
	wave_ended.emit(current_wave)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		var health = player.get_node("HealthComponent")
		if health.has_method("heal_full"):
			health.heal_full()
			
	# TODO: Send payload to Python server and fetch next-generation wave composition
	# var payload = Global.get_ai_payload()
	# var http_request = HTTPRequest.new()
	# ... (Integrate here when backend is connected)
	
	Global.reset_wave_telemetry()
	
	if wave_timer:
		wave_timer.start()

func _on_wave_timer_timeout() -> void:
	start_next_wave()

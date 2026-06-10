extends CharacterBody2D
class_name EnemyBase

@export var base_speed: float = 80.0
@export var contact_damage: float = 8.0

var class_type: String = "Bacteriophage"
var genes: Dictionary = {
	"res_beta_lactam": 0.0,
	"res_cipro": 0.0,
	"res_macrolide": 0.0
}
var spawn_time_ms: float = 0.0
var damage_dealt: float = 0.0
var player_ref: Node2D = null

var knockback_velocity: Vector2 = Vector2.ZERO
var base_color: Color = Color.WHITE

@onready var health_component: Node = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D

var walk_particles: CPUParticles2D

var tween_scale: Tween
var tween_flash: Tween
var base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	add_to_group("enemy")
	player_ref = get_tree().get_first_node_in_group("player")
	spawn_time_ms = Time.get_ticks_msec()
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	if health_component and not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)
		
	_setup_walk_particles()
	_update_visuals()
	if sprite:
		base_color = sprite.modulate
		base_scale = sprite.scale

func _setup_walk_particles() -> void:
	walk_particles = CPUParticles2D.new()
	walk_particles.emitting = false
	walk_particles.amount = 4
	walk_particles.lifetime = 0.4
	walk_particles.gravity = Vector2(0, -50)
	walk_particles.initial_velocity_min = 10
	walk_particles.initial_velocity_max = 20
	walk_particles.scale_amount_min = 2.0
	walk_particles.scale_amount_max = 5.0
	walk_particles.color = Color(0.8, 0.8, 0.8, 0.5)
	var radius:float = find_child("CollisionShape2D").shape.radius
	walk_particles.position = Vector2(-radius, 0)
	add_child(walk_particles)

func _physics_process(delta: float) -> void:
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
		
	var is_stunned = false
	# Apply Knockback Decay
	if knockback_velocity.length() > 5.0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, delta * 8.0)
		if knockback_velocity.length() > 50.0:
			is_stunned = true # Stunned if knockback is strong
	else:
		knockback_velocity = Vector2.ZERO
		
	if player_ref:
		if not is_stunned:
			chase_player(delta)
			look_at(player_ref.global_position)
		else:
			# If stunned, slow down the velocity drastically (friction)
			velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
			
		# Add knockback
		velocity += knockback_velocity
		move_and_slide()
		
		if walk_particles:
			walk_particles.emitting = velocity.length() > 10.0 and not is_stunned

func chase_player(delta: float) -> void:
	var direction := (player_ref.global_position - global_position).normalized()
	velocity = direction * base_speed * (delta * 60)

func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction * force

func take_weapon_damage(base_damage: float, weapon_type: String) -> void:
	var gene_key := "res_" + weapon_type
	var resistance: float = genes.get(gene_key, 0.0)
	resistance = clamp(resistance, 0.0, 0.95)
	
	var final_damage := base_damage * (1.0 - resistance)
	
	# Spawn damage number
	var dmg_num = preload("res://Game/Component/damage_number.gd").new()
	dmg_num.amount = final_damage
	dmg_num.weapon_type = weapon_type
	dmg_num.global_position = global_position + (Vector2(randf(), randf()) * 30)
	get_tree().current_scene.add_child(dmg_num)
	
	_play_hit_effects()
	
	if health_component:
		health_component.take_damage(final_damage)

func _play_hit_effects() -> void:
	AudioManager.play_sfx("enemy_hit")
	if not sprite: return
	
	# Hit Flash (longer if knocked back)
	if tween_flash and tween_flash.is_valid():
		tween_flash.kill()
	tween_flash = create_tween()
	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0) # Ultra white
	tween_flash.tween_property(sprite, "modulate", base_color, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Squash & Stretch (Bug Fix: use base_scale and kill previous tween)
	if tween_scale and tween_scale.is_valid():
		tween_scale.kill()
		
	var target_squash = Vector2(base_scale.x * 1.4, base_scale.y * 0.6)
	
	tween_scale = create_tween()
	tween_scale.tween_property(sprite, "scale", target_squash, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_scale.tween_property(sprite, "scale", base_scale, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# JUICE: Hitstop — freeze sesaat untuk kesan serangan berat
	HitstopManager.apply_hitstop(0.06)

func _spawn_death_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.explosiveness = 0.8
	particles.lifetime = 0.5
	particles.spread = 180.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.color = base_color
	
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)
	
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()

func _on_died() -> void:
	AudioManager.play_sfx("enemy_death")
	_spawn_death_particles()
	
	var data := {
		"class_type": class_type,
		"survival_time": get_survival_time_seconds(),
		"damage_dealt": damage_dealt,
		"genes": genes.duplicate()
	}
	Global.record_pathogen_survival(data)
	queue_free()

func _update_visuals() -> void:
	if not sprite:
		return
		
	var max_res :float= 0.0
	for res in genes.values():
		max_res = max(max_res, res)
		
	if max_res > 0.7:
		var factor :float= clamp((max_res - 0.7) / 0.25, 0.0, 1.0)
		sprite.modulate = Color(1.0, 1.0 - factor * 0.7, 1.0 - factor * 0.7, 1.0)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func get_survival_time_seconds() -> float:
	return (Time.get_ticks_msec() - spawn_time_ms) / 1000.0

func set_genes(new_genes: Dictionary) -> void:
	for key in new_genes:
		if key in genes:
			genes[key] = new_genes[key]
	_update_visuals()
	if sprite:
		base_color = sprite.modulate

extends CharacterBody2D

enum PlayerState { WALKING, FIRING, DEAD }

signal player_hurt ## Signal untuk HUD — trigger hurt vignette

@export var max_speed: float = 300.0

var current_state: PlayerState = PlayerState.WALKING

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_mount: Marker2D = $WeaponMount
@onready var weapon_manager: Node = $WeaponMount/WeaponManager
@onready var health_component: Node = $HealthComponent

var i_frame_timer: Timer
var walk_particles: CPUParticles2D

var knockback_velocity: Vector2 = Vector2.ZERO
var camera: Camera2D
var shake_intensity: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
	add_to_group("player")
	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)
	
	i_frame_timer = Timer.new()
	i_frame_timer.wait_time = 0.25
	i_frame_timer.one_shot = true
	add_child(i_frame_timer)
	
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1920
	camera.limit_bottom = 1080
	add_child(camera)
	
	_setup_walk_particles()

func _setup_walk_particles() -> void:
	walk_particles = CPUParticles2D.new()
	walk_particles.emitting = false
	walk_particles.amount = 6
	walk_particles.lifetime = 0.4
	walk_particles.gravity = Vector2(0, -50)
	walk_particles.initial_velocity_min = 15
	walk_particles.initial_velocity_max = 30
	walk_particles.scale_amount_min = 2.0
	walk_particles.scale_amount_max = 6.0
	walk_particles.color = Color(0.8, 0.8, 0.8, 0.6)
	walk_particles.position = Vector2(0, 15)
	add_child(walk_particles)

func apply_knockback(force: float, dir: Vector2) -> void:
	knockback_velocity = dir * force

func apply_camera_shake(intensity: float) -> void:
	shake_intensity = max(shake_intensity, intensity)

func _physics_process(delta: float) -> void:
	if current_state == PlayerState.DEAD:
		return
		
	# Camera shake logic
	if shake_intensity > 0:
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * shake_intensity
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
		if shake_intensity < 1.0:
			shake_intensity = 0.0
			camera.offset = Vector2.ZERO
			
	# Knockback decay
	if knockback_velocity.length() > 5.0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, delta * 15.0)
	else:
		knockback_velocity = Vector2.ZERO

	# Handle aiming
	var mouse_pos := get_global_mouse_position()
	weapon_mount.look_at(mouse_pos)
	
	# Flip sprite depending on mouse position relative to player
	var is_looking_left := mouse_pos.x < global_position.x
	sprite.flip_h = is_looking_left
	
	# Flip weapon vertically to prevent it from looking upside down when aiming left
	if weapon_manager and weapon_manager.current_weapon:
		if is_looking_left:
			weapon_manager.current_weapon.scale.y = -1.0
			weapon_mount.position.x = -abs(weapon_mount.position.x)
		else:
			weapon_manager.current_weapon.scale.y = 1.0
			weapon_mount.position.x = abs(weapon_mount.position.x)

	# Handle movement input
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if direction.length_squared() > 0.0:
		direction = direction.normalized()

	# Determine speed modifier (holding weapon = 0.7x, firing = 0.3x)
	var speed_multiplier := 0.7
	
	# Handle firing input and state transitions
	if Input.is_action_pressed("fire"):
		current_state = PlayerState.FIRING
		weapon_manager.fire()
	else:
		if current_state == PlayerState.FIRING:
			current_state = PlayerState.WALKING

	if current_state == PlayerState.FIRING:
		speed_multiplier = 0.3

	velocity = direction * max_speed * speed_multiplier * (delta * 100)
	velocity += knockback_velocity
	move_and_slide()
	
	if walk_particles:
		walk_particles.emitting = velocity.length() > 10.0

func _unhandled_input(event: InputEvent) -> void:
	if current_state == PlayerState.DEAD:
		return

	# Switch weapon input
	if event.is_action_pressed("switch_weapon"):
		weapon_manager.switch_weapon()

func take_damage(amount: float) -> void:
	## Dipanggil saat player menerima damage. Termasuk sistem juice lengkap.
	if current_state == PlayerState.DEAD:
		return
	if i_frame_timer and not i_frame_timer.is_stopped():
		return
	health_component.take_damage(amount)

	# -- JUICE: Hitstop --
	HitstopManager.apply_hitstop(0.08)

	# -- JUICE: Camera Shake (lebih intens dari biasa) --
	apply_camera_shake(8.0)

	# -- JUICE: Signal ke HUD untuk Hurt Vignette --
	player_hurt.emit()

	# -- JUICE: I-Frame Blinking --
	_blink_sprite()

	if i_frame_timer:
		i_frame_timer.start()

func _blink_sprite() -> void:
	## Kedipkan sprite selama durasi i-frame sebagai indikasi invulnerability
	var blink_count := 5
	for i in range(blink_count):
		sprite.modulate.a = 0.2
		# Timer process_always=true agar tidak terpengaruh hitstop
		await get_tree().create_timer(0.025, true, false, true).timeout
		sprite.modulate.a = 1.0
		await get_tree().create_timer(0.025, true, false, true).timeout
	# Pastikan sprite kembali normal
	sprite.modulate.a = 1.0

func _on_enemy_detector_body_entered(body: Node2D) -> void:
	if current_state == PlayerState.DEAD:
		return
	if body.is_in_group("enemy"):
		var damage: float = body.get("contact_damage") if "contact_damage" in body else 8.0
		take_damage(damage)
		if "damage_dealt" in body:
			body.damage_dealt += damage

func _on_died() -> void:
	if current_state == PlayerState.DEAD:
		return
	current_state = PlayerState.DEAD
	Global.is_game_over = true
	set_physics_process(false)
	set_process_unhandled_input(false)
	modulate = Color(0.3, 0.3, 0.3, 1.0)
	
	# Pause everything else in the scene tree
	get_tree().paused = true
	print("[Player] Player died. Game paused.")

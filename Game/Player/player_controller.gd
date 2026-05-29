extends CharacterBody2D

enum PlayerState { WALKING, FIRING, DEAD }

@export var max_speed: float = 300.0

var current_state: PlayerState = PlayerState.WALKING

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_mount: Marker2D = $WeaponMount
@onready var weapon_manager: Node = $WeaponMount/WeaponManager
@onready var health_component: Node = $HealthComponent

var i_frame_timer: Timer

func _ready() -> void:
	add_to_group("player")
	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)
	
	i_frame_timer = Timer.new()
	i_frame_timer.wait_time = 0.25
	i_frame_timer.one_shot = true
	add_child(i_frame_timer)

func _physics_process(delta: float) -> void:
	if current_state == PlayerState.DEAD:
		return

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
		else:
			weapon_manager.current_weapon.scale.y = 1.0

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
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if current_state == PlayerState.DEAD:
		return

	# Switch weapon input
	if event.is_action_pressed("switch_weapon"):
		weapon_manager.switch_weapon()

func take_damage(amount: float) -> void:
	if i_frame_timer and not i_frame_timer.is_stopped():
		return
	health_component.take_damage(amount)
	if i_frame_timer:
		i_frame_timer.start()

func _on_enemy_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		var damage: float = body.get("contact_damage") if "contact_damage" in body else 8.0
		take_damage(damage)
		if "damage_dealt" in body:
			body.damage_dealt += damage

func _on_died() -> void:
	current_state = PlayerState.DEAD
	Global.is_game_over = true
	set_physics_process(false)
	set_process_unhandled_input(false)
	modulate = Color(0.3, 0.3, 0.3, 1.0)

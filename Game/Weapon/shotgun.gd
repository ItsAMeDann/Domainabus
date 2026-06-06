extends Node2D

const WEAPON_ID: String = "macrolide_pulse_shots"
const WEAPON_NAME: String = "Shotgun"
const BULLET_SCENE: PackedScene = preload("res://Game/Bullet/bullet.tscn")
const WEAPON_ICON: Texture2D = preload("res://Asset/Placeholder/shotgun.png")

@export var bullet_damage: float = 12.0
@export var bullet_speed: float = 700.0
@export var cooldown: float = 0.5
@export var knockback_force: float = 150.0

@onready var muzzle: Marker2D = $Muzzle

func fire() -> void:
	var container := get_tree().get_first_node_in_group("bullet_container")
	var base_rotation := global_rotation
	
	for i in range(8):
		var bullet := BULLET_SCENE.instantiate() as Area2D
		bullet.global_position = muzzle.global_position
		
		# Distribute spread from -20 to +20 degrees (8 bullets, 7 gaps)
		var angle_offset_deg := -20.0 + (i * (40.0 / 7.0))
		var angle_offset_rad := deg_to_rad(angle_offset_deg)
		bullet.direction = Vector2.RIGHT.rotated(base_rotation + angle_offset_rad)
		bullet.speed = bullet_speed
		bullet.damage = bullet_damage
		bullet.weapon_type = "macrolide"
		bullet.knockback_force = knockback_force
		
		if container:
			container.add_child(bullet)
		else:
			get_tree().current_scene.add_child(bullet)
			
	# Muzzle Flash
	var flash := Sprite2D.new()
	flash.texture = preload("res://icon.svg")
	flash.modulate = Color(1.0, 1.0, 0.5, 0.8)
	flash.scale = Vector2(0.2, 0.2)
	flash.rotation = randf() * TAU
	flash.global_position = muzzle.global_position
	get_tree().current_scene.add_child(flash)
	
	var tween := flash.create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(0.8, 0.8), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(flash.queue_free)
			
	# Player Knockback & Screen Shake
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("apply_knockback"):
			player.apply_knockback(50.0, Vector2.LEFT.rotated(global_rotation))
		if player.has_method("apply_camera_shake"):
			player.apply_camera_shake(15.0)
			
	Global.record_weapon_fire(WEAPON_ID)

func get_cooldown() -> float:
	return cooldown

func get_weapon_name() -> String:
	return WEAPON_NAME

func get_weapon_icon() -> Texture2D:
	return WEAPON_ICON

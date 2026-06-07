extends Node2D

const WEAPON_ID: String = "beta_lactam_shots"
const WEAPON_NAME: String = "Pistol"
const BULLET_SCENE: PackedScene = preload("res://Game/Bullet/bullet.tscn")
const WEAPON_ICON: Texture2D = preload("res://Asset/Placeholder/pistol.png")

@export var bullet_damage: float = 20.0
@export var bullet_speed: float = 800.0
@export var cooldown: float = 0.15

@onready var muzzle: Marker2D = $Muzzle

func fire() -> void:
	AudioManager.play_sfx("gun")
	var bullet := BULLET_SCENE.instantiate() as Area2D
	bullet.global_position = muzzle.global_position
	bullet.direction = Vector2.RIGHT.rotated(global_rotation)
	bullet.speed = bullet_speed
	bullet.damage = bullet_damage
	bullet.weapon_type = "beta_lactam"
	bullet.knockback_force = 60.0 # Memberikan sedikit knockback dan stun
	
	var container := get_tree().get_first_node_in_group("bullet_container")
	if container:
		container.add_child(bullet)
	else:
		# Fallback to scene tree root if container group not found
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
		
	Global.record_weapon_fire(WEAPON_ID)

func get_cooldown() -> float:
	return cooldown

func get_weapon_name() -> String:
	return WEAPON_NAME

func get_weapon_icon() -> Texture2D:
	return WEAPON_ICON

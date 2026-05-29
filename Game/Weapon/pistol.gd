extends Node2D

const WEAPON_ID: String = "beta_lactam_shots"
const WEAPON_NAME: String = "Pistol"
const BULLET_SCENE: PackedScene = preload("res://Game/Bullet/bullet.tscn")

@export var bullet_damage: float = 20.0
@export var bullet_speed: float = 800.0
@export var cooldown: float = 0.15

@onready var muzzle: Marker2D = $Muzzle

func fire() -> void:
	var bullet := BULLET_SCENE.instantiate() as Area2D
	bullet.global_position = muzzle.global_position
	bullet.direction = Vector2.RIGHT.rotated(global_rotation)
	bullet.speed = bullet_speed
	bullet.damage = bullet_damage
	bullet.weapon_type = "beta_lactam"
	
	var container := get_tree().get_first_node_in_group("bullet_container")
	if container:
		container.add_child(bullet)
	else:
		# Fallback to scene tree root if container group not found
		get_tree().current_scene.add_child(bullet)
		
	Global.record_weapon_fire(WEAPON_ID)

func get_cooldown() -> float:
	return cooldown

func get_weapon_name() -> String:
	return WEAPON_NAME

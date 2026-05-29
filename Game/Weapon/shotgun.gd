extends Node2D

const WEAPON_ID: String = "macrolide_pulse_shots"
const WEAPON_NAME: String = "Shotgun"
const BULLET_SCENE: PackedScene = preload("res://Game/Bullet/bullet.tscn")

@export var bullet_damage: float = 12.0
@export var bullet_speed: float = 700.0
@export var cooldown: float = 0.5

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
		
		if container:
			container.add_child(bullet)
		else:
			get_tree().current_scene.add_child(bullet)
			
	Global.record_weapon_fire(WEAPON_ID)

func get_cooldown() -> float:
	return cooldown

func get_weapon_name() -> String:
	return WEAPON_NAME

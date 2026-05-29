extends Node2D

const WEAPON_ID: String = "cipro_blast_shots"
const WEAPON_NAME: String = "Grenade Launcher"
const GRENADE_SCENE: PackedScene = preload("res://Game/Bullet/grenade.tscn")

@export var bullet_damage: float = 50.0
@export var bullet_speed: float = 400.0
@export var cooldown: float = 0.8

@onready var muzzle: Marker2D = $Muzzle

func fire() -> void:
	var grenade := GRENADE_SCENE.instantiate() as Area2D
	grenade.global_position = muzzle.global_position
	grenade.direction = Vector2.RIGHT.rotated(global_rotation)
	grenade.speed = bullet_speed
	grenade.damage = bullet_damage
	grenade.weapon_type = "cipro"
	
	var container := get_tree().get_first_node_in_group("bullet_container")
	if container:
		container.add_child(grenade)
	else:
		get_tree().current_scene.add_child(grenade)
		
	Global.record_weapon_fire(WEAPON_ID)

func get_cooldown() -> float:
	return cooldown

func get_weapon_name() -> String:
	return WEAPON_NAME

extends Node2D

const WEAPON_ID: String = "cipro_blast_shots"
const WEAPON_NAME: String = "Grenade Launcher"
const GRENADE_SCENE: PackedScene = preload("res://Game/Bullet/grenade.tscn")
const WEAPON_ICON: Texture2D = preload("res://Asset/Placeholder/grenade_launcher.png")

@export var bullet_damage: float = 50.0
@export var bullet_speed: float = 400.0
@export var cooldown: float = 0.8

@onready var muzzle: Marker2D = $Muzzle

func fire() -> void:
	AudioManager.play_sfx("launch")
	var grenade := GRENADE_SCENE.instantiate() as Area2D
	grenade.global_position = muzzle.global_position
	grenade.direction = Vector2.RIGHT.rotated(global_rotation)
	grenade.speed = bullet_speed
	grenade.damage = bullet_damage
	grenade.weapon_type = "cipro"
	# Knockback force is handled by explosion.gd for grenade
	
	var container := get_tree().get_first_node_in_group("bullet_container")
	if container:
		container.add_child(grenade)
	else:
		get_tree().current_scene.add_child(grenade)
		
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
			player.apply_knockback(30.0, Vector2.LEFT.rotated(global_rotation))
		if player.has_method("apply_camera_shake"):
			player.apply_camera_shake(10.0)
		
	Global.record_weapon_fire(WEAPON_ID)

func get_cooldown() -> float:
	return cooldown

func get_weapon_name() -> String:
	return WEAPON_NAME

func get_weapon_icon() -> Texture2D:
	return WEAPON_ICON

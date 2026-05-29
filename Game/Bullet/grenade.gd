extends Area2D

@export var speed: float = 400.0
@export var damage: float = 50.0
@export var weapon_type: String = "cipro"
var direction: Vector2 = Vector2.RIGHT

const EXPLOSION_SCENE: PackedScene = preload("res://Game/Bullet/explosion.tscn")

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") or body.is_in_group("wall"):
		_explode()

func _on_fuse_timer_timeout() -> void:
	_explode()

func _explode() -> void:
	var explosion := EXPLOSION_SCENE.instantiate() as Area2D
	explosion.global_position = global_position
	explosion.damage = damage
	explosion.weapon_type = weapon_type
	
	var container := get_tree().get_first_node_in_group("bullet_container")
	if container:
		container.add_child.call_deferred(explosion)
	else:
		get_tree().current_scene.add_child.call_deferred(explosion)
		
	queue_free()

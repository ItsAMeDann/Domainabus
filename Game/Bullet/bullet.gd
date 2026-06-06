extends Area2D

@export var speed: float = 800.0
@export var damage: float = 20.0
@export var weapon_type: String = ""
var direction: Vector2 = Vector2.RIGHT
var knockback_force: float = 0.0

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_weapon_damage"):
			body.take_weapon_damage(damage, weapon_type)
		if knockback_force > 0.0 and body.has_method("apply_knockback"):
			body.apply_knockback(direction, knockback_force)
		queue_free()
	elif body.is_in_group("wall"):
		queue_free()

func _on_lifetime_timer_timeout() -> void:
	queue_free()

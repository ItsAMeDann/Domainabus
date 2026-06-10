extends Area2D

@export var damage: float = 50.0
@export var weapon_type: String = "cipro"

func _ready() -> void:
	_play_explosion_animation()

func _play_explosion_animation() -> void:
	pass

func _on_duration_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_weapon_damage"):
			body.take_weapon_damage(damage, weapon_type)
		if body.has_method("apply_knockback"):
			var push_dir = (body.global_position - global_position).normalized()
			body.apply_knockback(push_dir, 300.0)

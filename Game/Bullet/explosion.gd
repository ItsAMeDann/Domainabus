extends Area2D

@export var damage: float = 50.0
@export var weapon_type: String = "cipro"

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_play_explosion_animation()

func _play_explosion_animation() -> void:
	if not sprite:
		return
		
	sprite.scale = Vector2.ZERO
	sprite.modulate = Color(1.0, 0.8, 0.2, 0.8)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(3.0, 3.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func _on_duration_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_weapon_damage"):
			body.take_weapon_damage(damage, weapon_type)
		if body.has_method("apply_knockback"):
			var push_dir = (body.global_position - global_position).normalized()
			body.apply_knockback(push_dir, 300.0)

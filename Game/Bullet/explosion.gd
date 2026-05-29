extends Area2D

@export var damage: float = 50.0
@export var weapon_type: String = "cipro"

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	call_deferred("_apply_damage")
	_play_explosion_animation()

func _apply_damage() -> void:
	var bodies := get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("take_weapon_damage"):
			body.take_weapon_damage(damage, weapon_type)

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

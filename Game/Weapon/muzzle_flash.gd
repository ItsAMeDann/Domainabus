extends Sprite2D
class_name MuzzleFlash

func _ready() -> void:
	texture = preload("res://icon.svg") # Fallback since we don't have a specific flash texture
	modulate = Color(1.0, 1.0, 0.5, 0.8) # Yellowish
	scale = Vector2(0.2, 0.2)
	
	# Random rotation
	rotation = randf() * TAU
	
	# Animate flash
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

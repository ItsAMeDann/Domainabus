extends Node2D
class_name DamageNumber

var amount: float = 0.0
var weapon_type: String = ""

func _ready() -> void:
	var label := Label.new()
	label.text = str(round(amount))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	match weapon_type:
		"beta_lactam":
			label.modulate = Color(0.2, 0.6, 1.0)
		"cipro":
			label.modulate = Color(1.0, 0.3, 0.1)
		"macrolide":
			label.modulate = Color(0.8, 0.2, 0.8)
		_:
			label.modulate = Color.WHITE
			
	# Center the label
	label.position = Vector2(-30, -15)
	label.custom_minimum_size = Vector2(60, 30)
	
	add_child(label)
	
	var tween := create_tween().set_parallel(true)
	# Float up
	tween.tween_property(self, "position:y", position.y - 40.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.2).set_trans(Tween.TRANS_LINEAR)
	
	tween.chain().tween_callback(queue_free)

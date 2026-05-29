extends EnemyBase

func _ready() -> void:
	class_type = "Bacteriophage"
	base_speed = 80.0
	contact_damage = 8.0
	super._ready()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
		damage_dealt += contact_damage

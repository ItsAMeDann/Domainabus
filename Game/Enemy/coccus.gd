extends EnemyBase

func _ready() -> void:
	class_type = "Coccus"
	base_speed = 50.0
	contact_damage = 15.0
	super._ready()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
		damage_dealt += contact_damage

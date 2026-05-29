extends EnemyBase

var zigzag_time: float = 0.0
var zigzag_amplitude: float = 100.0
var zigzag_frequency: float = 6.0

func _ready() -> void:
	class_type = "Spirillum"
	base_speed = 180.0
	contact_damage = 10.0
	super._ready()

func chase_player(delta: float) -> void:
	var direction := (player_ref.global_position - global_position).normalized()
	var perpendicular := Vector2(-direction.y, direction.x)
	
	zigzag_time += delta
	var sin_offset := sin(zigzag_time * zigzag_frequency) * zigzag_amplitude
	velocity = (direction * base_speed) + (perpendicular * sin_offset)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(contact_damage)
		damage_dealt += contact_damage

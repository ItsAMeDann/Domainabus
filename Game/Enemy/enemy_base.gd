extends CharacterBody2D
class_name EnemyBase

@export var base_speed: float = 80.0
@export var contact_damage: float = 8.0

var class_type: String = "Bacteriophage"
var genes: Dictionary = {
	"res_beta_lactam": 0.0,
	"res_cipro": 0.0,
	"res_macrolide": 0.0
}
var spawn_time_ms: float = 0.0
var damage_dealt: float = 0.0
var player_ref: Node2D = null

@onready var health_component: Node = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemy")
	player_ref = get_tree().get_first_node_in_group("player")
	spawn_time_ms = Time.get_ticks_msec()
	
	if health_component and not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)
		
	_update_visuals()

func _physics_process(delta: float) -> void:
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
		
	if player_ref:
		chase_player(delta)
		look_at(player_ref.global_position)
		move_and_slide()

func chase_player(delta: float) -> void:
	var direction := (player_ref.global_position - global_position).normalized()
	velocity = direction * base_speed * (delta * 60)

func take_weapon_damage(base_damage: float, weapon_type: String) -> void:
	var gene_key := "res_" + weapon_type
	var resistance: float = genes.get(gene_key, 0.0)
	resistance = clamp(resistance, 0.0, 0.95)
	
	var final_damage := base_damage * (1.0 - resistance)
	if health_component:
		health_component.take_damage(final_damage)

func _on_died() -> void:
	var data := {
		"class_type": class_type,
		"survival_time": get_survival_time_seconds(),
		"damage_dealt": damage_dealt,
		"genes": genes.duplicate()
	}
	Global.record_pathogen_survival(data)
	queue_free()

func _update_visuals() -> void:
	if not sprite:
		return
		
	var max_res :float= 0.0
	for res in genes.values():
		max_res = max(max_res, res)
		
	if max_res > 0.7:
		var factor :float= clamp((max_res - 0.7) / 0.25, 0.0, 1.0)
		sprite.modulate = Color(1.0, 1.0 - factor * 0.7, 1.0 - factor * 0.7, 1.0)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func get_survival_time_seconds() -> float:
	return (Time.get_ticks_msec() - spawn_time_ms) / 1000.0

func set_genes(new_genes: Dictionary) -> void:
	for key in new_genes:
		if key in genes:
			genes[key] = new_genes[key]
	_update_visuals()

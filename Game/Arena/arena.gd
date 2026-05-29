extends Node2D

@onready var wave_manager: Node = $WaveManager

func _ready() -> void:
	$EnemyContainer.add_to_group("enemy_container")
	$BulletContainer.add_to_group("bullet_container")
	
	if wave_manager:
		wave_manager.start_game()

func _unhandled_input(event: InputEvent) -> void:
	if Global.is_game_over:
		if event.is_action_pressed("fire") or event.is_action_pressed("switch_weapon"):
			Global.reset_game()
			get_tree().reload_current_scene()

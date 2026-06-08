extends Node2D

@onready var wave_manager: Node = $WaveManager

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$EnemyContainer.add_to_group("enemy_container")
	$BulletContainer.add_to_group("bullet_container")
	
	if wave_manager:
		wave_manager.start_game()
		AudioManager.play_bgm_gameplay()

func _unhandled_input(event: InputEvent) -> void:
	if Global.is_game_over:
		# Jika game over, abaikan action pause
		if event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
			return
			
		if event.is_action_pressed("fire") or event.is_action_pressed("switch_weapon"):
			get_tree().paused = false
			Global.reset_game()
			get_tree().reload_current_scene()

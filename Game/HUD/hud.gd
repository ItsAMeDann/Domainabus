extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/TopLeft/HealthBar
@onready var wave_label: Label = $Control/TopCenter/WaveLabel
@onready var timer_label: Label = $Control/TopCenter/TimerLabel
@onready var enemy_count_label: Label = $Control/TopRight/EnemyCountLabel
@onready var weapon_label: Label = $Control/BottomLeft/WeaponLabel
@onready var weapon_icon: TextureRect = $Control/BottomLeft/WeaponIcon
@onready var wave_banner: Label = $Control/Center/WaveBanner

func _ready() -> void:
	if wave_banner:
		wave_banner.visible = false
		wave_banner.modulate.a = 0.0

	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var health = player.get_node_or_null("HealthComponent")
		if health:
			health.health_changed.connect(_on_player_health_changed)
			health.died.connect(_on_player_died)
			update_health(health.current_health, health.max_health)
			
		var weapon_manager = player.get_node_or_null("WeaponMount/WeaponManager")
		if weapon_manager:
			weapon_manager.weapon_switched.connect(_on_weapon_switched)
			if weapon_manager.current_weapon:
				update_weapon(weapon_manager.current_weapon.get_weapon_name(), weapon_manager.current_weapon.get_weapon_icon() if weapon_manager.current_weapon.has_method("get_weapon_icon") else null)
	
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if not wave_manager:
		wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
		
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_ended.connect(_on_wave_ended)
		wave_manager.wave_timer_tick.connect(_on_wave_timer_tick)
		wave_manager.enemies_count_changed.connect(_on_enemies_count_changed)
		update_wave(wave_manager.current_wave)
		update_enemy_count(wave_manager.enemies_alive)

func update_wave(wave_num: int) -> void:
	if wave_label:
		wave_label.text = "Wave: " + str(wave_num)

func update_enemy_count(count: int) -> void:
	if enemy_count_label:
		enemy_count_label.text = "Enemies Left: " + str(count)

func update_health(current: float, max_val: float) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

func update_weapon(weapon_name: String, icon: Texture2D) -> void:
	if weapon_label:
		weapon_label.text = "Weapon: " + weapon_name
	if weapon_icon:
		weapon_icon.texture = icon

func show_wave_banner(wave_num: int) -> void:
	if not wave_banner:
		return
	
	wave_banner.text = "WAVE " + str(wave_num)
	wave_banner.visible = true
	wave_banner.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(wave_banner, "modulate:a", 1.0, 0.4)
	tween.tween_interval(0.7)
	tween.tween_property(wave_banner, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): wave_banner.visible = false)

func _on_player_health_changed(new_health: float, max_health: float) -> void:
	update_health(new_health, max_health)

func _on_weapon_switched(weapon_name: String, _weapon_index: int, icon: Texture2D = null) -> void:
	update_weapon(weapon_name, icon)

func _on_wave_started(wave_num: int) -> void:
	update_wave(wave_num)
	show_wave_banner(wave_num)

func _on_wave_ended(_wave_num: int) -> void:
	pass

func _on_wave_timer_tick(time_left: float) -> void:
	if timer_label:
		var mins = int(time_left) / 60.0
		var secs = int(time_left) % 60
		timer_label.text = "Time: %02d:%02d" % [mins, secs]

func _on_enemies_count_changed(count: int) -> void:
	update_enemy_count(count)

func _on_player_died() -> void:
	var game_over_panel = $Control/GameOverPanel
	if game_over_panel:
		var final_wave_label = $Control/GameOverPanel/CenterContainer/VBoxContainer/FinalWaveLabel
		if final_wave_label:
			final_wave_label.text = "Final Wave Reached: " + str(Global.current_wave)
		game_over_panel.visible = true
		game_over_panel.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.5)

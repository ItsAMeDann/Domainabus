extends Control
## Main Menu — Titik masuk utama game Domainabus
## Menyediakan navigasi: Play, Settings, Credits, Quit

@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var main_buttons: VBoxContainer = $CenterContainer/MainButtons

# -- Slider References (di-set saat _ready) --
var master_slider: HSlider
var bgm_slider: HSlider
var sfx_slider: HSlider
var mute_button: Button

func _ready() -> void:
	# Pastikan tree tidak dalam keadaan pause
	get_tree().paused = false
	Engine.time_scale = 1.0

	# Sembunyikan panel overlay
	if settings_panel:
		settings_panel.visible = false
	if credits_panel:
		credits_panel.visible = false

	# Hubungkan tombol utama
	$CenterContainer/MainButtons/PlayButton.pressed.connect(_on_play_pressed)
	$CenterContainer/MainButtons/SettingsButton.pressed.connect(_on_settings_pressed)
	$CenterContainer/MainButtons/CreditsButton.pressed.connect(_on_credits_pressed)
	$CenterContainer/MainButtons/QuitButton.pressed.connect(_on_quit_pressed)

	# Hubungkan tombol settings
	_setup_settings_panel()

	# Hubungkan tombol credits
	$CreditsPanel/MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_credits_back)

	# Mainkan BGM menu
	AudioManager.play_bgm_main_menu()

	# Animasi masuk
	_animate_entrance()

func _setup_settings_panel() -> void:
	# Ambil referensi slider
	var settings_vbox = $SettingsPanel/MarginContainer/VBoxContainer
	master_slider = settings_vbox.get_node("MasterRow/MasterSlider")
	bgm_slider = settings_vbox.get_node("BGMRow/BGMSlider")
	sfx_slider = settings_vbox.get_node("SFXRow/SFXSlider")
	mute_button = settings_vbox.get_node("MuteButton")
	var back_button = settings_vbox.get_node("BackButton")

	# Set nilai awal dari AudioManager
	master_slider.value = AudioManager.get_master_volume()
	bgm_slider.value = AudioManager.get_bgm_volume()
	sfx_slider.value = AudioManager.get_sfx_volume()
	_update_mute_button_text()

	# Hubungkan signal slider
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	mute_button.pressed.connect(_on_mute_pressed)
	back_button.pressed.connect(_on_settings_back)

func _animate_entrance() -> void:
	# Fade in seluruh menu
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Animasi fade-in tombol satu per satu tanpa mengubah posisi
	for i in range(main_buttons.get_child_count()):
		var btn = main_buttons.get_child(i)
		btn.modulate.a = 0.0
		var btn_tween := create_tween()
		btn_tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(0.1 + i * 0.1)

# -- Navigasi --

func _on_play_pressed() -> void:
	AudioManager.play_sfx("change")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		get_tree().change_scene_to_file.call_deferred("res://Game/Arena/arena.tscn")
	)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("change")
	# Refresh slider values
	master_slider.value = AudioManager.get_master_volume()
	bgm_slider.value = AudioManager.get_bgm_volume()
	sfx_slider.value = AudioManager.get_sfx_volume()
	_update_mute_button_text()
	settings_panel.visible = true
	main_buttons.visible = false

func _on_credits_pressed() -> void:
	AudioManager.play_sfx("change")
	credits_panel.visible = true
	main_buttons.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_back() -> void:
	AudioManager.play_sfx("change")
	settings_panel.visible = false
	main_buttons.visible = true

func _on_credits_back() -> void:
	AudioManager.play_sfx("change")
	credits_panel.visible = false
	main_buttons.visible = true

# -- Volume Control --

func _on_master_volume_changed(value: float) -> void:
	AudioManager.set_master_volume(value)

func _on_bgm_volume_changed(value: float) -> void:
	AudioManager.set_bgm_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)

func _on_mute_pressed() -> void:
	AudioManager.toggle_mute()
	_update_mute_button_text()

func _update_mute_button_text() -> void:
	if mute_button:
		mute_button.text = "🔇 UNMUTE" if AudioManager.is_muted else "🔊 MUTE"

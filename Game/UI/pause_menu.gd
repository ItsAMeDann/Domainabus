extends CanvasLayer
## Pause Menu — Overlay yang muncul saat game di-pause (Escape)
## process_mode = ALWAYS agar tetap merespon input saat tree di-pause

var is_paused: bool = false

@onready var overlay: ColorRect = $Overlay
@onready var menu_container: CenterContainer = $Overlay/CenterContainer
@onready var settings_panel: PanelContainer = $Overlay/SettingsPanel

# -- Slider References --
var master_slider: HSlider
var bgm_slider: HSlider
var sfx_slider: HSlider
var mute_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	if settings_panel:
		settings_panel.visible = false

	# Hubungkan tombol menu
	var vbox = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer
	vbox.get_node("ResumeButton").pressed.connect(_on_resume_pressed)
	vbox.get_node("SettingsButton").pressed.connect(_on_settings_pressed)
	vbox.get_node("MainMenuButton").pressed.connect(_on_main_menu_pressed)

	# Setup settings panel
	_setup_settings_panel()

func _setup_settings_panel() -> void:
	var settings_vbox = $Overlay/SettingsPanel/MarginContainer/VBoxContainer
	master_slider = settings_vbox.get_node("MasterRow/MasterSlider")
	bgm_slider = settings_vbox.get_node("BGMRow/BGMSlider")
	sfx_slider = settings_vbox.get_node("SFXRow/SFXSlider")
	mute_button = settings_vbox.get_node("MuteButton")
	var back_button = settings_vbox.get_node("BackButton")

	# Set nilai awal
	master_slider.value = AudioManager.get_master_volume()
	bgm_slider.value = AudioManager.get_bgm_volume()
	sfx_slider.value = AudioManager.get_sfx_volume()
	_update_mute_button_text()

	# Hubungkan signal
	master_slider.value_changed.connect(_on_master_volume_changed)
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	mute_button.pressed.connect(_on_mute_pressed)
	back_button.pressed.connect(_on_settings_back)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if Global.is_game_over:
			return
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	if is_paused:
		_resume()
	else:
		_pause()

func _pause() -> void:
	is_paused = true
	get_tree().paused = true
	overlay.visible = true
	menu_container.visible = true
	settings_panel.visible = false

	# Animasi fade in
	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.15)

func _resume() -> void:
	is_paused = false
	get_tree().paused = false
	overlay.visible = false
	settings_panel.visible = false

# -- Button Callbacks --

func _on_resume_pressed() -> void:
	AudioManager.play_sfx("change")
	_resume()

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("change")
	# Refresh slider values
	master_slider.value = AudioManager.get_master_volume()
	bgm_slider.value = AudioManager.get_bgm_volume()
	sfx_slider.value = AudioManager.get_sfx_volume()
	_update_mute_button_text()
	settings_panel.visible = true
	menu_container.visible = false

func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("change")
	_resume()
	Global.reset_game()
	get_tree().change_scene_to_file("res://Game/UI/main_menu.tscn")

func _on_settings_back() -> void:
	AudioManager.play_sfx("change")
	settings_panel.visible = false
	menu_container.visible = true

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

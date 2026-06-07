extends Node
## Audio Manager — Singleton untuk kontrol audio game
## Mengelola BGM, SFX, volume per-bus, dan mute toggle

@onready var master_index: int = AudioServer.get_bus_index("Master")
@onready var bgm_index: int = AudioServer.get_bus_index("BGM")
@onready var sfx_index: int = AudioServer.get_bus_index("SFX")

var audio_root: Node
var is_muted := false

# Simpan volume sebelum mute agar bisa dikembalikan
var _saved_volumes: Dictionary = {
	"master": 1.0,
	"bgm": 1.0,
	"sfx": 1.0
}

func _ready():
	audio_root = self
	if master_index == -1:
		push_error("Master bus not found!")
		return
	if bgm_index == -1:
		push_error("BGM bus not found! Pastikan default_bus_layout.tres sudah benar.")
	if sfx_index == -1:
		push_error("SFX bus not found! Pastikan default_bus_layout.tres sudah benar.")

# -- Volume Control --

func set_master_volume(value: float) -> void:
	## Set volume Master bus (0.0 - 1.0, linear)
	value = clamp(value, 0.0, 1.0)
	_saved_volumes["master"] = value
	if master_index != -1:
		AudioServer.set_bus_volume_db(master_index, linear_to_db(value))

func set_bgm_volume(value: float) -> void:
	## Set volume BGM bus (0.0 - 1.0, linear)
	value = clamp(value, 0.0, 1.0)
	_saved_volumes["bgm"] = value
	if bgm_index != -1:
		AudioServer.set_bus_volume_db(bgm_index, linear_to_db(value))

func set_sfx_volume(value: float) -> void:
	## Set volume SFX bus (0.0 - 1.0, linear)
	value = clamp(value, 0.0, 1.0)
	_saved_volumes["sfx"] = value
	if sfx_index != -1:
		AudioServer.set_bus_volume_db(sfx_index, linear_to_db(value))

func get_master_volume() -> float:
	## Ambil volume Master bus saat ini (linear 0.0 - 1.0)
	if master_index == -1: return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(master_index))

func get_bgm_volume() -> float:
	## Ambil volume BGM bus saat ini (linear 0.0 - 1.0)
	if bgm_index == -1: return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(bgm_index))

func get_sfx_volume() -> float:
	## Ambil volume SFX bus saat ini (linear 0.0 - 1.0)
	if sfx_index == -1: return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(sfx_index))

# -- Mute Control --

func toggle_mute() -> void:
	## Toggle mute/unmute pada Master bus
	if is_muted:
		unmute()
	else:
		mute()

func mute() -> void:
	## Mute semua audio via Master bus
	is_muted = true
	if master_index != -1:
		AudioServer.set_bus_mute(master_index, true)

func unmute() -> void:
	## Unmute semua audio, kembalikan volume sebelumnya
	is_muted = false
	if master_index != -1:
		AudioServer.set_bus_mute(master_index, false)

# -- BGM Playback --

func play_bgm_main_menu() -> void:
	var bgm_root = audio_root.get_child(0).find_child("menu") as AudioStreamPlayer
	if bgm_root:
		bgm_root.bus = "BGM"
		bgm_root.play()
	else:
		# Jika tidak ada BGM menu, langsung putar BGM gameplay
		play_bgm_gameplay()
		return
	await bgm_root.finished
	play_bgm_gameplay()

func play_bgm_gameplay() -> void:
	play_bgm_end()
	var bgm_root = audio_root.get_child(0).find_child("game") as AudioStreamPlayer
	if bgm_root:
		bgm_root.bus = "BGM"
		bgm_root.play()

func play_bgm_end() -> void:
	var bgm_container = audio_root.get_child(0)
	if bgm_container:
		for bgm in bgm_container.get_children():
			if bgm is AudioStreamPlayer:
				bgm.stop()

# -- SFX Playback --

func play_sfx(sfx_name: String, is_random: bool = false) -> void:
	var sfx_root: Node
	if audio_root:
		sfx_root = audio_root.get_child(1).find_child(sfx_name)
	if sfx_root:
		sfx_root.bus = "SFX"
		if is_random:
			sfx_root.pitch_scale = randf_range(0.9, 1.1)
		sfx_root.play()
	else:
		push_error(sfx_name, " is not found!")

func stop_all_sfx() -> void:
	for sfx in audio_root.get_child(1).get_children():
		sfx.stop()

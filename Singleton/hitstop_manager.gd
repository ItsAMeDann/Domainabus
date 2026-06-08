extends Node
## Hitstop Manager — Singleton untuk efek time-freeze sesaat
## Memberikan kesan "berat" pada setiap serangan yang mengenai target.
## Dipanggil global: HitstopManager.apply_hitstop(0.08)

var _is_active: bool = false

func apply_hitstop(duration: float = 0.08) -> void:
	if _is_active:
		# Jika sudah aktif, abaikan agar tidak bertumpuk
		return

	_is_active = true
	Engine.time_scale = 0.05

	# Timer yang process_always=true agar tidak terpengaruh time_scale
	await get_tree().create_timer(duration, true, false, true).timeout

	Engine.time_scale = 1.0
	_is_active = false

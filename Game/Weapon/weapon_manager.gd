extends Node

signal weapon_switched(weapon_name: String, weapon_index: int, icon: Texture2D)

const WEAPONS: Array[PackedScene] = [
	preload("res://Game/Weapon/pistol.tscn"),
	preload("res://Game/Weapon/shotgun.tscn"),
	preload("res://Game/Weapon/grenade_launcher.tscn")
]

var current_index: int = 0
var current_weapon: Node2D = null
var can_fire: bool = true
var cooldown_timer: Timer

func _ready() -> void:
	# Create and add a child timer to handle weapon fire cooldowns
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(cooldown_timer)
	
	# Equip the default weapon
	_equip_weapon(0)

func switch_weapon() -> void:
	var next_index := (current_index + 1) % WEAPONS.size()
	_equip_weapon(next_index)

func _equip_weapon(index: int) -> void:
	if current_weapon:
		current_weapon.queue_free()
		current_weapon = null
	
	current_index = index
	var weapon_scene := WEAPONS[index]
	var weapon_instance := weapon_scene.instantiate() as Node2D
	
	# Add the weapon as a child of WeaponMount (the parent of WeaponManager)
	get_parent().add_child.call_deferred(weapon_instance)
	current_weapon = weapon_instance
	
	# Reset firing ability on weapon switch
	can_fire = true
	cooldown_timer.stop()
	
	var weapon_name := "Pistol"
	var weapon_icon: Texture2D = null
	if current_weapon.has_method("get_weapon_name"):
		weapon_name = current_weapon.get_weapon_name()
	if current_weapon.has_method("get_weapon_icon"):
		weapon_icon = current_weapon.get_weapon_icon()
	
	weapon_switched.emit(weapon_name, current_index, weapon_icon)

func fire() -> void:
	if not can_fire or not current_weapon:
		return
		
	if current_weapon.has_method("fire"):
		current_weapon.fire()
		
		var cd := 0.0
		if current_weapon.has_method("get_cooldown"):
			cd = current_weapon.get_cooldown()
			
		if cd > 0.0:
			can_fire = false
			cooldown_timer.wait_time = cd
			cooldown_timer.start()

func _on_cooldown_timeout() -> void:
	can_fire = true

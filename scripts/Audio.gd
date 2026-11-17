extends Node

const SFX := {
	"ui_click": preload("res://assets/audio/sfx/ui_click.ogg"),
	"ui_confirm": preload("res://assets/audio/sfx/ui_confirm.ogg"),
	"ui_error": preload("res://assets/audio/sfx/ui_error.ogg"),
	"soul_pickup": preload("res://assets/audio/sfx/soul_pickup.wav"),
	"tower_shoot": preload("res://assets/audio/sfx/tower_shoot.wav"),
	"tower_hit": preload("res://assets/audio/sfx/tower_hit.wav"),
	"voidborn_death": preload("res://assets/audio/sfx/voidborn_death.wav"),
	"game_over": preload("res://assets/audio/sfx/game_over.ogg"),
}

func play(name: String) -> void:
	if Meta.sfx_muted or not SFX.has(name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = SFX[name]
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func vibrate(duration_ms: int = 50) -> void:
	if Meta.vibration_enabled:
		Input.vibrate_handheld(duration_ms)

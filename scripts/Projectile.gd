extends Node2D

const SPRITE := preload("res://assets/sprites/bullet.png")
const SPEED := 500.0
const HIT_DIST := 12.0

var damage: float = 0.0
var target: Node2D

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	var dir := (target.position - position).normalized()
	position += dir * SPEED * delta
	rotation = dir.angle()
	if position.distance_to(target.position) <= HIT_DIST:
		target.take_damage(damage)
		queue_free()

func _draw() -> void:
	draw_texture_rect(SPRITE, Rect2(-12, -4, 24, 8), false)

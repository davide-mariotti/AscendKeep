extends Node2D

const SPRITE := preload("res://assets/sprites/voidling.png")
const GLOW_COLOR := Color(0.4, 0.85, 0.95)
const BOSS_GLOW_COLOR := Color(0.75, 0.35, 0.9)
const BOSS_VISUAL_SCALE := 1.8

signal defeated

var hp: float = 10.0
var speed: float = 40.0
var damage: float = 2.0
var tower: Node2D
var attack_timer := 0.0
var dying := false
var is_boss := false
var boss_texture: Texture2D = null

func _ready() -> void:
	scale = Vector2(0.2, 0.2)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _process(delta: float) -> void:
	if dying or not is_instance_valid(tower):
		return
	var dir := (tower.position - position).normalized()
	var dist := position.distance_to(tower.position)
	var melee_range := 25.0 * (BOSS_VISUAL_SCALE if is_boss else 1.0)
	if dist > melee_range:
		position += dir * speed * delta
	else:
		attack_timer -= delta
		if attack_timer <= 0.0:
			attack_timer = 1.0
			tower.take_damage(damage)
			if tower.thorns > 0.0:
				take_damage(tower.thorns)

func take_damage(amount: float) -> void:
	if dying:
		return
	hp -= amount
	if hp <= 0:
		_die()

func _die() -> void:
	dying = true
	defeated.emit()
	Audio.play("voidborn_death")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free).set_delay(0.18)

func _draw() -> void:
	# Soft halo so the Voidborn keeps a readable silhouette against the
	# similarly dark, stony arena background. Bosses without a dedicated
	# sprite reuse the Voidborn art scaled up with a violet glow instead of
	# cyan (style bible: violet energy marks elite enemies).
	var glow := BOSS_GLOW_COLOR if is_boss else GLOW_COLOR
	var s := BOSS_VISUAL_SCALE if is_boss else 1.0
	draw_circle(Vector2.ZERO, 22.0 * s, Color(glow, 0.12))
	draw_circle(Vector2.ZERO, 15.0 * s, Color(glow, 0.18))
	if is_boss and boss_texture:
		var tex_size := boss_texture.get_size()
		var h := 32.0 * s
		var w := h * (tex_size.x / tex_size.y)
		draw_texture_rect(boss_texture, Rect2(-w * 0.5, -h * 0.5, w, h), false)
	else:
		draw_texture_rect(SPRITE, Rect2(-16.0 * s, -16.0 * s, 32.0 * s, 32.0 * s), false)

extends Node2D

signal died
signal damaged(amount: float)

const SPRITE := preload("res://assets/sprites/tower.png")
const RING_ROTATION_SPEED := 0.35
const RING_GAP_RADIANS := 0.4

const BASE_HP := 100.0
const BASE_DAMAGE := 5.0
const BASE_RANGE := 150.0
const BASE_ATTACK_INTERVAL := 0.5
const MIN_ATTACK_INTERVAL := 0.15
const BASE_CRIT_MULTIPLIER := 1.5

var max_hp: float
var hp: float
var damage: float
var atk_range: float
var attack_interval: float
var attack_timer := 0.0
var crit_chance: float
var crit_multiplier: float
var multishot_chance: float
var regen: float
var thorns: float
var defense_pct: float
var ring_angle := 0.0

# Every combat stat now sums three independent sources: Reconstruction
# (Meta.bonus_for, Souls, infinite levels), Skill tree (Meta.skill_bonus_for_stat,
# Skill Points, ~50 one-time nodes per branch) and Lab research
# (Meta.lab_bonus_for_stat, Souls, ~32 one-time nodes per category) — plus
# whichever named one-time Marketplace/Lab unlock applies to that stat.
func _ready() -> void:
	max_hp = (BASE_HP + Meta.bonus_for("hp") + Meta.skill_bonus_for_stat("hp") + Meta.lab_bonus_for_stat("hp") + Meta.one_time_bonus("resonant_shell")) * (1.0 + Meta.tier_perk_hp_bonus)
	hp = max_hp
	damage = (BASE_DAMAGE + Meta.bonus_for("damage") + Meta.skill_bonus_for_stat("damage") + Meta.lab_bonus_for_stat("damage") + Meta.one_time_bonus("overcharge_core")) * (1.0 + Meta.tier_perk_damage_bonus)
	atk_range = BASE_RANGE + Meta.bonus_for("range") + Meta.skill_bonus_for_stat("range") + Meta.lab_bonus_for_stat("range") + Meta.one_time_bonus("voidsight")
	attack_interval = max(MIN_ATTACK_INTERVAL, BASE_ATTACK_INTERVAL - Meta.bonus_for("haste") - Meta.skill_bonus_for_stat("haste") - Meta.lab_bonus_for_stat("haste") - Meta.one_time_bonus("quickening"))
	crit_chance = clamp(Meta.bonus_for("crit_chance") + Meta.skill_bonus_for_stat("crit_chance") + Meta.lab_bonus_for_stat("crit_chance"), 0.0, 1.0)
	crit_multiplier = BASE_CRIT_MULTIPLIER + Meta.bonus_for("crit_damage") + Meta.skill_bonus_for_stat("crit_damage") + Meta.lab_bonus_for_stat("crit_damage")
	multishot_chance = clamp(Meta.bonus_for("multishot") + Meta.skill_bonus_for_stat("multishot") + Meta.lab_bonus_for_stat("multishot"), 0.0, 1.0)
	regen = Meta.bonus_for("regen") + Meta.skill_bonus_for_stat("regen") + Meta.lab_bonus_for_stat("regen")
	thorns = Meta.bonus_for("thorns") + Meta.skill_bonus_for_stat("thorns") + Meta.lab_bonus_for_stat("thorns")
	defense_pct = clamp(Meta.skill_bonus_for_stat("defense_pct") + Meta.lab_bonus_for_stat("defense_pct"), 0.0, 0.85)
	queue_redraw()

func _process(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0.0:
		attack_timer = attack_interval
		_attack_nearest()
	if regen > 0.0 and hp < max_hp:
		hp = min(max_hp, hp + regen * delta)
	ring_angle = wrapf(ring_angle + delta * RING_ROTATION_SPEED, 0.0, TAU)
	queue_redraw()

func _attack_nearest() -> void:
	var enemies := get_parent().get_node("EnemiesContainer").get_children()
	var targets: Array[Node2D] = []
	for e: Node2D in enemies:
		if e.position.distance_to(position) <= atk_range:
			targets.append(e)
	if targets.is_empty():
		return
	targets.sort_custom(func(a: Node2D, b: Node2D): return a.position.distance_to(position) < b.position.distance_to(position))
	_fire_at(targets[0])
	if targets.size() > 1 and randf() < multishot_chance:
		_fire_at(targets[1])

func _fire_at(target: Node2D) -> void:
	var projectile = preload("res://scenes/Projectile.tscn").instantiate()
	projectile.position = position
	var shot_damage := damage
	if randf() < crit_chance:
		shot_damage *= crit_multiplier
	projectile.damage = shot_damage
	projectile.target = target
	get_parent().get_node("ProjectilesContainer").add_child(projectile)
	Audio.play("tower_shoot")

func take_damage(amount: float) -> void:
	var actual := amount * (1.0 - defense_pct)
	hp -= actual
	Audio.play("tower_hit")
	Audio.vibrate(30)
	damaged.emit(actual)
	if hp <= 0:
		hp = 0
		died.emit()

func _draw() -> void:
	# A rotating, slightly-open ring instead of a static full circle — the
	# gap makes the rotation actually readable, giving the battle scene a
	# small amount of constant ambient motion instead of a frozen HUD element.
	# Drawn as a soft wide glow plus a brighter core line — a single thin
	# 22%-alpha line was getting lost against the busy stone background.
	var start := ring_angle
	var end := ring_angle + TAU - RING_GAP_RADIANS
	# Ring color follows the purchased Core skin (default matches the
	# original hardcoded cyan) so a bought skin actually changes something visible.
	var skin_color := Meta.core_skin_color()
	draw_arc(Vector2.ZERO, atk_range, start, end, 48, Color(skin_color.r, skin_color.g, skin_color.b, 0.18), 10.0)
	draw_arc(Vector2.ZERO, atk_range, start, end, 48, Color(skin_color.r, skin_color.g, skin_color.b, 0.7), 3.0)
	draw_texture_rect(SPRITE, Rect2(-32, -32, 64, 64), false)

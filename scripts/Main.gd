extends Node2D

const BASE_SPAWN_INTERVAL := 2.0
const MIN_SPAWN_INTERVAL := 0.6
const WAVE_ENEMY_BASE := 3
# Enemy count per wave grows forever (3 + wave*2) with nothing to stop it —
# at high wave numbers (very reachable by grinding, e.g. at high time_scale
# while testing) this spawns thousands of enemies. If the tower can't kill
# them as fast as they spawn, they pile up with no limit: hundreds of live
# Node2Ds each running _process/_draw every frame, which is what actually
# crashes the game (out of memory / the renderer falling over), not a
# single bad frame. Both caps below are defense in depth: capping the wave
# total keeps spawn counts sane at high waves, capping alive count is a
# hard backstop regardless of wave number. Difficulty at high waves comes
# from HP/damage scaling (already unbounded), not from raw enemy count.
const MAX_WAVE_ENEMIES := 60
const MAX_ALIVE_ENEMIES := 40
const ARENA_RADIUS := 400.0
const HOME_SCENE := "res://scenes/Home.tscn"
const AUTO_RESTART_DELAY_SECONDS := 2.5

# A boss wave is a single much tougher enemy instead of a crowd — it stands
# in for the "boss every 10 waves" gauntlet structure until bespoke boss
# art/behavior exists. Speed scales gentler than HP/damage per tier so
# high-tier bosses stay hittable instead of just becoming unreactable.
const BOSS_HP_MULT := 12.0
const BOSS_DAMAGE_MULT := 2.5
const BOSS_SPEED_MULT := 0.7
const BOSS_SOULS_MULT := 5.0
const TIER_SPEED_GROWTH_PER_TIER := 0.05

# The only bespoke boss art that exists yet — used for every Tier 1 boss
# wave. Higher tiers fall back to the scaled, violet-tinted Voidborn until
# more boss sprites exist.
const TIER1_BOSS_SPRITE := preload("res://assets/sprites/boss-the-hollow-crown.png")

# Battle-scene "juice": smoothing/flash/shake constants. None of these
# affect gameplay numbers, only how alive the scene feels while playing.
const HP_BAR_SMOOTH_SPEED := 6.0
const HP_FLASH_COLOR := Color(1.7, 1.7, 1.7)
const HIT_SHAKE_STRENGTH := 4.0
const BOSS_SHAKE_STRENGTH := 10.0
const SHAKE_DECAY_PER_SEC := 30.0
const BOSS_BANNER_SECONDS := 1.8
const TOAST_SHOW_SECONDS := 2.6

var tier := 1
var wave := 1
var enemies_to_spawn := 0
var spawn_interval: float
var spawn_timer := 0.0
var game_over := false
var displayed_hp := 0.0
var shake_strength := 0.0
var toast_queue: Array = []
var toast_showing := false

var run_start_souls := 0
var run_souls_earned := 0
var voidborn_defeated := 0

@onready var camera = $Camera2D
@onready var tower = $Tower
@onready var enemies_container = $EnemiesContainer
@onready var wave_icon = $HUD/Root/TopBarPanel/TopBar/WaveBox/WaveIcon
@onready var wave_label = $HUD/Root/TopBarPanel/TopBar/WaveBox/WaveLabel
@onready var hp_bar = $HUD/Root/TopBarPanel/TopBar/HPBar
@onready var souls_label = $HUD/Root/TopBarPanel/TopBar/CoinsBox/CoinsLabel
@onready var souls_icon = $HUD/Root/TopBarPanel/TopBar/CoinsBox/CoinsIcon
@onready var boss_banner = $HUD/Root/BossBanner
@onready var unlock_toast = $HUD/Root/UnlockToast
@onready var unlock_toast_title = $HUD/Root/UnlockToast/VBox/TitleLabel
@onready var unlock_toast_desc = $HUD/Root/UnlockToast/VBox/DescLabel
@onready var game_over_panel = $HUD/Root/GameOverPanel
@onready var points_label = $HUD/Root/GameOverPanel/Card/Content/PointsLabel
@onready var return_button = $HUD/Root/GameOverPanel/Card/Content/ButtonsRow/ReturnButton
@onready var restart_button = $HUD/Root/GameOverPanel/Card/Content/ButtonsRow/RestartButton
@onready var auto_restart_label = $HUD/Root/GameOverPanel/Card/Content/AutoRestartLabel

func _ready() -> void:
	tier = Meta.current_tier
	tower.died.connect(_on_tower_died)
	tower.damaged.connect(_on_tower_damaged)
	Meta.progress_changed.connect(_on_souls_changed)
	Meta.notable_unlock.connect(_on_notable_unlock)
	return_button.pressed.connect(func(): get_tree().change_scene_to_file(HOME_SCENE))
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())

	spawn_interval = max(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL - Meta.one_time_bonus("swift_tides"))
	run_start_souls = Meta.souls
	displayed_hp = tower.hp
	_update_souls_label()
	_start_wave()

	# A per-instance copy of the HP fill style, pulsed continuously so the
	# bar always has some motion even when idle, instead of sitting frozen.
	var pulsing_fill: StyleBoxFlat = hp_bar.get_theme_stylebox("fill").duplicate()
	hp_bar.add_theme_stylebox_override("fill", pulsing_fill)
	var pulse := create_tween().set_loops()
	pulse.tween_property(pulsing_fill, "shadow_size", 7.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(pulsing_fill, "shadow_size", 2.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _is_boss_wave(w: int) -> bool:
	return w % Meta.BOSS_WAVE_INTERVAL == 0

func _start_wave() -> void:
	enemies_to_spawn = 1 if _is_boss_wave(wave) else min(WAVE_ENEMY_BASE + wave * 2, MAX_WAVE_ENEMIES)
	spawn_timer = 0.0
	var boss_wave := _is_boss_wave(wave)
	wave_label.text = "Tier %d · Wave %d%s" % [tier, wave, "  (Boss)" if boss_wave else ""]
	if boss_wave:
		_show_boss_banner()
	else:
		_pulse_wave_icon()

func _process(delta: float) -> void:
	if game_over:
		return
	hp_bar.max_value = tower.max_hp
	displayed_hp = lerp(displayed_hp, tower.hp, min(1.0, HP_BAR_SMOOTH_SPEED * delta))
	hp_bar.value = displayed_hp
	if shake_strength > 0.0:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
		shake_strength = max(0.0, shake_strength - SHAKE_DECAY_PER_SEC * delta)
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO
	if enemies_to_spawn > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0 and enemies_container.get_child_count() < MAX_ALIVE_ENEMIES:
			spawn_timer = spawn_interval
			_spawn_enemy()
			enemies_to_spawn -= 1
	elif enemies_container.get_child_count() == 0:
		var reward := _souls_reward_for_wave(wave)
		Meta.add_souls(reward)
		Meta.add_mission_progress("souls_earned", reward)
		Meta.report_wave_reached(tier, wave)
		wave += 1
		_start_wave()

func _souls_reward_for_wave(cleared_wave: int) -> int:
	var base_reward := 5 + cleared_wave * 3
	var gain_pct := Meta.bonus_for("souls_gain") + Meta.skill_bonus_for_stat("souls_gain") + Meta.lab_bonus_for_stat("souls_gain")
	var boosted := base_reward * (1.0 + gain_pct)
	boosted *= Meta.tier_reward_multiplier(tier)
	return int(round(boosted))

func _spawn_enemy() -> void:
	var enemy = preload("res://scenes/Enemy.tscn").instantiate()
	var angle := randf() * TAU
	enemy.position = tower.position + Vector2(cos(angle), sin(angle)) * ARENA_RADIUS
	var tier_mult := Meta.tier_difficulty_multiplier(tier)
	var speed_mult := 1.0 + TIER_SPEED_GROWTH_PER_TIER * (tier - 1)
	var boss := _is_boss_wave(wave)
	enemy.hp = (10.0 + wave * 4.0) * tier_mult * (BOSS_HP_MULT if boss else 1.0)
	enemy.speed = (40.0 + wave * 2.0) * speed_mult * (BOSS_SPEED_MULT if boss else 1.0)
	enemy.damage = (2.0 + wave) * tier_mult * (BOSS_DAMAGE_MULT if boss else 1.0)
	enemy.is_boss = boss
	if boss and tier == 1:
		enemy.boss_texture = TIER1_BOSS_SPRITE
	enemy.tower = tower
	enemy.defeated.connect(_on_voidborn_defeated.bind(boss))
	enemies_container.add_child(enemy)

func _on_voidborn_defeated(boss: bool = false) -> void:
	voidborn_defeated += 1
	Meta.add_mission_progress("voidborn", 1)
	if boss:
		var bonus := int(round(_souls_reward_for_wave(wave) * BOSS_SOULS_MULT))
		Meta.add_souls(bonus)
		Meta.add_mission_progress("souls_earned", bonus)
		Meta.add_skill_points(1)

func _on_tower_died() -> void:
	game_over = true
	run_souls_earned = Meta.souls - run_start_souls
	points_label.text = "Tier %d — Wave %d reached\nVoidborn defeated: %d\nSouls absorbed: %d\nSouls total: %d" % [
		tier, wave, voidborn_defeated, run_souls_earned, Meta.souls,
	]
	game_over_panel.visible = true
	Audio.play("game_over")
	Audio.vibrate(200)

	if Meta.real_purchases.auto_restart and Meta.auto_restart_enabled:
		auto_restart_label.visible = true
		await get_tree().create_timer(AUTO_RESTART_DELAY_SECONDS).timeout
		get_tree().reload_current_scene()

func _update_souls_label() -> void:
	souls_label.text = "%d" % (Meta.souls - run_start_souls)

func _on_souls_changed() -> void:
	_update_souls_label()
	if not game_over:
		_pulse_souls_icon()
		Audio.play("soul_pickup")

func _pulse_souls_icon() -> void:
	souls_icon.scale = Vector2(1.6, 1.6)
	create_tween().tween_property(souls_icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

func _pulse_wave_icon() -> void:
	wave_icon.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(wave_icon, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

func _shake(strength: float) -> void:
	shake_strength = max(shake_strength, strength)

func _on_tower_damaged(_amount: float) -> void:
	_shake(HIT_SHAKE_STRENGTH)
	hp_bar.modulate = HP_FLASH_COLOR
	create_tween().tween_property(hp_bar, "modulate", Color.WHITE, 0.25)

func _show_boss_banner() -> void:
	_shake(BOSS_SHAKE_STRENGTH)
	Audio.play("ui_error")
	boss_banner.visible = true
	boss_banner.modulate.a = 0.0
	boss_banner.scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(boss_banner, "modulate:a", 1.0, 0.2)
	tween.tween_property(boss_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_interval(BOSS_BANNER_SECONDS)
	tween.chain().tween_property(boss_banner, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(func(): boss_banner.visible = false)

func _on_notable_unlock(title: String, description: String) -> void:
	toast_queue.append([title, description])
	if not toast_showing:
		_show_next_toast()

func _show_next_toast() -> void:
	if toast_queue.is_empty():
		toast_showing = false
		return
	toast_showing = true
	var item: Array = toast_queue.pop_front()
	unlock_toast_title.text = item[0]
	unlock_toast_desc.text = item[1]
	unlock_toast.visible = true
	unlock_toast.modulate.a = 0.0
	Audio.play("ui_confirm")
	var tween := create_tween()
	tween.tween_property(unlock_toast, "modulate:a", 1.0, 0.25)
	tween.tween_interval(TOAST_SHOW_SECONDS)
	tween.tween_property(unlock_toast, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		unlock_toast.visible = false
		_show_next_toast()
	)

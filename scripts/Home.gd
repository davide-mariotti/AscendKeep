extends Control

const BATTLE_SCENE := "res://scenes/Main.tscn"
const RESET_CONFIRM_SECONDS := 3.0
# Crimson is reserved for danger/destructive states (see visual-style.json) —
# used here, and nowhere else, for the irreversible progress-reset confirm.
const DANGER_COLOR := Color(0.85, 0.25, 0.3, 1)
const MENU_ICON := preload("res://assets/icons/menu.svg")
const CLOSE_ICON := preload("res://assets/icons/close.svg")

const INTRO_LINES := [
	"The world was consumed by the Void.",
	"Only one living fortress remains.",
	"Ascend Keep remembers every fall.",
]
const INTRO_LINE_SECONDS := 2.2

const SPLASH_FRAMES_DIR := "res://assets/art/home_splash_frames/"
const SPLASH_FPS := 24.0

const SWIPE_THRESHOLD := 60.0

# Icons shared by every generated Skill-tree/Lab node for a given stat —
# there are far too many nodes (150 skills, ~100 researches) to each carry
# a bespoke icon, so nodes boosting the same stat share one.
const STAT_ICONS := {
	"damage": preload("res://assets/icons/damage.svg"),
	"crit_chance": preload("res://assets/icons/crit_chance.svg"),
	"crit_damage": preload("res://assets/icons/crit_damage.svg"),
	"multishot": preload("res://assets/icons/multishot.svg"),
	"range": preload("res://assets/icons/range.svg"),
	"haste": preload("res://assets/icons/haste.svg"),
	"defense_pct": preload("res://assets/icons/defense_pct.svg"),
	"thorns": preload("res://assets/icons/thorns.svg"),
	"hp": preload("res://assets/icons/hp.svg"),
	"regen": preload("res://assets/icons/regen.svg"),
	"souls_gain": preload("res://assets/icons/souls_gain.svg"),
}
const SECTION_HEADER_COLOR := Color(0.78, 0.63, 0.28)

var intro_index := 0
var reset_confirm_pending := false
var selected_tier := 1
var _swipe_start_x := 0.0
var skill_node_buttons := []
var lab_node_buttons := []

@onready var souls_label = $TopBarPanel/TopBar/SoulsBox/SoulsLabel
@onready var gems_label = $TopBarPanel/TopBar/GemsBox/GemsLabel
@onready var top_skill_points_label = $TopBarPanel/TopBar/SkillPointsBox/SkillPointsLabel
@onready var menu_button = $TopBarPanel/TopBar/MenuButton
@onready var menu_popup = $MenuPopup
@onready var reset_button = $MenuPopup/VBox/ResetButton
@onready var license_popup = $LicensePopup
@onready var settings_popup = $SettingsPopup
@onready var sfx_check = $SettingsPopup/VBox/SfxCheck
@onready var music_check = $SettingsPopup/VBox/MusicCheck
@onready var vibration_check = $SettingsPopup/VBox/VibrationCheck
@onready var auto_restart_check = $SettingsPopup/VBox/AutoRestartCheck
@onready var google_sign_in_button = $SettingsPopup/VBox/GoogleSignInButton

@onready var splash_background = $BattleSplashBackground
@onready var battle_panel = $TabContent/BattlePanel
@onready var battle_button = $TabContent/BattlePanel/BattleButton
@onready var tier_label = $TabContent/BattlePanel/TierRow/TierLabel
@onready var tier_left_button = $TabContent/BattlePanel/TierRow/TierLeftButton
@onready var tier_right_button = $TabContent/BattlePanel/TierRow/TierRightButton
@onready var hp_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/HpButton
@onready var dmg_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/DmgButton
@onready var range_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/RangeButton
@onready var haste_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/HasteButton
@onready var souls_gain_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/SoulsGainButton
@onready var crit_chance_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/CritChanceButton
@onready var crit_damage_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/CritDamageButton
@onready var multishot_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/MultishotButton
@onready var regen_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/RegenButton
@onready var thorns_button = $TabContent/UpgradesPanel/ScrollContainer/VBox/ThornsButton

@onready var skills_locked_label = $TabContent/SkillsPanel/ScrollContainer/VBox/LockedLabel
@onready var skill_points_row = $TabContent/SkillsPanel/ScrollContainer/VBox/SkillPointsRow
@onready var skill_points_label = $TabContent/SkillsPanel/ScrollContainer/VBox/SkillPointsRow/SkillPointsLabel
@onready var root_button = $TabContent/SkillsPanel/ScrollContainer/VBox/RootButton
@onready var tree_connector = $TabContent/SkillsPanel/ScrollContainer/VBox/TreeConnector
@onready var branches = $TabContent/SkillsPanel/ScrollContainer/VBox/Branches
@onready var branches_vbox = $TabContent/SkillsPanel/ScrollContainer/VBox/Branches/BranchesVBox

@onready var lab_locked_label = $TabContent/LabPanel/ScrollContainer/VBox/LockedLabel
@onready var swift_tides_button = $TabContent/LabPanel/ScrollContainer/VBox/SwiftTidesButton
@onready var overcharge_core_button = $TabContent/LabPanel/ScrollContainer/VBox/OverchargeCoreButton
@onready var resonant_shell_button = $TabContent/LabPanel/ScrollContainer/VBox/ResonantShellButton
@onready var voidsight_button = $TabContent/LabPanel/ScrollContainer/VBox/VoidsightButton
@onready var quickening_button = $TabContent/LabPanel/ScrollContainer/VBox/QuickeningButton
@onready var generated_research_vbox = $TabContent/LabPanel/ScrollContainer/VBox/GeneratedResearchVBox
@onready var lab_content_buttons := [
	swift_tides_button, overcharge_core_button, resonant_shell_button, voidsight_button, quickening_button,
	generated_research_vbox,
]

@onready var auto_restart_button = $TabContent/MarketplacePanel/VBox/AutoRestartButton
@onready var remove_ads_button = $TabContent/MarketplacePanel/VBox/RemoveAdsButton
@onready var skin_violet_button = $TabContent/MarketplacePanel/VBox/SkinVioletButton
@onready var skin_gold_button = $TabContent/MarketplacePanel/VBox/SkinGoldButton
@onready var milestone_pass_button = $TabContent/MarketplacePanel/VBox/MilestonePassButton
@onready var skillpoint_ad_button = $TabContent/MarketplacePanel/VBox/SkillPointAdButton
@onready var coin_ad_button = $TabContent/MarketplacePanel/VBox/CoinAdButton

@onready var missions_popup = $MissionsPopup
@onready var mission_buttons := [
	$MissionsPopup/VBox/Mission1Button,
	$MissionsPopup/VBox/Mission2Button,
	$MissionsPopup/VBox/Mission3Button,
]
@onready var reroll_button = $MissionsPopup/VBox/RerollButton

@onready var milestones_popup = $MilestonesPopup
@onready var milestone_buttons := [
	$MilestonesPopup/VBox/ScrollContainer/MilestonesVBox/Milestone5Button,
	$MilestonesPopup/VBox/ScrollContainer/MilestonesVBox/Milestone10Button,
	$MilestonesPopup/VBox/ScrollContainer/MilestonesVBox/Milestone15Button,
	$MilestonesPopup/VBox/ScrollContainer/MilestonesVBox/Milestone20Button,
	$MilestonesPopup/VBox/ScrollContainer/MilestonesVBox/Milestone30Button,
	$MilestonesPopup/VBox/ScrollContainer/MilestonesVBox/Milestone40Button,
	$MilestonesPopup/VBox/ScrollContainer/MilestonesVBox/Milestone50Button,
]

@onready var panels := {
	"battle": $TabContent/BattlePanel,
	"upgrades": $TabContent/UpgradesPanel,
	"skills": $TabContent/SkillsPanel,
	"lab": $TabContent/LabPanel,
	"marketplace": $TabContent/MarketplacePanel,
}
@onready var tab_buttons := {
	"battle": $BottomTabBar/TabBar/BattleTabButton,
	"upgrades": $BottomTabBar/TabBar/UpgradesTabButton,
	"skills": $BottomTabBar/TabBar/SkillsTabButton,
	"lab": $BottomTabBar/TabBar/LabTabButton,
	"marketplace": $BottomTabBar/TabBar/MarketplaceTabButton,
}

@onready var intro_overlay = $IntroOverlay
@onready var intro_label = $IntroOverlay/IntroLabel
@onready var intro_timer = $IntroTimer

func _ready() -> void:
	_setup_splash_animation()
	for stat in tab_buttons.keys():
		tab_buttons[stat].pressed.connect(func():
			Audio.play("ui_click")
			_show_tab(stat)
		)
	battle_button.pressed.connect(func():
		Audio.play("ui_click")
		Audio.vibrate(40)
		Meta.select_tier(selected_tier)
		get_tree().change_scene_to_file(BATTLE_SCENE)
	)
	selected_tier = Meta.current_tier
	tier_left_button.pressed.connect(func(): _change_tier(-1))
	tier_right_button.pressed.connect(func(): _change_tier(1))
	battle_panel.gui_input.connect(_on_battle_panel_gui_input)
	_update_tier_label()

	hp_button.pressed.connect(func(): _spend("hp"))
	dmg_button.pressed.connect(func(): _spend("damage"))
	range_button.pressed.connect(func(): _spend("range"))
	haste_button.pressed.connect(func(): _spend("haste"))
	souls_gain_button.pressed.connect(func(): _spend("souls_gain"))
	crit_chance_button.pressed.connect(func(): _spend("crit_chance"))
	crit_damage_button.pressed.connect(func(): _spend("crit_damage"))
	multishot_button.pressed.connect(func(): _spend("multishot"))
	regen_button.pressed.connect(func(): _spend("regen"))
	thorns_button.pressed.connect(func(): _spend("thorns"))

	root_button.pressed.connect(func(): _buy_skill("awakened_core"))
	swift_tides_button.pressed.connect(func(): _unlock("swift_tides"))
	overcharge_core_button.pressed.connect(func(): _unlock("overcharge_core"))
	resonant_shell_button.pressed.connect(func(): _unlock("resonant_shell"))
	voidsight_button.pressed.connect(func(): _unlock("voidsight"))
	quickening_button.pressed.connect(func(): _unlock("quickening"))
	_build_skill_ui()
	_build_lab_ui()

	auto_restart_button.pressed.connect(func(): Purchases.buy("auto_restart"))
	remove_ads_button.pressed.connect(func(): Purchases.buy("remove_ads"))
	skin_violet_button.pressed.connect(_on_skin_button_pressed.bind("skin_violet"))
	skin_gold_button.pressed.connect(_on_skin_button_pressed.bind("skin_gold"))
	milestone_pass_button.pressed.connect(func(): _unlock("milestone_pass"))
	skillpoint_ad_button.pressed.connect(_on_watch_skillpoint_ad)
	coin_ad_button.pressed.connect(_on_watch_coin_ad)
	auto_restart_check.button_pressed = Meta.auto_restart_enabled
	auto_restart_check.toggled.connect(func(on: bool): Meta.set_auto_restart_enabled(on))

	menu_button.pressed.connect(_on_menu_button_pressed)
	menu_popup.about_to_popup.connect(func(): menu_button.icon = CLOSE_ICON)
	menu_popup.popup_hide.connect(func(): menu_button.icon = MENU_ICON)
	$MenuPopup/VBox/ReplayIntroButton.pressed.connect(_on_replay_intro_pressed)
	$MenuPopup/VBox/MissionsButton.pressed.connect(func():
		menu_popup.hide()
		missions_popup.popup_centered()
	)
	$MenuPopup/VBox/MilestonesButton.pressed.connect(func():
		menu_popup.hide()
		milestones_popup.popup_centered()
	)
	$MissionsPopup/VBox/CloseButton.pressed.connect(func(): missions_popup.hide())
	$MilestonesPopup/VBox/CloseButton.pressed.connect(func(): milestones_popup.hide())
	reroll_button.pressed.connect(func():
		_play_purchase_sfx(Meta.reroll_daily_missions())
	)
	for i in range(mission_buttons.size()):
		mission_buttons[i].pressed.connect(_claim_mission.bind(i))
	for i in range(milestone_buttons.size()):
		milestone_buttons[i].pressed.connect(_claim_milestone.bind(Meta.MILESTONES[i].wave))
	reset_button.pressed.connect(_on_reset_pressed)
	$MenuPopup/VBox/LicenseButton.pressed.connect(_on_license_pressed)
	$LicensePopup/VBox/CloseButton.pressed.connect(func(): license_popup.hide())
	$MenuPopup/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$SettingsPopup/VBox/CloseButton.pressed.connect(func(): settings_popup.hide())
	sfx_check.button_pressed = not Meta.sfx_muted
	music_check.button_pressed = not Meta.music_muted
	vibration_check.button_pressed = Meta.vibration_enabled
	sfx_check.toggled.connect(func(on: bool): Meta.set_sfx_muted(not on))
	music_check.toggled.connect(func(on: bool): Meta.set_music_muted(not on))
	vibration_check.toggled.connect(func(on: bool):
		Meta.set_vibration_enabled(on)
		if on:
			Audio.vibrate(30)
	)
	google_sign_in_button.pressed.connect(func(): Backend.sign_in_with_google())
	Backend.signed_in.connect(func(_uid): _update_google_sign_in_button())
	settings_popup.about_to_popup.connect(_update_google_sign_in_button)

	$IntroOverlay/SkipButton.pressed.connect(_skip_intro)
	intro_timer.timeout.connect(_on_intro_timer_timeout)

	Meta.progress_changed.connect(_refresh_all)
	_refresh_all()
	_show_tab("battle")

	if not Meta.intro_seen:
		_show_intro()

# Builds a looping AnimatedTexture from the numbered frames baked by
# scripts/tools (see prompt/home-splash-animation.json) — the frames already
# fade to/from black at the loop seam. Falls back to the static PNG set in
# the scene if the frames folder is missing.
func _setup_splash_animation() -> void:
	var dir := DirAccess.open(SPLASH_FRAMES_DIR)
	if dir == null:
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	if files.is_empty():
		return
	files.sort()

	var anim := AnimatedTexture.new()
	anim.frames = files.size()
	for i in range(files.size()):
		anim.set_frame_texture(i, load(SPLASH_FRAMES_DIR + files[i]))
		anim.set_frame_duration(i, 1.0 / SPLASH_FPS)
	splash_background.texture = anim

func _show_tab(tab_name: String) -> void:
	for key in panels.keys():
		panels[key].visible = key == tab_name
	splash_background.visible = tab_name == "battle"

func _refresh_all() -> void:
	souls_label.text = "%d" % Meta.souls
	gems_label.text = "%d" % Meta.gems
	top_skill_points_label.text = "%d" % Meta.skill_points
	skill_points_label.text = "%d Skill Points" % Meta.skill_points
	_update_upgrade_button(hp_button, "hp")
	_update_upgrade_button(dmg_button, "damage")
	_update_upgrade_button(range_button, "range")
	_update_upgrade_button(haste_button, "haste")
	_update_upgrade_button(souls_gain_button, "souls_gain")
	_update_upgrade_button(crit_chance_button, "crit_chance")
	_update_upgrade_button(crit_damage_button, "crit_damage")
	_update_upgrade_button(multishot_button, "multishot")
	_update_upgrade_button(regen_button, "regen")
	_update_upgrade_button(thorns_button, "thorns")

	var skills_ready := Meta.skills_unlocked()
	skills_locked_label.visible = not skills_ready
	skill_points_row.visible = skills_ready
	root_button.visible = skills_ready
	tree_connector.visible = skills_ready
	branches.visible = skills_ready
	if skills_ready:
		_update_root_button()
		for entry in skill_node_buttons:
			_update_skill_node_button(entry.button, entry.key)

	var lab_ready := Meta.lab_unlocked()
	lab_locked_label.visible = not lab_ready
	for btn in lab_content_buttons:
		btn.visible = lab_ready
	if lab_ready:
		_update_one_time_button(swift_tides_button, "swift_tides")
		_update_one_time_button(overcharge_core_button, "overcharge_core")
		_update_one_time_button(resonant_shell_button, "resonant_shell")
		_update_one_time_button(voidsight_button, "voidsight")
		_update_one_time_button(quickening_button, "quickening")
		for entry in lab_node_buttons:
			_update_one_time_button(entry.button, entry.key)

	_update_real_money_button(auto_restart_button, "auto_restart")
	_update_real_money_button(remove_ads_button, "remove_ads")
	_update_skin_button(skin_violet_button, "skin_violet")
	_update_skin_button(skin_gold_button, "skin_gold")
	auto_restart_check.disabled = not Meta.real_purchases.auto_restart
	if Meta.real_purchases.auto_restart:
		auto_restart_check.button_pressed = Meta.auto_restart_enabled
	_update_one_time_button(milestone_pass_button, "milestone_pass")
	_update_ad_buttons()
	_update_missions_ui()
	_update_milestones_ui()
	selected_tier = clamp(selected_tier, 1, Meta.unlocked_tier)
	_update_tier_label()

func _change_tier(delta: int) -> void:
	var new_tier: int = clamp(selected_tier + delta, 1, Meta.unlocked_tier)
	if new_tier == selected_tier:
		return
	selected_tier = new_tier
	Audio.play("ui_click")
	_update_tier_label()

func _update_tier_label() -> void:
	tier_label.text = "Tier %d" % selected_tier
	tier_left_button.disabled = selected_tier <= 1
	tier_right_button.disabled = selected_tier >= Meta.unlocked_tier

func _on_battle_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start_x = event.position.x
		else:
			_handle_swipe_release(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_swipe_start_x = event.position.x
		else:
			_handle_swipe_release(event.position.x)

func _handle_swipe_release(release_x: float) -> void:
	var delta_x := release_x - _swipe_start_x
	if abs(delta_x) >= SWIPE_THRESHOLD:
		_change_tier(-1 if delta_x > 0 else 1)

func _update_ad_buttons() -> void:
	if Meta.can_watch_skillpoint_ad():
		skillpoint_ad_button.text = "Watch an ad — +1 Skill Point\nOnce per day."
		skillpoint_ad_button.disabled = false
	else:
		skillpoint_ad_button.text = "Watch an ad — +1 Skill Point\nAlready claimed today."
		skillpoint_ad_button.disabled = true

	var remaining := Meta.coin_ads_remaining_today()
	var reward := int(round(Meta.coin_ad_reward() * Meta.ad_bonus_multiplier()))
	if remaining <= 0:
		coin_ad_button.text = "Watch an ad — +Souls\nAll 5 claimed today."
		coin_ad_button.disabled = true
	elif Meta.ad_bonus_multiplier() > 1.0:
		var bonus_pct := int(round((Meta.ad_bonus_multiplier() - 1.0) * 100))
		coin_ad_button.text = "Watch an ad — +%d Souls (+%d%% streak)\n%d of 5 left today." % [reward, bonus_pct, remaining]
		coin_ad_button.disabled = false
	else:
		coin_ad_button.text = "Watch an ad — +%d Souls\n%d of 5 left today." % [reward, remaining]
		coin_ad_button.disabled = false

func _update_missions_ui() -> void:
	for i in range(mission_buttons.size()):
		var btn: Button = mission_buttons[i]
		if i >= Meta.daily_missions.size():
			btn.visible = false
			continue
		btn.visible = true
		var m: Dictionary = Meta.daily_missions[i]
		var t := Meta.mission_template(m.id)
		var progress := Meta.mission_progress(i)
		if m.claimed:
			btn.text = "%s — Claimed\n%d / %d" % [t.label, progress, t.target]
			btn.disabled = true
		elif Meta.mission_is_ready(i):
			btn.text = "%s — Ready!\n+%d Souls" % [t.label, t.reward]
			btn.disabled = false
		else:
			btn.text = "%s — %d / %d\n+%d Souls" % [t.label, progress, t.target, t.reward]
			btn.disabled = true
	reroll_button.disabled = not Meta.can_reroll_missions()
	reroll_button.text = "Reroll Missions" if Meta.can_reroll_missions() else "Reroll used today"

func _update_milestones_ui() -> void:
	for i in range(milestone_buttons.size()):
		var btn: Button = milestone_buttons[i]
		var wave: int = Meta.MILESTONES[i].wave
		var reward := Meta.milestone_reward(wave)
		if Meta.milestone_claimed.get(str(wave), false):
			btn.text = "Wave %d — Claimed\n+%d Souls" % [wave, reward]
			btn.disabled = true
		elif Meta.milestone_available(wave):
			btn.text = "Wave %d — Ready!\n+%d Souls" % [wave, reward]
			btn.disabled = false
		else:
			btn.text = "Wave %d — Locked\n+%d Souls" % [wave, reward]
			btn.disabled = true

func _update_upgrade_button(button: Button, stat: String) -> void:
	var u = Meta.UPGRADES[stat]
	var cost := Meta.cost_for(stat)
	var level: int = Meta.levels[stat]
	button.text = "%s — Lv.%d — %d Souls\n%s" % [u.label, level, cost, u.description]
	button.disabled = Meta.souls < cost

func _update_one_time_button(button: Button, key: String) -> void:
	var u = Meta.ONE_TIME[key]
	if Meta.unlocked.get(key, false):
		button.text = "%s — Unlocked\n%s" % [u.label, u.description]
		button.disabled = true
	elif not Meta.one_time_available(key):
		button.text = "%s — Locked" % u.label
		button.disabled = true
	else:
		button.text = "%s — %d Souls\n%s" % [u.label, u.cost, u.description]
		button.disabled = Meta.souls < u.cost

func _update_real_money_button(button: Button, key: String) -> void:
	var p = Meta.REAL_MONEY_PRODUCTS[key]
	if Meta.real_purchases.get(key, false):
		button.text = "%s — Owned\n%s" % [p.label, p.description]
		button.disabled = true
	else:
		button.text = "%s\n%s" % [p.label, p.description]
		button.disabled = false

func _update_skin_button(button: Button, key: String) -> void:
	var p = Meta.REAL_MONEY_PRODUCTS[key]
	if Meta.active_core_skin == key:
		button.text = "%s — Equipped\n%s" % [p.label, p.description]
		button.disabled = true
	elif Meta.real_purchases.get(key, false):
		button.text = "%s — Owned, tap to equip\n%s" % [p.label, p.description]
		button.disabled = false
	else:
		button.text = "%s\n%s" % [p.label, p.description]
		button.disabled = false

func _on_skin_button_pressed(key: String) -> void:
	if Meta.real_purchases.get(key, false):
		Meta.set_active_core_skin(key)
	else:
		Purchases.buy(key)

func _update_google_sign_in_button() -> void:
	if Backend.signed_in_with_google:
		var label := Backend.signed_in_email if Backend.signed_in_email != "" else "Google account"
		google_sign_in_button.text = "Signed in as %s" % label
		google_sign_in_button.disabled = true
	elif not Backend.google_sign_in_available():
		google_sign_in_button.text = "Sign in with Google (Android only)"
		google_sign_in_button.disabled = true
	else:
		google_sign_in_button.text = "Sign in with Google"
		google_sign_in_button.disabled = false

func _update_root_button() -> void:
	var s = Meta.SKILL_TREE.awakened_core
	if Meta.skill_unlocked.awakened_core:
		root_button.text = "%s — Awakened\n%s" % [s.label, s.description]
		root_button.disabled = true
	else:
		root_button.text = "%s — %d Skill Points\n%s" % [s.label, s.cost, s.description]
		root_button.disabled = Meta.skill_points < s.cost

func _update_skill_node_button(button: Button, key: String) -> void:
	var s = Meta.SKILL_TREE[key]
	if Meta.skill_unlocked.get(key, false):
		button.text = "%s — Bought\n%s" % [s.label, s.description]
		button.disabled = true
	elif not Meta.skill_available(key):
		button.text = "%s — Locked" % s.label
		button.disabled = true
	else:
		button.text = "%s — %d Skill Points\n%s" % [s.label, s.cost, s.description]
		button.disabled = Meta.skill_points < s.cost

# Builds the ~150-button Skills list once at startup: a header per branch
# (Attack/Defense/HP) followed by its 50 generated nodes, in chain order.
func _build_skill_ui() -> void:
	for branch_key in Meta.SKILL_BRANCHES.keys():
		var branch = Meta.SKILL_BRANCHES[branch_key]
		branches_vbox.add_child(_make_section_header(branch.label))
		for i in range(Meta.SKILL_NODES_BY_BRANCH[branch_key].size()):
			var key := "skill_%s_%02d" % [branch_key, i]
			var s = Meta.SKILL_TREE[key]
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(0, 50)
			btn.icon = STAT_ICONS.get(s.stat)
			btn.pressed.connect(_buy_skill.bind(key))
			branches_vbox.add_child(btn)
			skill_node_buttons.append({"key": key, "button": btn})

# Same idea as _build_skill_ui, for the ~100-button Lab research list —
# a header per category (Power/Guard/Flow) followed by its 32 generated
# nodes, appended after the hand-written named researches.
func _build_lab_ui() -> void:
	for cat_key in Meta.LAB_CATEGORIES.keys():
		var cat = Meta.LAB_CATEGORIES[cat_key]
		generated_research_vbox.add_child(_make_section_header(cat.label))
		for i in range(Meta.LAB_NODES_BY_CATEGORY[cat_key].size()):
			var key := "lab_%s_%02d" % [cat_key, i]
			var o = Meta.ONE_TIME[key]
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(0, 54)
			btn.icon = STAT_ICONS.get(o.stat)
			btn.pressed.connect(_unlock.bind(key))
			generated_research_vbox.add_child(btn)
			lab_node_buttons.append({"key": key, "button": btn})

func _make_section_header(text: String) -> Label:
	var header := Label.new()
	header.text = text
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", SECTION_HEADER_COLOR)
	return header

func _play_purchase_sfx(success: bool) -> void:
	if success:
		Audio.play("ui_confirm")
		Audio.vibrate(25)
	else:
		Audio.play("ui_error")

func _spend(stat: String) -> void:
	_play_purchase_sfx(Meta.spend(stat))

func _unlock(key: String) -> void:
	_play_purchase_sfx(Meta.unlock(key))

func _buy_skill(key: String) -> void:
	_play_purchase_sfx(Meta.buy_skill(key))

func _claim_mission(index: int) -> void:
	_play_purchase_sfx(Meta.claim_mission(index))

func _claim_milestone(wave: int) -> void:
	_play_purchase_sfx(Meta.claim_milestone(wave))

func _on_watch_skillpoint_ad() -> void:
	if not Meta.can_watch_skillpoint_ad():
		return
	skillpoint_ad_button.disabled = true
	Ads.show_skillpoint_ad()
	await Ads.ad_finished
	if Meta.claim_skillpoint_ad():
		_play_purchase_sfx(true)
	else:
		_update_ad_buttons()

func _on_watch_coin_ad() -> void:
	if not Meta.can_watch_coin_ad():
		return
	coin_ad_button.disabled = true
	Ads.show_coin_ad()
	await Ads.ad_finished
	if Meta.claim_coin_ad():
		_play_purchase_sfx(true)
	else:
		_update_ad_buttons()

func _on_menu_button_pressed() -> void:
	if menu_popup.visible:
		menu_popup.hide()
	else:
		menu_popup.popup_centered()

func _on_license_pressed() -> void:
	menu_popup.hide()
	license_popup.popup_centered()

func _on_settings_pressed() -> void:
	menu_popup.hide()
	settings_popup.popup_centered()

func _on_replay_intro_pressed() -> void:
	Meta.replay_intro()
	menu_popup.hide()
	_show_intro()

func _on_reset_pressed() -> void:
	if not reset_confirm_pending:
		reset_confirm_pending = true
		reset_button.text = "Tap again to confirm"
		reset_button.add_theme_color_override("font_color", DANGER_COLOR)
		reset_button.add_theme_color_override("font_hover_color", DANGER_COLOR)
		await get_tree().create_timer(RESET_CONFIRM_SECONDS).timeout
		if reset_confirm_pending:
			reset_confirm_pending = false
			reset_button.text = "Reset Progress"
			reset_button.remove_theme_color_override("font_color")
			reset_button.remove_theme_color_override("font_hover_color")
	else:
		reset_confirm_pending = false
		Meta.reset_progress()
		reset_button.text = "Reset Progress"
		reset_button.remove_theme_color_override("font_color")
		reset_button.remove_theme_color_override("font_hover_color")
		menu_popup.hide()

func _show_intro() -> void:
	intro_index = 0
	intro_overlay.visible = true
	intro_label.text = INTRO_LINES[0]
	intro_timer.start(INTRO_LINE_SECONDS)

func _on_intro_timer_timeout() -> void:
	intro_index += 1
	if intro_index >= INTRO_LINES.size():
		_finish_intro()
	else:
		intro_label.text = INTRO_LINES[intro_index]
		intro_timer.start(INTRO_LINE_SECONDS)

func _skip_intro() -> void:
	intro_timer.stop()
	_finish_intro()

func _finish_intro() -> void:
	intro_overlay.visible = false
	Meta.mark_intro_seen()

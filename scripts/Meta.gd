extends Node

const SAVE_PATH = "user://save.json"

# Leveled upgrades: cost scales geometrically forever, bought from the
# Reconstruction screen with Souls.
const UPGRADES := {
	"hp": {
		"base_cost": 20, "growth": 1.15, "per_level": 10.0,
		"label": "Max HP", "description": "Reinforce the ancient stone.",
	},
	"damage": {
		"base_cost": 30, "growth": 1.18, "per_level": 1.0,
		"label": "Damage", "description": "Amplify the power of the Core.",
	},
	"range": {
		"base_cost": 25, "growth": 1.15, "per_level": 10.0,
		"label": "Range", "description": "Extend the Core's influence.",
	},
	"haste": {
		"base_cost": 35, "growth": 1.2, "per_level": 0.02,
		"label": "Haste", "description": "Quicken the Core's pulse.",
	},
	"souls_gain": {
		"base_cost": 40, "growth": 1.2, "per_level": 0.05,
		"label": "Soul Gain", "description": "Draw more from every fallen wave.",
	},
	"crit_chance": {
		"base_cost": 50, "growth": 1.22, "per_level": 0.02,
		"label": "Critical Strike", "description": "A chance for the Core's pulse to strike true.",
	},
	"crit_damage": {
		"base_cost": 45, "growth": 1.2, "per_level": 0.15,
		"label": "Critical Power", "description": "Amplify the fury of a critical strike.",
	},
	"multishot": {
		"base_cost": 60, "growth": 1.25, "per_level": 0.015,
		"label": "Multishot", "description": "A chance to strike two Voidborn at once.",
	},
	"regen": {
		"base_cost": 35, "growth": 1.18, "per_level": 0.3,
		"label": "Regeneration", "description": "The stone slowly mends itself.",
	},
	"thorns": {
		"base_cost": 30, "growth": 1.17, "per_level": 0.5,
		"label": "Thorned Stone", "description": "Wounds returned to those who strike the Keep.",
	},
}

# One-time unlocks bought with Souls. "category" decides which tab shows them.
# The "lab" category merges a handful of hand-written named researches with
# three much longer hand-authored chains (see _build_one_time / LAB_POWER_NODES
# / LAB_GUARD_NODES / LAB_FLOW_NODES) the player invests Souls into
# indefinitely, one node unlocking the next.
const ONE_TIME_NAMED := {
	"swift_tides": {
		"category": "lab", "cost": 90, "bonus": 0.4,
		"label": "Swift Tides", "description": "Voidborn waves rise sooner.",
	},
	"overcharge_core": {
		"category": "lab", "cost": 150, "bonus": 8.0, "stat": "damage",
		"label": "Overcharge Core", "description": "Force more power through the Core, permanently.",
	},
	"resonant_shell": {
		"category": "lab", "cost": 130, "bonus": 60.0, "stat": "hp",
		"label": "Resonant Shell", "description": "Layer the ancient stone against future harm.",
	},
	"voidsight": {
		"category": "lab", "cost": 110, "bonus": 50.0, "stat": "range",
		"label": "Voidsight", "description": "See the Void before it arrives.",
	},
	"quickening": {
		"category": "lab", "cost": 200, "bonus": 0.08,
		"label": "Quickening", "description": "Shave the space between heartbeats.",
	},
	"milestone_pass": {
		"category": "marketplace", "cost": 300, "bonus": 1.0,
		"label": "Milestone Pass", "description": "Doubles every Milestone reward, forever.",
	},
}
var ONE_TIME := _build_one_time()

# Real-money purchases (Google Play Billing via Purchases.gd) — deliberately
# separate from the Souls/Skill-Point economy above. Nothing here affects
# combat power: Auto Restart and Remove Ads are pure convenience, skins are
# cosmetic. product_id must match a real in-app product configured in the
# Google Play Console for a purchase to actually succeed on a real device.
const REAL_MONEY_PRODUCTS := {
	"auto_restart": {
		"product_id": "com.ascendkeep.game.auto_restart",
		"label": "Auto Restart", "description": "Instantly begin a new run after the Keep falls.",
	},
	"remove_ads": {
		"product_id": "com.ascendkeep.game.remove_ads",
		"label": "Remove Ads", "description": "No more ad-watching — your daily Skill Point and Souls ad rewards are credited automatically instead.",
	},
	"skin_violet": {
		"product_id": "com.ascendkeep.game.skin_violet",
		"label": "Violet Core", "description": "A violet glow for the Core. Purely cosmetic.",
	},
	"skin_gold": {
		"product_id": "com.ascendkeep.game.skin_gold",
		"label": "Golden Core", "description": "A golden glow for the Core. Purely cosmetic.",
	},
}

# Cosmetic ring-glow colors selectable once the matching skin is owned.
# "default" is always available and free.
const CORE_SKINS := {
	"default": {"label": "Stone Blue", "color": Color(0.6, 0.9, 1.0)},
	"skin_violet": {"label": "Violet Core", "color": Color(0.75, 0.4, 0.95)},
	"skin_gold": {"label": "Golden Core", "color": Color(0.95, 0.8, 0.4)},
}

const SKILL_STAT_INCREMENT := {
	"damage": 0.5, "crit_chance": 0.008, "crit_damage": 0.05, "multishot": 0.006,
	"range": 3.0, "haste": 0.006, "defense_pct": 0.004, "thorns": 0.25,
	"hp": 5.0, "regen": 0.1, "souls_gain": 0.01,
}
const LAB_STAT_INCREMENT := {
	"damage": 0.4, "crit_chance": 0.006, "crit_damage": 0.04, "multishot": 0.005,
	"range": 2.5, "haste": 0.005, "defense_pct": 0.003, "thorns": 0.2,
	"hp": 4.0, "regen": 0.08, "souls_gain": 0.008,
}

const SKILL_BRANCHES := {
	"attack": {"stats": ["damage", "crit_chance", "crit_damage", "multishot", "range", "haste"], "label": "Attack"},
	"defense": {"stats": ["defense_pct", "thorns"], "label": "Defense"},
	"hp": {"stats": ["hp", "regen", "souls_gain"], "label": "HP"},
}
const SKILL_COST_BASE := 3
const SKILL_COST_GROWTH := 1.11

const LAB_CATEGORIES := {
	"power": {"label": "Power Research"},
	"guard": {"label": "Guard Research"},
	"flow": {"label": "Flow Research"},
}
const LAB_COST_BASE := 80
const LAB_COST_GROWTH := 1.09

# Power Research, hand-authored: weapons-lab voice — measuring, calibrating
# and pushing past the Core's original design limits. Cycles damage,
# crit_damage and multishot.
const LAB_POWER_NODES := [
	{"stat": "damage", "label": "Fracture Analysis", "description": "The first real data on how the Core's pulse breaks Void matter."},
	{"stat": "crit_damage", "label": "Weak Point Mapping", "description": "Every Voidborn has one. Now it's documented."},
	{"stat": "multishot", "label": "Split Beam Prototype", "description": "The pulse, divided on purpose."},
	{"stat": "damage", "label": "Calibrated Impact", "description": "Small adjustment, measurable difference."},
	{"stat": "crit_damage", "label": "Structural Failure Study", "description": "Understanding exactly how they come apart."},
	{"stat": "multishot", "label": "Dual Emission Study", "description": "Two targets, one Core."},
	{"stat": "damage", "label": "Compressed Charge", "description": "More force packed into the same pulse."},
	{"stat": "crit_damage", "label": "Amplified Rupture", "description": "A critical strike that does more than crit."},
	{"stat": "multishot", "label": "Divergent Trajectory", "description": "Not a miscalculation — a second shot."},
	{"stat": "damage", "label": "Focused Discharge", "description": "Less waste, more damage."},
	{"stat": "crit_damage", "label": "Shattering Coefficient", "description": "A number that keeps getting worse for the Voidborn."},
	{"stat": "multishot", "label": "Parallel Discharge", "description": "Simultaneous, not sequential."},
	{"stat": "damage", "label": "Resonant Amplification", "description": "The pulse now excites itself before release."},
	{"stat": "crit_damage", "label": "Cascading Fracture", "description": "One crack finds the next."},
	{"stat": "multishot", "label": "Branching Impact", "description": "The pulse forks where it's useful."},
	{"stat": "damage", "label": "Overdriven Coils", "description": "Pushed past the safety margins the first design assumed."},
	{"stat": "crit_damage", "label": "Critical Mass Theory", "description": "Enough force in the right place ends the argument."},
	{"stat": "multishot", "label": "Redundant Targeting", "description": "No single Voidborn gets the Core's full attention."},
	{"stat": "damage", "label": "Kinetic Refinement", "description": "Every joule accounted for, none wasted."},
	{"stat": "crit_damage", "label": "Terminal Impact Study", "description": "The strike after which nothing needs healing."},
	{"stat": "multishot", "label": "Cascading Emission", "description": "Each shot considers what the last one hit."},
	{"stat": "damage", "label": "Sustained Overload", "description": "The Core can run hotter than anyone expected."},
	{"stat": "crit_damage", "label": "Total Rupture", "description": "Nothing partial about it anymore."},
	{"stat": "multishot", "label": "Networked Discharge", "description": "The Core's pulses start coordinating."},
	{"stat": "damage", "label": "Terminal Velocity Study", "description": "There was a ceiling. There isn't anymore."},
	{"stat": "crit_damage", "label": "Absolute Failure Point", "description": "Beyond this, there is no such thing as surviving."},
	{"stat": "multishot", "label": "Swarm Trajectory", "description": "Built for when there's more than one target worth hitting."},
	{"stat": "damage", "label": "Unbound Output", "description": "The old limits were never truly physical."},
	{"stat": "crit_damage", "label": "Beyond Threshold", "description": "The old failure point was never the real one."},
	{"stat": "multishot", "label": "Unbound Emission", "description": "However many pulses the Core wants to send, it sends."},
	{"stat": "damage", "label": "Theoretical Maximum", "description": "Or as close to it as anyone dares test."},
	{"stat": "crit_damage", "label": "Unsurvivable Coefficient", "description": "A number nobody wants applied to them."},
]

# Guard Research, hand-authored: fortification-lab voice — reinforcing,
# dispersing and answering force instead of just enduring it. Cycles hp,
# defense_pct and thorns.
const LAB_GUARD_NODES := [
	{"stat": "hp", "label": "Structural Reinforcement", "description": "The Keep's walls, measured and thickened."},
	{"stat": "defense_pct", "label": "Deflection Modeling", "description": "Predicting exactly how force should be turned aside."},
	{"stat": "thorns", "label": "Reflective Surface Study", "description": "A wall that returns what it receives."},
	{"stat": "hp", "label": "Load-Bearing Analysis", "description": "Knowing exactly what the Keep can take."},
	{"stat": "defense_pct", "label": "Impact Dispersion Study", "description": "Spreading a blow instead of absorbing it whole."},
	{"stat": "thorns", "label": "Feedback Loop Prototype", "description": "The first working return-strike design."},
	{"stat": "hp", "label": "Deep Lattice Study", "description": "What holds the stone together, strengthened."},
	{"stat": "defense_pct", "label": "Angular Deflection", "description": "The right shape does half the work."},
	{"stat": "thorns", "label": "Return Vector Analysis", "description": "Calculating exactly where the retaliation should land."},
	{"stat": "hp", "label": "Redundant Framework", "description": "No single point the Keep depends on to stand."},
	{"stat": "defense_pct", "label": "Distributed Load Theory", "description": "No single point takes the full hit."},
	{"stat": "thorns", "label": "Retaliatory Coating", "description": "A layer whose only purpose is to answer back."},
	{"stat": "hp", "label": "Stress Tolerance Study", "description": "How much more the Keep can absorb, documented."},
	{"stat": "defense_pct", "label": "Resonant Dampening", "description": "The stone learns to not transmit the shock."},
	{"stat": "thorns", "label": "Reactive Plating", "description": "Triggers faster than the strike that sets it off."},
	{"stat": "hp", "label": "Compound Reinforcement", "description": "Layer on layer, each one counted."},
	{"stat": "defense_pct", "label": "Absorption Matrix", "description": "A lattice built specifically to eat force."},
	{"stat": "thorns", "label": "Amplified Feedback", "description": "The return hits harder than the original."},
	{"stat": "hp", "label": "Integrity Threshold", "description": "The point of failure, pushed further out."},
	{"stat": "defense_pct", "label": "Layered Dispersion", "description": "Each layer catches what the last one missed."},
	{"stat": "thorns", "label": "Compound Retaliation", "description": "Every layer answers separately."},
	{"stat": "hp", "label": "Reinforced Substrate", "description": "Beneath the visible stone, something sturdier now."},
	{"stat": "defense_pct", "label": "Total Deflection Study", "description": "How close to zero the impact can get."},
	{"stat": "thorns", "label": "Total Feedback Theory", "description": "Modeling a wall that punishes every single contact."},
	{"stat": "hp", "label": "Structural Overbuild", "description": "Built for far more than it needs, on purpose."},
	{"stat": "defense_pct", "label": "Near-Total Dampening", "description": "Almost nothing gets through anymore."},
	{"stat": "thorns", "label": "Unbound Retaliation", "description": "No cap left on how hard it answers back."},
	{"stat": "hp", "label": "Absolute Tolerance", "description": "Approaching the theoretical edge of what stone can bear."},
	{"stat": "defense_pct", "label": "Residual Impact Theory", "description": "Modeling what little force is left after every layer."},
	{"stat": "thorns", "label": "Absolute Reprisal", "description": "The last research note on the subject: don't touch the Keep."},
	{"stat": "hp", "label": "Theoretical Integrity Limit", "description": "As close to indestructible as the research allows."},
	{"stat": "defense_pct", "label": "Theoretical Zero-Impact", "description": "The research edge case nobody expected to reach."},
]

# Flow Research, hand-authored: efficiency/sensing-lab voice — cycling
# faster, healing continuously, sensing further, drawing more. Cycles
# haste, regen, range, souls_gain and crit_chance.
const LAB_FLOW_NODES := [
	{"stat": "haste", "label": "Cycle Time Reduction", "description": "Shaving fractions of a second off every pulse."},
	{"stat": "regen", "label": "Self-Repair Prototype", "description": "The first working design for a Keep that heals itself."},
	{"stat": "range", "label": "Detection Radius Study", "description": "Mapping exactly how far the Core can sense a threat."},
	{"stat": "souls_gain", "label": "Residue Collection Study", "description": "What's left behind after a Voidborn falls, catalogued."},
	{"stat": "crit_chance", "label": "Probability Modeling", "description": "The first real numbers on when a strike lands true."},
	{"stat": "haste", "label": "Discharge Interval Study", "description": "Understanding exactly where the delay comes from."},
	{"stat": "regen", "label": "Structural Recovery Study", "description": "How fast stone can knit, measured properly."},
	{"stat": "haste", "label": "Accelerated Cycling", "description": "The Core recovers between pulses faster than designed."},
	{"stat": "regen", "label": "Accelerated Recovery", "description": "Healing that keeps pace with the damage."},
	{"stat": "range", "label": "Extended Sensing Array", "description": "Pushing the detection radius further out."},
	{"stat": "souls_gain", "label": "Efficient Extraction", "description": "Less is wasted in the collection process."},
	{"stat": "crit_chance", "label": "Weak Point Prediction", "description": "Guessing less, knowing more."},
	{"stat": "haste", "label": "Compressed Interval Theory", "description": "How short the gap can get before it stops mattering."},
	{"stat": "regen", "label": "Continuous Repair Theory", "description": "A Keep that never stops mending, even mid-fight."},
	{"stat": "range", "label": "Amplified Detection", "description": "Fainter signals, noticed sooner."},
	{"stat": "souls_gain", "label": "Amplified Collection", "description": "Drawing more from the same fallen enemy."},
	{"stat": "crit_chance", "label": "Predictive Targeting", "description": "The Core starts anticipating the opening before it appears."},
	{"stat": "haste", "label": "Near-Instant Cycling", "description": "The pause between pulses, almost gone."},
	{"stat": "regen", "label": "Compound Recovery", "description": "Multiple repair processes running at once."},
	{"stat": "range", "label": "Long-Range Calibration", "description": "Precision holds even at the new distance."},
	{"stat": "souls_gain", "label": "Compound Extraction Theory", "description": "Multiple collection methods running together."},
	{"stat": "crit_chance", "label": "Amplified Prediction", "description": "Better data, better strikes."},
	{"stat": "haste", "label": "Unbound Cycle Rate", "description": "Whatever limited it before no longer applies."},
	{"stat": "regen", "label": "Near-Instant Repair", "description": "Wounds that barely have time to matter."},
	{"stat": "range", "label": "Horizon Sensing Theory", "description": "Modeling detection at the edge of the arena itself."},
	{"stat": "souls_gain", "label": "Near-Total Collection", "description": "Almost nothing left behind anymore."},
	{"stat": "crit_chance", "label": "Near-Certain Targeting", "description": "The gap between a good hit and the best one, closing."},
	{"stat": "haste", "label": "Theoretical Cycle Limit", "description": "The fastest anyone has modeled the Core going."},
	{"stat": "regen", "label": "Theoretical Recovery Limit", "description": "As fast as anyone has modeled stone healing."},
	{"stat": "range", "label": "Unbound Detection Range", "description": "No meaningful limit left to push against."},
	{"stat": "souls_gain", "label": "Theoretical Extraction Limit", "description": "As much as the research says can be drawn."},
	{"stat": "crit_chance", "label": "Theoretical Prediction Limit", "description": "As close to certainty as the research gets."},
]

# Lets Home.gd know how many buttons to build per category without
# hardcoding the count (all three happen to be 32, but this stays correct
# if that ever changes).
const LAB_NODES_BY_CATEGORY := {
	"power": LAB_POWER_NODES, "guard": LAB_GUARD_NODES, "flow": LAB_FLOW_NODES,
}

static func _build_lab_hand_category(result: Dictionary, cat_key: String, nodes: Array) -> void:
	var prev_key := ""
	for i in range(nodes.size()):
		var node = nodes[i]
		var key := "lab_%s_%02d" % [cat_key, i]
		var cost := int(round(LAB_COST_BASE * pow(LAB_COST_GROWTH, i)))
		result[key] = {
			"category": "lab", "chain": cat_key, "requires": prev_key, "stat": node.stat,
			"cost": cost, "bonus": LAB_STAT_INCREMENT[node.stat],
			"label": node.label, "description": node.description,
		}
		prev_key = key

# Builds the ~100-node Lab list: the hand-written named researches plus
# three hand-authored 32-node chains (one per category), each node
# requiring the previous one in its own chain.
static func _build_one_time() -> Dictionary:
	var result := ONE_TIME_NAMED.duplicate(true)
	_build_lab_hand_category(result, "power", LAB_POWER_NODES)
	_build_lab_hand_category(result, "guard", LAB_GUARD_NODES)
	_build_lab_hand_category(result, "flow", LAB_FLOW_NODES)
	return result

# Tiers: each is its own 100-wave gauntlet, harder than the last, with a
# boss every 10 waves. Reaching wave 50 of the current highest tier unlocks
# the next one — old tiers stay replayable forever (harder tiers just pay
# and hit much better), which is what makes the climb effectively endless.
const MAX_TIER := 100
const TIER_MAX_WAVE := 100
const TIER_UNLOCK_WAVE := 50
const BOSS_WAVE_INTERVAL := 10
# Compounding per-tier multiplier on enemy HP/damage and on Souls/mission
# rewards — chosen so each tier feels like a real step up without the
# numbers exploding into nonsense by tier 100 (20/tier ~= a very hard but
# not absurd late game; tune after real playtesting).
const TIER_DIFFICULTY_GROWTH := 1.2
const TIER_REWARD_GROWTH := 1.25
# Small permanent bonuses auto-granted the first time a tier's wave 50 (HP)
# or wave 100 (Damage) is reached — the "infinite" character-growth layer
# that keeps paying out even after a tier stops feeling difficult.
const TIER_PERK_HP_PERCENT := 0.01
const TIER_PERK_DAMAGE_PERCENT := 0.01

# The Skills tab and Lab tab stay locked until the Core has unlocked these
# tiers — a full tier (100 waves deep) is a much bigger milestone than a
# handful of waves, so gating by tier instead of by wave paces things out
# properly instead of dumping every system on the player almost immediately.
const SKILLS_UNLOCK_TIER := 3
const LAB_UNLOCK_TIER := 2

const MAX_COIN_ADS_PER_DAY := 5
const COIN_AD_PERCENT := 0.15
const SECONDS_PER_DAY := 86400.0

# Watching another coin ad within this window of the last one grows the
# reward multiplier instead of resetting to flat — rewards back-to-back
# ad-watching sessions without raising the daily cap.
const AD_BONUS_STACK_WINDOW_SECONDS := 1800.0
const AD_BONUS_STACK_PERCENT := 0.05
const AD_BONUS_STACK_MAX := 5

# Daily missions: three random templates per day, rerollable (all at once)
# once for free. Progress accumulates across every run played that day.
const ACTIVE_MISSIONS_COUNT := 3
const MISSION_TEMPLATES := [
	{"id": "wave5", "metric": "wave", "target": 5, "reward": 30, "label": "Reach Wave 5"},
	{"id": "wave10", "metric": "wave", "target": 10, "reward": 70, "label": "Reach Wave 10"},
	{"id": "wave15", "metric": "wave", "target": 15, "reward": 120, "label": "Reach Wave 15"},
	{"id": "voidborn20", "metric": "voidborn", "target": 20, "reward": 50, "label": "Defeat 20 Voidborn"},
	{"id": "voidborn50", "metric": "voidborn", "target": 50, "reward": 110, "label": "Defeat 50 Voidborn"},
	{"id": "souls150", "metric": "souls_earned", "target": 150, "reward": 45, "label": "Earn 150 Souls"},
	{"id": "souls400", "metric": "souls_earned", "target": 400, "reward": 100, "label": "Earn 400 Souls"},
	{"id": "ads2", "metric": "ads_watched", "target": 2, "reward": 60, "label": "Watch 2 Ads"},
]

# Milestone track: permanent one-time rewards for the highest wave ever
# reached across all runs. Reward doubles forever once "milestone_pass" is
# bought (see ONE_TIME) — the free/premium track pattern, without needing a
# live in-round UI since AscendKeep runs reset on death.
const MILESTONES := [
	{"wave": 5, "reward": 30},
	{"wave": 10, "reward": 70},
	{"wave": 15, "reward": 120},
	{"wave": 20, "reward": 200},
	{"wave": 30, "reward": 350},
	{"wave": 40, "reward": 550},
	{"wave": 50, "reward": 800},
]

# The Skill tree. "awakened_core" is the root: it must be unlocked before
# any branch is buyable. Each of the three branches (Attack/Defense/HP) is
# a long chain of one-time nodes (see _build_skill_tree) — 50 apiece,
# node N requiring node N-1 — paid for with Skill Points, which now come
# from boss kills (Meta.BOSS_WAVE_INTERVAL in Main.gd).
const SKILL_ROOT := {
	"awakened_core": {
		"requires": "", "cost": 3,
		"label": "Awakened Core", "description": "The Core stirs, ready to grow beyond stone.",
	},
}

# The Attack branch, hand-authored: 50 distinct named nodes. Order here IS
# chain order (node N requires node N-1), so it also reads as an escalating
# narrative across 6 stats.
const SKILL_ATTACK_NODES := [
	{"stat": "damage", "label": "Bruising Force", "description": "The first bruise the Void ever felt."},
	{"stat": "crit_chance", "label": "Keen Instinct", "description": "The Core starts to sense where it hurts most."},
	{"stat": "crit_damage", "label": "Vicious Follow-Through", "description": "A strike that doesn't stop at first contact."},
	{"stat": "multishot", "label": "Splitting Pulse", "description": "One pulse becomes two, rarely — but rarely is enough."},
	{"stat": "range", "label": "Extended Sight", "description": "The Core's will reaches a little further into the dark."},
	{"stat": "haste", "label": "Quickened Heartbeat", "description": "Barely faster. Barely matters. It adds up."},
	{"stat": "damage", "label": "Rending Edge", "description": "Every pulse leaves a little more behind."},
	{"stat": "crit_chance", "label": "Weak Point Sense", "description": "Not luck — recognition."},
	{"stat": "crit_damage", "label": "Brutal Finish", "description": "The last inch of a killing blow, sharpened."},
	{"stat": "multishot", "label": "Echoing Strike", "description": "The pulse remembers where it's been."},
	{"stat": "range", "label": "Farseeing Core", "description": "Threats resolve before they arrive."},
	{"stat": "haste", "label": "Restless Pulse", "description": "The Core forgets how to be still."},
	{"stat": "damage", "label": "Savage Momentum", "description": "Force compounding on force."},
	{"stat": "crit_chance", "label": "Predator's Focus", "description": "Nothing moves that the Core doesn't track."},
	{"stat": "crit_damage", "label": "Merciless Edge", "description": "No strike wasted, none softened."},
	{"stat": "multishot", "label": "Twin Fangs", "description": "Two wounds where there was one."},
	{"stat": "range", "label": "Horizon's Edge", "description": "The arena shrinks; the Core does not."},
	{"stat": "haste", "label": "Accelerated Rhythm", "description": "The gap between heartbeats keeps closing."},
	{"stat": "damage", "label": "Crushing Weight", "description": "Stone remembers how to fall."},
	{"stat": "crit_chance", "label": "Opportunist's Eye", "description": "Every opening, seen and taken."},
	{"stat": "crit_damage", "label": "Devastating Blow", "description": "A strike that ends arguments."},
	{"stat": "multishot", "label": "Forked Lightning", "description": "The pulse no longer chooses just one target."},
	{"stat": "range", "label": "Boundless Reach", "description": "Distance stops being a defense."},
	{"stat": "haste", "label": "Fevered Tempo", "description": "The Core's patience runs thin, and that's useful."},
	{"stat": "damage", "label": "Annihilating Pulse", "description": "Less a hit, more an ending."},
	{"stat": "crit_chance", "label": "Killing Intuition", "description": "The Core stops guessing."},
	{"stat": "crit_damage", "label": "Executioner's Grip", "description": "The strike after the strike that should have ended it."},
	{"stat": "multishot", "label": "Cascading Impact", "description": "One pulse triggers the next."},
	{"stat": "range", "label": "All-Seeing Pulse", "description": "Nothing enters the arena unnoticed."},
	{"stat": "haste", "label": "Relentless Cadence", "description": "No pause the Voidborn can exploit."},
	{"stat": "damage", "label": "Ruinous Impact", "description": "What it hits, it unmakes."},
	{"stat": "crit_chance", "label": "Flawless Reading", "description": "Every weakness, an open book."},
	{"stat": "crit_damage", "label": "Overwhelming Force", "description": "Beyond what the strike needed to be."},
	{"stat": "multishot", "label": "Chain Reaction", "description": "The pulse forgets where to stop."},
	{"stat": "range", "label": "Void Perception", "description": "The Core sees into the dark the Voidborn came from."},
	{"stat": "haste", "label": "Unbound Speed", "description": "Nothing left to slow the pulse down."},
	{"stat": "damage", "label": "Cataclysmic Strike", "description": "A single pulse, a small cataclysm."},
	{"stat": "crit_chance", "label": "Death's Whisper", "description": "The Core hears the moment before the kill."},
	{"stat": "crit_damage", "label": "Annihilator's Strike", "description": "There is less of the enemy after this."},
	{"stat": "multishot", "label": "Storm of Pulses", "description": "No longer one pulse. A weather pattern."},
	{"stat": "range", "label": "Omnipresent Watch", "description": "The whole arena, always in range."},
	{"stat": "haste", "label": "Timeless Pulse", "description": "The Core stops waiting entirely."},
	{"stat": "damage", "label": "Worldbreaker's Wrath", "description": "Enough force to end more than a Voidborn."},
	{"stat": "crit_chance", "label": "Perfect Opening", "description": "Every strike, the right one."},
	{"stat": "crit_damage", "label": "Absolute Ruin", "description": "Nothing left to finish off. Already finished."},
	{"stat": "multishot", "label": "Infinite Echo", "description": "The pulse no longer remembers being one thing."},
	{"stat": "range", "label": "Infinite Horizon", "description": "There is no far enough."},
	{"stat": "haste", "label": "Eternal Momentum", "description": "The Core's pulse never truly stops."},
	{"stat": "damage", "label": "Apex of Ruin", "description": "The Core, at its most merciless."},
	{"stat": "crit_chance", "label": "Omniscient Aim", "description": "No weak points left to find — so it makes new ones."},
]

# Defense branch, hand-authored: alternates defense_pct (warding/armor
# theme) and thorns (retaliation theme).
const SKILL_DEFENSE_NODES := [
	{"stat": "defense_pct", "label": "Hardened Surface", "description": "The first layer that refuses to give."},
	{"stat": "thorns", "label": "Jagged Edge", "description": "Touch it and it touches back."},
	{"stat": "defense_pct", "label": "Stone Ward", "description": "A little less gets through each time."},
	{"stat": "thorns", "label": "Sharpened Stone", "description": "The Keep's walls were never meant to be soft."},
	{"stat": "defense_pct", "label": "Deflecting Angle", "description": "Not every blow needs to be absorbed — some just slide off."},
	{"stat": "thorns", "label": "Retaliating Spikes", "description": "An answer for every strike."},
	{"stat": "defense_pct", "label": "Layered Bulwark", "description": "One wall becomes several."},
	{"stat": "thorns", "label": "Bramble Ward", "description": "The closer they get, the more it costs them."},
	{"stat": "defense_pct", "label": "Runic Barrier", "description": "Old wards, still holding."},
	{"stat": "thorns", "label": "Vengeful Surface", "description": "Every impact is remembered, and returned."},
	{"stat": "defense_pct", "label": "Unyielding Face", "description": "It does not flinch. It was not built to."},
	{"stat": "thorns", "label": "Cutting Return", "description": "The Keep does not simply endure — it answers."},
	{"stat": "defense_pct", "label": "Absorbing Stone", "description": "Force spreads through the wall instead of past it."},
	{"stat": "thorns", "label": "Spiked Bulwark", "description": "A wall that bites."},
	{"stat": "defense_pct", "label": "Tempered Ward", "description": "Hardened by every blow that came before."},
	{"stat": "thorns", "label": "Reactive Barbs", "description": "Faster than the strike that triggers them."},
	{"stat": "defense_pct", "label": "Void-Touched Armor", "description": "It learned something from what it survived."},
	{"stat": "thorns", "label": "Thorned Crown", "description": "The Keep wears its defiance openly."},
	{"stat": "defense_pct", "label": "Resonant Barrier", "description": "The stone hums, and holds."},
	{"stat": "thorns", "label": "Punishing Contact", "description": "Nothing that touches the Keep leaves undamaged."},
	{"stat": "defense_pct", "label": "Ancient Warding", "description": "Older than the Voidborn's memory of victory."},
	{"stat": "thorns", "label": "Bloodied Stone", "description": "It has drawn more than it has lost."},
	{"stat": "defense_pct", "label": "Petrified Skin", "description": "What was flesh-soft is flesh no longer."},
	{"stat": "thorns", "label": "Wrathful Skin", "description": "The Keep's patience has an edge."},
	{"stat": "defense_pct", "label": "Bound Aegis", "description": "A shield that was never separate from the stone."},
	{"stat": "thorns", "label": "Iron Thorns", "description": "Softer things break against it first."},
	{"stat": "defense_pct", "label": "Unbreakable Facade", "description": "The Voidborn stopped expecting it to crack."},
	{"stat": "thorns", "label": "Retribution's Edge", "description": "The last thing many Voidborn ever feel."},
	{"stat": "defense_pct", "label": "Sanctified Stone", "description": "Something in the old wards still remembers purpose."},
	{"stat": "thorns", "label": "Cruel Surface", "description": "There is no gentle way to strike the Keep now."},
	{"stat": "defense_pct", "label": "Immutable Ward", "description": "It does not weaken. It has stopped being asked to."},
	{"stat": "thorns", "label": "Barbed Aegis", "description": "Defense that draws blood of its own."},
	{"stat": "defense_pct", "label": "Fortress Heart", "description": "The core the rest of the wall protects, protecting itself."},
	{"stat": "thorns", "label": "Answering Blade", "description": "Every strike, met with one in kind."},
	{"stat": "defense_pct", "label": "Reinforced Core", "description": "What was already strong, made stronger."},
	{"stat": "thorns", "label": "Merciless Rebuke", "description": "The Keep no longer merely survives an attack."},
	{"stat": "defense_pct", "label": "Warding Sigil", "description": "A mark that turns force aside."},
	{"stat": "thorns", "label": "Void-Touched Spikes", "description": "Turned the enemy's own dark against it."},
	{"stat": "defense_pct", "label": "Eternal Bastion", "description": "It was built to last. It is lasting."},
	{"stat": "thorns", "label": "Undying Vengeance", "description": "The Keep remembers every wound, and repays them all."},
	{"stat": "defense_pct", "label": "Impenetrable Face", "description": "Very little is left that can find a way through."},
	{"stat": "thorns", "label": "Absolute Retaliation", "description": "To strike the Keep is to be struck."},
	{"stat": "defense_pct", "label": "Absolute Ward", "description": "Almost nothing gets through anymore."},
	{"stat": "thorns", "label": "Keep's Fury", "description": "Every attacker pays a price worth remembering."},
	{"stat": "defense_pct", "label": "Keep's Own Shield", "description": "The Keep has stopped needing anything else to protect it."},
	{"stat": "thorns", "label": "Final Answer", "description": "There is nothing left to say back to this."},
	{"stat": "defense_pct", "label": "Final Bulwark", "description": "What stands here, stands for good."},
	{"stat": "thorns", "label": "Unrelenting Thorns", "description": "It never stops answering."},
	{"stat": "defense_pct", "label": "Unshakeable Stone", "description": "The Void itself cannot move what refuses to move."},
	{"stat": "thorns", "label": "Apex Retribution", "description": "The Keep's final word on being struck."},
]

# HP branch, hand-authored: cycles hp (endurance theme), regen (mending
# theme) and souls_gain (hunger/drawing theme).
const SKILL_HP_NODES := [
	{"stat": "hp", "label": "Deeper Foundation", "description": "The Keep goes further down than it lets on."},
	{"stat": "regen", "label": "Slow Mending", "description": "Cracks close, given time."},
	{"stat": "souls_gain", "label": "Hungry Stone", "description": "The Keep takes a little more from every fall."},
	{"stat": "hp", "label": "Thicker Walls", "description": "More stone between the Core and the dark."},
	{"stat": "regen", "label": "Knitting Stone", "description": "The Keep was never meant to stay wounded."},
	{"stat": "souls_gain", "label": "Soul Tether", "description": "A little of every Voidborn stays behind."},
	{"stat": "hp", "label": "Ancient Reserves", "description": "Strength the Keep forgot it still had."},
	{"stat": "regen", "label": "Quiet Restoration", "description": "Healing that asks for no attention."},
	{"stat": "souls_gain", "label": "Drawing Current", "description": "Souls flow toward the Keep a little more eagerly."},
	{"stat": "hp", "label": "Stubborn Stone", "description": "It simply refuses to fall."},
	{"stat": "regen", "label": "Steady Repair", "description": "Slow, but it never stops."},
	{"stat": "souls_gain", "label": "Deepened Hunger", "description": "The Keep wants more, and takes it."},
	{"stat": "hp", "label": "Layered Defenses", "description": "Behind every wall, another."},
	{"stat": "regen", "label": "Living Mortar", "description": "Even the mortar between the stones remembers how to heal."},
	{"stat": "souls_gain", "label": "Resonant Pull", "description": "Fallen Voidborn give up a little more than they'd like."},
	{"stat": "hp", "label": "Enduring Core", "description": "What is at the center does not give up easily."},
	{"stat": "regen", "label": "Self-Healing Walls", "description": "The stone was never entirely inert."},
	{"stat": "souls_gain", "label": "Void Siphon", "description": "Turns a fraction of the Void's own power back on it."},
	{"stat": "hp", "label": "Vital Bedrock", "description": "The foundation the rest of the Keep depends on, deepened."},
	{"stat": "regen", "label": "Patient Recovery", "description": "There is no wound the Keep expects to keep."},
	{"stat": "souls_gain", "label": "Insatiable Core", "description": "It has stopped being satisfied with a little."},
	{"stat": "hp", "label": "Resilient Frame", "description": "Bent, perhaps. Broken, not yet."},
	{"stat": "regen", "label": "Renewing Core", "description": "The heart of the Keep keeps setting itself right."},
	{"stat": "souls_gain", "label": "Binding Current", "description": "Fewer souls slip past the Keep's reach."},
	{"stat": "hp", "label": "Unworn Stone", "description": "Ten thousand strikes, and it still stands the same."},
	{"stat": "regen", "label": "Persistent Mending", "description": "Given enough time, everything closes."},
	{"stat": "souls_gain", "label": "Ancient Hunger", "description": "Older than the Voidborn themselves, and just as patient."},
	{"stat": "hp", "label": "Deepened Roots", "description": "What holds the Keep up runs further than anyone can see."},
	{"stat": "regen", "label": "Ceaseless Repair", "description": "It was never finished being built."},
	{"stat": "souls_gain", "label": "Overflowing Well", "description": "More comes back than was ever expected."},
	{"stat": "hp", "label": "Stalwart Foundation", "description": "What the Keep is built on does not move."},
	{"stat": "regen", "label": "Ancient Restoration", "description": "A healing older than the current siege."},
	{"stat": "souls_gain", "label": "Endless Draw", "description": "The pull never quite stops."},
	{"stat": "hp", "label": "Timeless Endurance", "description": "It has already outlasted more than it was meant to."},
	{"stat": "regen", "label": "Unbroken Recovery", "description": "No wound the Keep has kept for long."},
	{"stat": "souls_gain", "label": "Keep's Own Hunger", "description": "It has started wanting for itself."},
	{"stat": "hp", "label": "Keep's Own Strength", "description": "Not borrowed. Not granted. Its own."},
	{"stat": "regen", "label": "Eternal Renewal", "description": "As long as the Core beats, the Keep mends."},
	{"stat": "souls_gain", "label": "Boundless Siphon", "description": "There is no longer a limit to what it can take."},
	{"stat": "hp", "label": "Boundless Vitality", "description": "Whatever life the Keep has left, there is more of it now."},
	{"stat": "regen", "label": "Keep's Own Healing", "description": "It needs nothing else to mend itself."},
	{"stat": "souls_gain", "label": "Absolute Draw", "description": "Nothing that falls near the Keep is truly lost to it."},
	{"stat": "hp", "label": "Immovable Core", "description": "What is at the heart of the Keep will not be moved."},
	{"stat": "regen", "label": "Boundless Restoration", "description": "There is no damage left that outpaces the mending."},
	{"stat": "souls_gain", "label": "Final Hunger", "description": "The last and greatest of the Keep's appetites."},
	{"stat": "hp", "label": "Everlasting Stone", "description": "Built once. Standing still."},
	{"stat": "regen", "label": "Apex Renewal", "description": "The Keep's mending, perfected."},
	{"stat": "souls_gain", "label": "Apex Hunger", "description": "Every fallen Voidborn gives everything it has left."},
	{"stat": "hp", "label": "Apex Endurance", "description": "The Keep, at its most unbreakable."},
	{"stat": "regen", "label": "Deep Renewal", "description": "Even the deepest cracks close now."},
]

var SKILL_TREE := _build_skill_tree()

# Lets Home.gd know how many buttons to build per branch without
# hardcoding the count.
const SKILL_NODES_BY_BRANCH := {
	"attack": SKILL_ATTACK_NODES, "defense": SKILL_DEFENSE_NODES, "hp": SKILL_HP_NODES,
}

static func _build_skill_hand_branch(result: Dictionary, branch_key: String, nodes: Array) -> void:
	var prev_key := "awakened_core"
	for i in range(nodes.size()):
		var node = nodes[i]
		var key := "skill_%s_%02d" % [branch_key, i]
		var cost := int(round(SKILL_COST_BASE * pow(SKILL_COST_GROWTH, i)))
		result[key] = {
			"requires": prev_key, "branch": branch_key, "stat": node.stat, "cost": cost,
			"bonus": SKILL_STAT_INCREMENT[node.stat],
			"label": node.label, "description": node.description,
		}
		prev_key = key

static func _build_skill_tree() -> Dictionary:
	var result := SKILL_ROOT.duplicate(true)
	_build_skill_hand_branch(result, "attack", SKILL_ATTACK_NODES)
	_build_skill_hand_branch(result, "defense", SKILL_DEFENSE_NODES)
	_build_skill_hand_branch(result, "hp", SKILL_HP_NODES)
	return result

signal progress_changed
# Fired for unlocks big enough to deserve an in-battle toast (tier/skills/
# lab unlocking, permanent tier perks) — deliberate purchases already get
# their own button-state + SFX feedback and don't need this.
signal notable_unlock(title: String, description: String)

var souls := 0
var gems := 0
var skill_points := 0
var levels := {
	"hp": 0, "damage": 0, "range": 0, "haste": 0, "souls_gain": 0,
	"crit_chance": 0, "crit_damage": 0, "multishot": 0, "regen": 0, "thorns": 0,
}
var unlocked := {
	"swift_tides": false, "overcharge_core": false, "resonant_shell": false,
	"voidsight": false, "quickening": false, "milestone_pass": false,
}
# Real-money purchases — never touched by reset_progress(). A player who
# paid for something keeps it forever, even after wiping their save.
var real_purchases := {
	"auto_restart": false, "remove_ads": false, "skin_violet": false, "skin_gold": false,
}
var active_core_skin := "default"
var auto_restart_enabled := true
var ad_day_index := -1
var skillpoint_ad_used_today := false
var coin_ads_used_today := 0
var ad_bonus_stack := 0
var ad_bonus_expires_at := 0.0
var daily_missions := []
var mission_reroll_used_today := false
var best_wave_ever := 0
var milestone_claimed := {}
var current_tier := 1
var unlocked_tier := 1
var best_wave_by_tier := {}
var tier_perk_hp_bonus := 0.0
var tier_perk_damage_bonus := 0.0
var tier_perks_claimed := {}
var skill_unlocked := {"awakened_core": false}
var intro_seen := false
var sfx_muted := false
var music_muted := false
var vibration_enabled := true

func _ready() -> void:
	_load()
	_check_daily_reset()

func skills_unlocked() -> bool:
	return unlocked_tier >= SKILLS_UNLOCK_TIER

func lab_unlocked() -> bool:
	return unlocked_tier >= LAB_UNLOCK_TIER

func tier_difficulty_multiplier(tier: int) -> float:
	return pow(TIER_DIFFICULTY_GROWTH, tier - 1)

func tier_reward_multiplier(tier: int) -> float:
	return pow(TIER_REWARD_GROWTH, tier - 1)

func best_wave_in_tier(tier: int) -> int:
	return best_wave_by_tier.get(str(tier), 0)

# Called from the Battle tab carousel — browsing is free, but you can only
# actually fight in a tier you've unlocked.
func select_tier(tier: int) -> void:
	current_tier = clamp(tier, 1, unlocked_tier)
	_save()

func add_souls(amount: int) -> void:
	souls += amount
	progress_changed.emit()
	_save()

# Not called anywhere yet — the hook for when a boss kill grants Skill Points.
func add_skill_points(amount: int) -> void:
	skill_points += amount
	progress_changed.emit()
	_save()

func cost_for(stat: String) -> int:
	var u = UPGRADES[stat]
	return int(ceil(u.base_cost * pow(u.growth, levels[stat])))

func bonus_for(stat: String) -> float:
	return levels[stat] * UPGRADES[stat].per_level

func spend(stat: String) -> bool:
	var cost := cost_for(stat)
	if souls < cost:
		return false
	souls -= cost
	levels[stat] += 1
	progress_changed.emit()
	_save()
	return true

func one_time_bonus(key: String) -> float:
	return ONE_TIME[key].bonus if unlocked.get(key, false) else 0.0

# A generated Lab node is buyable once the previous node in its chain is
# bought; the hand-written named researches have no "requires" and are
# always available once the Lab tab itself is unlocked.
func one_time_available(key: String) -> bool:
	var requires: String = ONE_TIME[key].get("requires", "")
	return requires == "" or unlocked.get(requires, false)

func unlock(key: String) -> bool:
	if unlocked.get(key, false) or not one_time_available(key):
		return false
	var cost: int = ONE_TIME[key].cost
	if souls < cost:
		return false
	souls -= cost
	unlocked[key] = true
	progress_changed.emit()
	_save()
	return true

# Called by Purchases.gd once Google Play actually confirms the purchase —
# never called speculatively, so no price/ownership check is needed here.
func grant_real_purchase(key: String) -> void:
	if real_purchases.get(key, false):
		return
	real_purchases[key] = true
	if key.begins_with("skin_"):
		active_core_skin = key
	progress_changed.emit()
	_save()

func set_active_core_skin(skin: String) -> bool:
	if skin != "default" and not real_purchases.get(skin, false):
		return false
	active_core_skin = skin
	progress_changed.emit()
	_save()
	return true

func core_skin_color() -> Color:
	return CORE_SKINS.get(active_core_skin, CORE_SKINS.default).color

func skill_cost(key: String) -> int:
	return SKILL_TREE[key].cost

# A skill node is buyable once its required node (root, or the previous
# node in its branch's chain) is unlocked.
func skill_available(key: String) -> bool:
	var s = SKILL_TREE[key]
	return s.requires == "" or skill_unlocked.get(s.requires, false)

# Total bonus for a given stat across every bought Skill-tree node that
# feeds it — nodes are one-time (bought or not), so this is a plain sum.
func skill_bonus_for_stat(stat: String) -> float:
	var total := 0.0
	for key in SKILL_TREE.keys():
		var s = SKILL_TREE[key]
		if s.get("stat", "") == stat and skill_unlocked.get(key, false):
			total += s.bonus
	return total

# Same idea as skill_bonus_for_stat, for bought Lab research.
func lab_bonus_for_stat(stat: String) -> float:
	var total := 0.0
	for key in ONE_TIME.keys():
		var o = ONE_TIME[key]
		if o.category == "lab" and o.get("stat", "") == stat and unlocked.get(key, false):
			total += o.bonus
	return total

func buy_skill(key: String) -> bool:
	if skill_unlocked.get(key, false) or not skill_available(key):
		return false
	var cost := skill_cost(key)
	if skill_points < cost:
		return false
	skill_points -= cost
	skill_unlocked[key] = true
	progress_changed.emit()
	_save()
	return true

func _check_daily_reset() -> void:
	var today := int(Time.get_unix_time_from_system() / SECONDS_PER_DAY)
	if today != ad_day_index:
		ad_day_index = today
		skillpoint_ad_used_today = false
		coin_ads_used_today = 0
		mission_reroll_used_today = false
		_roll_daily_missions()
		if real_purchases.remove_ads:
			_auto_grant_ad_rewards()
		_save()
	elif daily_missions.is_empty():
		_roll_daily_missions()
		_save()

# Remove Ads (real money) means never having to watch an ad again — but it
# shouldn't cost the player the daily Skill Point / Souls that used to
# require watching one, so those are credited automatically instead, once
# per day, at the flat (non-streak) rate.
func _auto_grant_ad_rewards() -> void:
	skillpoint_ad_used_today = true
	add_skill_points(1)
	for i in range(MAX_COIN_ADS_PER_DAY):
		coin_ads_used_today += 1
		add_souls(coin_ad_reward())

func _roll_daily_missions() -> void:
	var pool := MISSION_TEMPLATES.duplicate()
	pool.shuffle()
	daily_missions.clear()
	for i in range(min(ACTIVE_MISSIONS_COUNT, pool.size())):
		daily_missions.append({"id": pool[i].id, "progress": 0, "claimed": false})

func can_reroll_missions() -> bool:
	_check_daily_reset()
	return not mission_reroll_used_today

func reroll_daily_missions() -> bool:
	if not can_reroll_missions():
		return false
	mission_reroll_used_today = true
	_roll_daily_missions()
	progress_changed.emit()
	_save()
	return true

func mission_template(id: String) -> Dictionary:
	for t in MISSION_TEMPLATES:
		if t.id == id:
			return t
	return {}

func mission_progress(index: int) -> int:
	var m: Dictionary = daily_missions[index]
	return min(m.progress, mission_template(m.id).target)

func mission_is_ready(index: int) -> bool:
	var m: Dictionary = daily_missions[index]
	return not m.claimed and m.progress >= mission_template(m.id).target

func claim_mission(index: int) -> bool:
	_check_daily_reset()
	if index < 0 or index >= daily_missions.size() or not mission_is_ready(index):
		return false
	daily_missions[index].claimed = true
	add_souls(mission_template(daily_missions[index].id).reward)
	return true

# Cumulative progress toward whichever active missions track this metric
# (e.g. "voidborn" kills, "souls_earned", "ads_watched") — accrues across
# every run played today, not reset when a single run ends.
func add_mission_progress(metric: String, amount: int) -> void:
	_check_daily_reset()
	var changed := false
	for m in daily_missions:
		var t := mission_template(m.id)
		if t.metric == metric and not m.claimed and m.progress < t.target:
			m.progress = min(t.target, m.progress + amount)
			changed = true
	if changed:
		progress_changed.emit()
		_save()

# Threshold-style progress (e.g. "reach wave 10") for whichever tier a run
# is in — updates that tier's best wave (unlocking the next tier and any
# tier perks along the way), and the mission "wave" metric, tier-agnostic.
# best_wave_ever (used by the tier-1-only Milestone track) only tracks
# tier 1, since that track predates tiers and its thresholds top out at 50.
func report_wave_reached(tier: int, wave: int) -> void:
	_check_daily_reset()
	var changed := false
	var key := str(tier)
	if wave > best_wave_by_tier.get(key, 0):
		best_wave_by_tier[key] = wave
		changed = true
		_check_tier_unlock(tier, wave)
		_check_tier_perks(tier, wave)
	if tier == 1 and wave > best_wave_ever:
		best_wave_ever = wave
		changed = true
	for m in daily_missions:
		var t := mission_template(m.id)
		if t.metric == "wave" and not m.claimed and m.progress < wave:
			m.progress = min(t.target, wave)
			changed = true
	if changed:
		progress_changed.emit()
		_save()

func _check_tier_unlock(tier: int, wave: int) -> void:
	if wave >= TIER_UNLOCK_WAVE and tier == unlocked_tier and unlocked_tier < MAX_TIER:
		unlocked_tier += 1
		notable_unlock.emit("Tier %d Unlocked" % unlocked_tier, "A harder, more rewarding gauntlet awaits. Swipe to it from the Battle tab.")
		if unlocked_tier == LAB_UNLOCK_TIER:
			notable_unlock.emit("Lab Unlocked", "Permanent research is now available, paid for in Souls.")
		if unlocked_tier == SKILLS_UNLOCK_TIER:
			notable_unlock.emit("Skills Unlocked", "The Awakened Core's skill tree is now available, paid for in Skill Points.")

func _check_tier_perks(tier: int, wave: int) -> void:
	if wave >= TIER_UNLOCK_WAVE:
		_grant_tier_perk(tier, TIER_UNLOCK_WAVE, "hp")
	if wave >= TIER_MAX_WAVE:
		_grant_tier_perk(tier, TIER_MAX_WAVE, "damage")

func _grant_tier_perk(tier: int, threshold: int, stat: String) -> void:
	var key := "%d_%d" % [tier, threshold]
	if tier_perks_claimed.get(key, false):
		return
	tier_perks_claimed[key] = true
	if stat == "hp":
		tier_perk_hp_bonus += TIER_PERK_HP_PERCENT
		notable_unlock.emit("Permanent Bonus", "+%d%% Max HP, forever (Tier %d, Wave %d)." % [int(round(TIER_PERK_HP_PERCENT * 100)), tier, threshold])
	else:
		tier_perk_damage_bonus += TIER_PERK_DAMAGE_PERCENT
		notable_unlock.emit("Permanent Bonus", "+%d%% Damage, forever (Tier %d, Wave %d)." % [int(round(TIER_PERK_DAMAGE_PERCENT * 100)), tier, threshold])

func milestone_available(wave: int) -> bool:
	return best_wave_ever >= wave and not milestone_claimed.get(str(wave), false)

func milestone_reward(wave: int) -> int:
	for m in MILESTONES:
		if m.wave == wave:
			return m.reward * (2 if unlocked.milestone_pass else 1)
	return 0

func claim_milestone(wave: int) -> bool:
	if not milestone_available(wave):
		return false
	milestone_claimed[str(wave)] = true
	add_souls(milestone_reward(wave))
	return true

func can_watch_skillpoint_ad() -> bool:
	_check_daily_reset()
	return not skillpoint_ad_used_today

func can_watch_coin_ad() -> bool:
	_check_daily_reset()
	return coin_ads_used_today < MAX_COIN_ADS_PER_DAY

func coin_ads_remaining_today() -> int:
	_check_daily_reset()
	return MAX_COIN_ADS_PER_DAY - coin_ads_used_today

# 15% of whichever Reconstruction upgrade is currently cheapest — scales
# naturally with progression instead of going stale in late game.
func coin_ad_reward() -> int:
	var cheapest: int = -1
	for stat in UPGRADES.keys():
		var c := cost_for(stat)
		if cheapest == -1 or c < cheapest:
			cheapest = c
	return max(1, int(round(cheapest * COIN_AD_PERCENT)))

func claim_skillpoint_ad() -> bool:
	if not can_watch_skillpoint_ad():
		return false
	skillpoint_ad_used_today = true
	add_mission_progress("ads_watched", 1)
	add_skill_points(1)
	return true

# Stack grows while ads are watched back-to-back (within the stack window)
# and resets to 1 once it expires — rewards ad-watching sessions instead of
# paying the same flat amount no matter the pacing.
func ad_bonus_multiplier() -> float:
	if Time.get_unix_time_from_system() >= ad_bonus_expires_at:
		return 1.0
	return 1.0 + AD_BONUS_STACK_PERCENT * (ad_bonus_stack - 1)

func ad_bonus_seconds_remaining() -> float:
	return max(0.0, ad_bonus_expires_at - Time.get_unix_time_from_system())

func claim_coin_ad() -> bool:
	if not can_watch_coin_ad():
		return false
	coin_ads_used_today += 1
	var now := Time.get_unix_time_from_system()
	ad_bonus_stack = (ad_bonus_stack + 1) if now < ad_bonus_expires_at else 1
	ad_bonus_stack = min(ad_bonus_stack, AD_BONUS_STACK_MAX)
	ad_bonus_expires_at = now + AD_BONUS_STACK_WINDOW_SECONDS
	add_mission_progress("ads_watched", 1)
	add_souls(int(round(coin_ad_reward() * ad_bonus_multiplier())))
	return true

func set_auto_restart_enabled(enabled: bool) -> void:
	auto_restart_enabled = enabled
	_save()

func set_sfx_muted(muted: bool) -> void:
	sfx_muted = muted
	_save()

func set_music_muted(muted: bool) -> void:
	music_muted = muted
	_save()

func set_vibration_enabled(enabled: bool) -> void:
	vibration_enabled = enabled
	_save()

func mark_intro_seen() -> void:
	intro_seen = true
	_save()

func replay_intro() -> void:
	intro_seen = false
	_save()

# Wipes economy, levels and unlocks. Leaves intro_seen untouched — replaying
# the intro is a separate, explicit action.
func reset_progress() -> void:
	souls = 0
	gems = 0
	skill_points = 0
	for stat in levels.keys():
		levels[stat] = 0
	for key in unlocked.keys():
		unlocked[key] = false
	for key in skill_unlocked.keys():
		skill_unlocked[key] = false
	auto_restart_enabled = true
	ad_day_index = -1
	skillpoint_ad_used_today = false
	coin_ads_used_today = 0
	ad_bonus_stack = 0
	ad_bonus_expires_at = 0.0
	_roll_daily_missions()
	mission_reroll_used_today = false
	best_wave_ever = 0
	milestone_claimed.clear()
	current_tier = 1
	unlocked_tier = 1
	best_wave_by_tier.clear()
	tier_perk_hp_bonus = 0.0
	tier_perk_damage_bonus = 0.0
	tier_perks_claimed.clear()
	progress_changed.emit()
	_save()

# Rough sense of how far the Core has evolved, driven by total permanent
# progression rather than any single stat. Not tied to visuals yet — no
# tower sprites exist for the different stages.
func get_tower_evolution_stage() -> int:
	var total_levels: int = levels.hp + levels.damage + levels.range
	if total_levels >= 40:
		return 4
	elif total_levels >= 25:
		return 3
	elif total_levels >= 12:
		return 2
	elif total_levels >= 4:
		return 1
	return 0

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(save_data()))

# The full save state as a plain Dictionary — used for the local save file
# and, identically, for the Firestore cloud save document (Backend.gd).
func save_data() -> Dictionary:
	return {
		"souls": souls,
		"gems": gems,
		"skill_points": skill_points,
		"levels": levels,
		"unlocked": unlocked,
		"skill_unlocked": skill_unlocked,
		"intro_seen": intro_seen,
		"sfx_muted": sfx_muted,
		"music_muted": music_muted,
		"vibration_enabled": vibration_enabled,
		"auto_restart_enabled": auto_restart_enabled,
		"ad_day_index": ad_day_index,
		"skillpoint_ad_used_today": skillpoint_ad_used_today,
		"coin_ads_used_today": coin_ads_used_today,
		"ad_bonus_stack": ad_bonus_stack,
		"ad_bonus_expires_at": ad_bonus_expires_at,
		"daily_missions": daily_missions,
		"mission_reroll_used_today": mission_reroll_used_today,
		"best_wave_ever": best_wave_ever,
		"milestone_claimed": milestone_claimed,
		"current_tier": current_tier,
		"unlocked_tier": unlocked_tier,
		"best_wave_by_tier": best_wave_by_tier,
		"tier_perk_hp_bonus": tier_perk_hp_bonus,
		"tier_perk_damage_bonus": tier_perk_damage_bonus,
		"tier_perks_claimed": tier_perks_claimed,
		"real_purchases": real_purchases,
		"active_core_skin": active_core_skin,
	}

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if data:
		apply_save_data(data)

# Applies a save-state Dictionary (from the local file OR a Firestore cloud
# pull, same shape as save_data()) and re-persists it locally. Used by both
# _load() and Backend.gd's pull_save().
func apply_save_data(data: Dictionary) -> void:
	# "souls" is the current save key; "points"/"coins" are pre-lore
	# save formats. Migrate forward without ever discarding progress.
	souls = data.get("souls", data.get("points", data.get("coins", 0)))
	gems = data.get("gems", 0)
	skill_points = data.get("skill_points", 0)
	var loaded_levels = data.get("levels", {})
	for stat in levels.keys():
		levels[stat] = loaded_levels.get(stat, 0)
	# Iterate the SAVED dict's keys (not the freshly-built ONE_TIME/
	# SKILL_TREE ones) so purchases of procedurally generated Lab/Skill
	# nodes — which aren't part of the base dict until bought — survive
	# a reload instead of being silently dropped.
	var loaded_unlocked = data.get("unlocked", {})
	for key in loaded_unlocked.keys():
		unlocked[key] = loaded_unlocked[key]
	var loaded_skill_unlocked = data.get("skill_unlocked", {})
	for key in loaded_skill_unlocked.keys():
		skill_unlocked[key] = loaded_skill_unlocked[key]
	intro_seen = data.get("intro_seen", false)
	sfx_muted = data.get("sfx_muted", false)
	music_muted = data.get("music_muted", false)
	vibration_enabled = data.get("vibration_enabled", true)
	auto_restart_enabled = data.get("auto_restart_enabled", true)
	ad_day_index = data.get("ad_day_index", -1)
	skillpoint_ad_used_today = data.get("skillpoint_ad_used_today", false)
	coin_ads_used_today = data.get("coin_ads_used_today", 0)
	ad_bonus_stack = data.get("ad_bonus_stack", 0)
	ad_bonus_expires_at = data.get("ad_bonus_expires_at", 0.0)
	daily_missions = data.get("daily_missions", [])
	mission_reroll_used_today = data.get("mission_reroll_used_today", false)
	best_wave_ever = data.get("best_wave_ever", 0)
	milestone_claimed = data.get("milestone_claimed", {})
	current_tier = data.get("current_tier", 1)
	unlocked_tier = data.get("unlocked_tier", 1)
	best_wave_by_tier = data.get("best_wave_by_tier", {})
	tier_perk_hp_bonus = data.get("tier_perk_hp_bonus", 0.0)
	tier_perk_damage_bonus = data.get("tier_perk_damage_bonus", 0.0)
	tier_perks_claimed = data.get("tier_perks_claimed", {})
	var loaded_real_purchases = data.get("real_purchases", {})
	for key in loaded_real_purchases.keys():
		real_purchases[key] = loaded_real_purchases[key]
	active_core_skin = data.get("active_core_skin", "default")
	if not real_purchases.get(active_core_skin, false):
		active_core_skin = "default"
	_save()

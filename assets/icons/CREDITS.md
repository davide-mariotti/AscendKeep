# Icon, art & plugin credits

## Plugins

- `addons/admob/` — [AdMob plugin for Godot](https://github.com/poingstudios/godot-admob-plugin) v5.0.0, by Poing Studios, MIT License.

## Icons

All UI icons are from [Lucide](https://lucide.dev) 1.74.0, ISC License (the one icon set used across all my projects).
Each file keeps the Lucide name in a comment; white stroke, 512 px so Godot rasterises them sharp.

- `hp.svg` — heart
- `damage.svg` — sword
- `range.svg` — crosshair
- `haste.svg` — fast-forward
- `souls_gain.svg` — trending-up
- `skill_eye.svg` — eye
- `skill_shield.svg` — shield-check
- `skill_bond.svg` — link
- `lab_hourglass.svg` — hourglass
- `soul.svg` — ghost
- `gem.svg` — gem
- `restart.svg` — undo-2
- `reset.svg` — trash-2
- `credits.svg` — scroll-text
- `close.svg` — x
- `menu.svg` — menu
- `wave.svg` — waves
- `tab_battle.svg` — swords
- `tab_upgrades.svg` — hammer
- `tab_skills.svg` — network
- `tab_lab.svg` — flask-conical
- `tab_marketplace.svg` — shopping-cart
- `skill_root.svg` — sprout
- `skill_point.svg` — crown
- `settings.svg` — settings
- `sfx_icon.svg` — volume-2
- `music_icon.svg` — music
- `vibration_icon.svg` — vibrate
- `restart_game.svg` — rotate-cw
- `auto_restart.svg` — power
- `watch_ad.svg` — clapperboard
- `coin_ad.svg` — coins
- `mission.svg` — flag
- `milestone.svg` — trophy
- `crit_chance.svg` — target
- `crit_damage.svg` — flame
- `multishot.svg` — split
- `regen.svg` — heart-pulse
- `thorns.svg` — shield-x
- `deadly_precision.svg` — focus
- `twin_strike.svg` — git-fork
- `stone_skin.svg` — shield
- `overcharge_core.svg` — zap
- `resonant_shell.svg` — orbit
- `voidsight.svg` — scan-eye
- `quickening.svg` — timer
- `defense_pct.svg` — shield-half

## Sound effects

- `assets/audio/sfx/ui_click.ogg`, `ui_confirm.ogg`, `ui_error.ogg` — from [Interface Sounds](https://opengameart.org/content/interface-sounds) by Kenney, CC0.
- `assets/audio/sfx/game_over.ogg` — also from Kenney's Interface Sounds, CC0.
- `assets/audio/sfx/soul_pickup.wav`, `tower_shoot.wav`, `tower_hit.wav`, `voidborn_death.wav` — from the [RPG Sound Pack](https://opengameart.org/content/rpg-sound-pack) by artisticdude, CC0.

## In-battle sprites

Custom artwork, generated from prompts in `prompt/*.json`, not from any third-party asset pack.

- `assets/sprites/tower.png` — the Core (`Tower.gd`)
- `assets/sprites/voidling.png` — the Voidborn (`Enemy.gd`)
- `assets/sprites/bullet.png` — tower projectile (`Projectile.gd`)
- `assets/sprites/boss-the-hollow-crown.png` — boss concept art, not wired into gameplay yet (no boss system exists)
- `assets/art/battle-background.png` — background behind the arena during a run (`Main.tscn`), generated from `prompt/battle-background.json`.

## Home screen art

- `assets/art/home-splash.png` — static cover illustration, generated from `prompt/home-splash.json` (kept as source/fallback).
- `assets/art/home-splash.mp4` — the same image animated via an AI video tool from `prompt/home-splash-animation.json` (source file, not used directly at runtime).
- `assets/art/home_splash_frames/` — 168 frames (native 24fps, 150×267, ~7s loop) extracted and processed from that video (dead trailing black cut, fade-to/from-black added at the loop seam) — built into a looping `AnimatedTexture` at runtime by `Home.gd`, shown full-screen behind the Battle tab.

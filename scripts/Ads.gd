extends Node

## Real AdMob rewarded ads via the "AdMob" plugin (addons/admob, Poing Studios).
## On desktop/editor (no Android/iOS export) the plugin shows its own
## interactive "Mock Ad" overlay instead of a real ad, so this can be tested
## without a device. On an actual Android/iOS export with the native AdMob
## packages installed (Project > Tools > AdMob Manager), real ads play.

signal ad_finished(success: bool)

const SKILLPOINT_AD_UNIT_ANDROID := "ca-app-pub-5907544153918240/1981590643"
const SKILLPOINT_AD_UNIT_IOS := "ca-app-pub-5907544153918240/8738570686"
const COIN_AD_UNIT_ANDROID := "ca-app-pub-5907544153918240/7042345635"
const COIN_AD_UNIT_IOS := "ca-app-pub-5907544153918240/7233917329"

var _rewarded_ad: RewardedAd
var _reward_listener := OnUserEarnedRewardListener.new()
var _load_callback := RewardedAdLoadCallback.new()
var _content_callback := FullScreenContentCallback.new()
var _busy := false

func _ready() -> void:
	MobileAds.initialize()
	_reward_listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		ad_finished.emit(true)
	_load_callback.on_ad_loaded = _on_ad_loaded
	_load_callback.on_ad_failed_to_load = func(_error: LoadAdError) -> void:
		_busy = false
		ad_finished.emit(false)
	_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		if _rewarded_ad:
			_rewarded_ad.destroy()
			_rewarded_ad = null
		_busy = false
	_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError) -> void:
		_busy = false
		ad_finished.emit(false)

func show_skillpoint_ad() -> void:
	_load_and_show(SKILLPOINT_AD_UNIT_ANDROID if OS.get_name() == "Android" else SKILLPOINT_AD_UNIT_IOS)

func show_coin_ad() -> void:
	_load_and_show(COIN_AD_UNIT_ANDROID if OS.get_name() == "Android" else COIN_AD_UNIT_IOS)

func _load_and_show(unit_id: String) -> void:
	if _busy:
		return
	_busy = true
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), _load_callback)

func _on_ad_loaded(ad: RewardedAd) -> void:
	ad.full_screen_content_callback = _content_callback
	_rewarded_ad = ad
	ad.show(_reward_listener)

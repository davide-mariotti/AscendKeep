extends Node

## AdMob rewarded ads (addons/admob, Poing Studios), behind Google's consent form (UMP).
## Start-up: ask Google whether this player has to give consent (EEA, UK, Switzerland), show the form if so,
## and only then start the Mobile Ads SDK. On desktop/editor there is no consent SDK and the plugin shows
## its own interactive "Mock Ad" overlay, so the whole flow can still be clicked through without a phone.

signal ad_finished(success: bool)

## Test builds use Google's sample ad units: real ads watched (or clicked) on your own phone can get the
## AdMob account suspended. Set to false only for the production release.
const USE_TEST_ADS := true
const TEST_REWARDED_ANDROID := "ca-app-pub-3940256099942544/5224354917"
const TEST_REWARDED_IOS := "ca-app-pub-3940256099942544/1712485313"

const SKILLPOINT_AD_UNIT_ANDROID := "ca-app-pub-5907544153918240/1981590643"
const SKILLPOINT_AD_UNIT_IOS := "ca-app-pub-5907544153918240/8738570686"
const COIN_AD_UNIT_ANDROID := "ca-app-pub-5907544153918240/7042345635"
const COIN_AD_UNIT_IOS := "ca-app-pub-5907544153918240/7233917329"

var _rewarded_ad: RewardedAd
var _reward_listener := OnUserEarnedRewardListener.new()
var _load_callback := RewardedAdLoadCallback.new()
var _content_callback := FullScreenContentCallback.new()
var _busy := false
var _ads_started := false  # Mobile Ads SDK initialised, which happens only after the consent step

func _ready() -> void:
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
	_gather_consent()

# ── Consent (UMP) ─────────────────────────────────────────────────────────

func _on_mobile() -> bool:
	return OS.get_name() in ["Android", "iOS"]

func _gather_consent() -> void:
	if not _on_mobile():
		_start_ads()
		return
	# A failed update or form never blocks the game: the SDK starts anyway and serves what consent allows.
	UserMessagingPlatform.consent_information.update(
		ConsentRequestParameters.new(), _on_consent_info_updated, func(_error: FormError) -> void: _start_ads())

func _on_consent_info_updated() -> void:
	if UserMessagingPlatform.consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(_on_consent_form_loaded, func(_error: FormError) -> void: _start_ads())
	else:
		_start_ads()

func _on_consent_form_loaded(form: ConsentForm) -> void:
	if UserMessagingPlatform.consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		form.show(func(_error: FormError) -> void: _start_ads())
	else:
		_start_ads()

func _start_ads() -> void:
	if _ads_started:
		return
	_ads_started = true
	MobileAds.initialize()

## Players who had to give consent must be able to change it later: Settings shows a button when this is true.
func privacy_options_required() -> bool:
	return _on_mobile() and UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	UserMessagingPlatform.show_privacy_options_form()

# ── Rewarded ads ──────────────────────────────────────────────────────────

func show_skillpoint_ad() -> void:
	_load_and_show(SKILLPOINT_AD_UNIT_ANDROID, SKILLPOINT_AD_UNIT_IOS)

func show_coin_ad() -> void:
	_load_and_show(COIN_AD_UNIT_ANDROID, COIN_AD_UNIT_IOS)

func _load_and_show(android_unit: String, ios_unit: String) -> void:
	if _busy:
		return
	if not _ads_started:  # still waiting for the consent form: no ad yet
		ad_finished.emit(false)
		return
	_busy = true
	var android := OS.get_name() == "Android"
	var unit := (TEST_REWARDED_ANDROID if android else TEST_REWARDED_IOS) if USE_TEST_ADS else (android_unit if android else ios_unit)
	RewardedAdLoader.new().load(unit, AdRequest.new(), _load_callback)

func _on_ad_loaded(ad: RewardedAd) -> void:
	ad.full_screen_content_callback = _content_callback
	_rewarded_ad = ad
	ad.show(_reward_listener)

extends Node

# Thin wrapper around the Firebase plugin (addons/godot-firebase) for
# account-backed cloud save. Stays inert until res://addons/godot-firebase/.env
# is filled in with a real Firebase project's config (apiKey/authDomain) —
# see firebase.gd's _load_config, which leaves those empty and just prints a
# warning otherwise. Until then, signed_in_user_id stays "" and nothing else
# in the game depends on this yet.

signal signed_in(user_id: String)

const PUSH_INTERVAL_SECONDS := 15.0
const GOOGLE_SIGN_IN_SINGLETON := "GodotGoogleSignIn"

var signed_in_user_id := ""
var signed_in_email := ""
var signed_in_with_google := false
var _push_pending := false
var _google_sign_in: Object = null

func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(_on_login_succeeded)
	Firebase.Auth.signup_succeeded.connect(_on_login_succeeded)
	Firebase.Auth.login_failed.connect(_on_login_failed)
	# Any local progress change queues a cloud push; a timer coalesces bursts
	# (a fast wave clear can emit this many times a second) into one write.
	Meta.progress_changed.connect(func(): _push_pending = true)

	var push_timer := Timer.new()
	push_timer.wait_time = PUSH_INTERVAL_SECONDS
	push_timer.timeout.connect(_on_push_timer_timeout)
	add_child(push_timer)
	push_timer.start()

	# addons/GodotGoogleSignIn (addons/GodotGoogleSignIn/plugin.cfg) — native,
	# Android-only, no editor mock (same limitation as Purchases.gd). Needs
	# the Firebase project's OAuth Web Client ID in .env's "clientId" to
	# initialize; that value comes from Firebase Console → Authentication →
	# Sign-in method → Google, once that provider is enabled.
	if Engine.has_singleton(GOOGLE_SIGN_IN_SINGLETON) and Firebase._config.clientId != "":
		_google_sign_in = Engine.get_singleton(GOOGLE_SIGN_IN_SINGLETON)
		_google_sign_in.connect("sign_in_success", _on_google_sign_in_success)
		_google_sign_in.connect("sign_in_failed", _on_google_sign_in_failed)
		_google_sign_in.initialize(Firebase._config.clientId)

	if Firebase._config.apiKey != "":
		Firebase.Auth.login_anonymous()

func _on_login_succeeded(auth_result: Dictionary) -> void:
	signed_in_user_id = auth_result.get("localid", "")
	signed_in_email = auth_result.get("email", "")
	signed_in.emit(signed_in_user_id)
	pull_save()

func _on_login_failed(_code, message) -> void:
	printerr("[Backend] Firebase sign-in failed: %s" % message)

func google_sign_in_available() -> bool:
	return _google_sign_in != null

# Upgrades the current (anonymous) session to a real Google account: the
# native plugin returns a Google ID token, which is exchanged directly with
# Firebase's signInWithIdp REST endpoint via the existing Firebase.Auth node
# (reusing its request plumbing/auth-refresh scheduling instead of a
# separate HTTPRequest). Only works on a real Android build.
func sign_in_with_google() -> void:
	if _google_sign_in == null:
		printerr("[Backend] Google Sign-In not available (needs a real Android build + a configured clientId)")
		return
	_google_sign_in.signIn()

func _on_google_sign_in_success(id_token: String, _email: String, _display_name: String) -> void:
	if not Firebase.Auth._is_ready():
		return
	Firebase.Auth.is_busy = true
	var body := {
		"postBody": "id_token=%s&providerId=google.com" % id_token,
		"requestUri": "http://localhost",
		"returnIdpCredential": true,
		"returnSecureToken": true,
	}
	signed_in_with_google = true
	Firebase.Auth.request(
		Firebase.Auth._base_url + Firebase.Auth._signin_with_oauth_request_url,
		Firebase.Auth._headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

func _on_google_sign_in_failed(error: String) -> void:
	printerr("[Backend] Google Sign-In failed: %s" % error)

func _on_push_timer_timeout() -> void:
	if _push_pending and signed_in_user_id != "":
		_push_pending = false
		push_save()

# Cloud is the source of truth on login: if a save already exists there, it
# overwrites the local one (reinstall / new device). Otherwise the local save
# becomes the first cloud save. No multi-device merge — one active device at
# a time is the assumption.
func pull_save() -> void:
	if signed_in_user_id == "":
		return
	var doc: FirestoreDocument = await Firebase.Firestore.collection("users").get_doc(signed_in_user_id)
	if doc == null or doc.keys().is_empty():
		push_save()
		return
	Meta.apply_save_data(doc.get_unsafe_document())
	Meta.progress_changed.emit()

func push_save() -> void:
	if signed_in_user_id == "":
		return
	Firebase.Firestore.collection("users").set_doc(signed_in_user_id, Meta.save_data())

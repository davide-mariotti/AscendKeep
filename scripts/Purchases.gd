extends Node

# Wraps the Google Play Billing plugin (addons/GodotGooglePlayBilling) for
# the real-money IAP items in Meta.REAL_MONEY_PRODUCTS. Only functional on a
# real signed Android build — BillingClient silently no-ops everywhere else
# (no editor mock, unlike Ads.gd), so purchases can't be tested in-editor.

var _client: BillingClient
var _connected := false

func _ready() -> void:
	_client = BillingClient.new()
	add_child(_client)
	_client.connected.connect(_on_connected)
	_client.connect_error.connect(_on_connect_error)
	_client.on_purchase_updated.connect(_on_purchase_response)
	_client.query_purchases_response.connect(_on_purchase_response)
	_client.start_connection()

func _on_connected() -> void:
	_connected = true
	# Re-grant anything already owned (reinstall, or a save that predates
	# the purchase) instead of waiting for the user to buy it again.
	_client.query_purchases(BillingClient.ProductType.INAPP)

func _on_connect_error(response_code: int, debug_message: String) -> void:
	printerr("[Purchases] connect error %d: %s" % [response_code, debug_message])

# Starts the purchase flow for a Meta.REAL_MONEY_PRODUCTS key (e.g.
# "remove_ads"). The result arrives later via on_purchase_updated.
func buy(key: String) -> void:
	if not _connected:
		printerr("[Purchases] billing not connected yet")
		return
	var product = Meta.REAL_MONEY_PRODUCTS.get(key)
	if product == null:
		return
	_client.purchase(product.product_id)

# Shared handler: on_purchase_updated (fresh buy) and query_purchases_response
# (restore-on-launch) both hand back the same {response_code, purchases: [...]} shape.
func _on_purchase_response(response: Dictionary) -> void:
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return
	for purchase in response.get("purchases", []):
		if int(purchase.get("purchase_state", -1)) != BillingClient.PurchaseState.PURCHASED:
			continue
		var product_ids: Array = purchase.get("products", [purchase.get("product_id", "")])
		for product_id in product_ids:
			_grant_product_id(product_id)
		if not purchase.get("is_acknowledged", false):
			_client.acknowledge_purchase(purchase.get("purchase_token", ""))

func _grant_product_id(product_id: String) -> void:
	for key in Meta.REAL_MONEY_PRODUCTS.keys():
		if Meta.REAL_MONEY_PRODUCTS[key].product_id == product_id:
			Meta.grant_real_purchase(key)
			return

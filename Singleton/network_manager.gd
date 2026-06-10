extends Node

## Manages HTTP requests and communication with the Python AI Flask server.

signal ai_prediction_received(success: bool, response_data: Dictionary)

@export var server_url: String = "https://domainabus-production.up.railway.app"
@export var fallback_url: String = "http://127.0.0.1:5000"
@export var ai_predict_endpoint: String = "/ai-predict"
@export var connection_timeout: float = 3.0
@export var is_ai_enabled: bool = true

var http_request: HTTPRequest = null
var is_request_in_progress: bool = false

# Internal tracking for fallback handling
var current_url_base: String = ""
var is_retrying_locally: bool = false
var last_cached_payload: Dictionary = {}

func _ready() -> void:
	# Default to trying the production server first
	current_url_base = server_url
	
	# Create and configure HTTPRequest node dynamically
	http_request = HTTPRequest.new()
	http_request.timeout = connection_timeout
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("[NetworkManager] Initialized. Target URL: ", current_url_base, ", AI Enabled: ", is_ai_enabled)

## Sends the wave telemetry data to the Python AI backend
func send_telemetry(payload: Dictionary) -> void:
	if not is_ai_enabled:
		print("[NetworkManager] Request ignored: AI is disabled in settings.")
		ai_prediction_received.emit(false, {})
		return

	if is_request_in_progress:
		print("[NetworkManager] Request ignored: Another request is already in progress.")
		return

	is_request_in_progress = true
	last_cached_payload = payload # Cache payload in case we need to trigger a fallback retry
	
	_execute_request()

## Internal helper to process the network request execution
func _execute_request() -> void:
	var url := current_url_base + ai_predict_endpoint
	var headers := ["Content-Type: application/json"]
	var json_payload := JSON.stringify(last_cached_payload)

	print("[NetworkManager] Sending telemetry POST to: ", url)

	var err := http_request.request(url, headers, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		print("[NetworkManager] HTTPRequest failed to initiate! Error code: ", err)
		_handle_failure()

## Callback when the HTTP request finishes
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("[NetworkManager] HTTP Request completed. Result: ", result, ", Status Code: ", response_code)

	# Check for total network/connection failures
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[NetworkManager] Network target failed or returned an error code.")
		_handle_failure()
		return

	# Parse response body
	var response_text := body.get_string_from_utf8()
	print("[NetworkManager] Raw response body received: ", response_text)
	
	var json = JSON.new()
	var parse_err := json.parse(response_text)
	if parse_err != OK:
		print("[NetworkManager] JSON Parsing failed! Line: ", json.get_error_line(), ", Error: ", json.get_error_message())
		_handle_failure()
		return

	var response_data = json.get_data()
	if typeof(response_data) != TYPE_DICTIONARY:
		print("[NetworkManager] Invalid JSON response type! Expected Dictionary, got: ", typeof(response_data))
		_handle_failure()
		return

	# Reset fallback state flags on absolute success
	is_request_in_progress = false
	is_retrying_locally = false
	
	print("[NetworkManager] Success! Evolved population size: ", response_data.get("pathogen_population", []).size())
	ai_prediction_received.emit(true, response_data)

## Manages shifting from production environment down to localhost environment seamlessly
func _handle_failure() -> void:
	if not is_retrying_locally and current_url_base != fallback_url:
		print("[NetworkManager] Production connection failed. Falling back to Localhost API...")
		current_url_base = fallback_url
		is_retrying_locally = true
		
		# Small structural delay to ensure request lifecycle cleanup
		await get_tree().create_timer(0.1).timeout
		_execute_request()
	else:
		# Both primary and fallback routes have exhausted options
		print("[NetworkManager] All connection targets failed. Disabling live AI session loop.")
		is_request_in_progress = false
		is_retrying_locally = false
		ai_prediction_received.emit(false, {})

extends Node

## Manages HTTP requests and communication with the Python AI Flask server.

signal ai_prediction_received(success: bool, response_data: Dictionary)

@export var server_url: String = "https://domainabus-production.up.railway.app"
@export var ai_predict_endpoint: String = "/ai-predict"
@export var connection_timeout: float = 3.0
@export var is_ai_enabled: bool = true

var http_request: HTTPRequest = null
var is_request_in_progress: bool = false

func _ready() -> void:
	# Create and configure HTTPRequest node dynamically
	http_request = HTTPRequest.new()
	http_request.timeout = connection_timeout
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("[NetworkManager] Initialized. Server URL: ", server_url, ", AI Enabled: ", is_ai_enabled)

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
	var url := server_url + ai_predict_endpoint
	var headers := ["Content-Type: application/json"]
	var json_payload := JSON.stringify(payload)

	print("[NetworkManager] Sending telemetry POST to: ", url)
	#print("[NetworkManager] Payload: ", json_payload)

	var err := http_request.request(url, headers, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		print("[NetworkManager] HTTPRequest failed to initiate! Error code: ", err)
		is_request_in_progress = false
		ai_prediction_received.emit(false, {})

## Callback when the HTTP request finishes
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	is_request_in_progress = false
	
	print("[NetworkManager] HTTP Request completed. Result: ", result, ", Status Code: ", response_code)

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[NetworkManager] Network request failed! Result enum value: ", result)
		ai_prediction_received.emit(false, {})
		return

	if response_code != 200:
		print("[NetworkManager] Server returned an error code: ", response_code)
		ai_prediction_received.emit(false, {})
		return

	# Parse response body
	var response_text := body.get_string_from_utf8()
	print("[NetworkManager] Raw response body received: ", response_text)
	
	var json = JSON.new()
	var parse_err := json.parse(response_text)
	if parse_err != OK:
		print("[NetworkManager] JSON Parsing failed! Line: ", json.get_error_line(), ", Error: ", json.get_error_message())
		ai_prediction_received.emit(false, {})
		return

	var response_data = json.get_data()
	if typeof(response_data) != TYPE_DICTIONARY:
		print("[NetworkManager] Invalid JSON response type! Expected Dictionary, got: ", typeof(response_data))
		ai_prediction_received.emit(false, {})
		return

	print("[NetworkManager] Success! Evolved population size: ", response_data.get("pathogen_population", []).size())
	ai_prediction_received.emit(true, response_data)

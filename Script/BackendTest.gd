# BackendTest.gd - Test script for backend connectivity
extends Control

@onready var status_label = $StatusLabel
@onready var test_button = $TestButton
@onready var honeycomb_manager = get_node("/root/HoneycombManager")

func _ready():
	test_button.pressed.connect(_on_test_button_pressed)
	
	# Connect to HoneycombManager signals
	if honeycomb_manager:
		honeycomb_manager.backend_connected.connect(_on_backend_connected)
		honeycomb_manager.backend_error.connect(_on_backend_error)
		honeycomb_manager.xp_gained.connect(_on_xp_gained)
		honeycomb_manager.level_up.connect(_on_level_up)
		honeycomb_manager.mission_completed.connect(_on_mission_completed)

func _on_test_button_pressed():
	"""Test backend connectivity and functionality"""
	status_label.text = "Testing backend connection..."
	
	# Test health endpoint
	test_health_endpoint()
	
	# Test project status
	test_project_status()
	
	# Test user creation
	test_user_creation()

func test_health_endpoint():
	"""Test the health endpoint"""
	var http_client = HTTPRequest.new()
	add_child(http_client)
	http_client.request_completed.connect(_on_health_response)
	
	var url = "http://localhost:8080/health"
	var headers = ["Content-Type: application/json"]
	
	var error = http_client.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		status_label.text = "Failed to send health check request"
		return
	
	print("Health check request sent")

func _on_health_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var response_body = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(response_body)
		
		if parse_result == OK:
			var data = json.get_data()
			status_label.text = "✅ Backend connected! Project: " + str(data.get("project", "None"))
			print("Backend health check successful: ", data)
		else:
			status_label.text = "❌ Failed to parse health response"
	else:
		status_label.text = "❌ Backend health check failed: " + str(response_code)

func test_project_status():
	"""Test the project status endpoint"""
	var http_client = HTTPRequest.new()
	add_child(http_client)
	http_client.request_completed.connect(_on_project_response)
	
	var url = "http://localhost:8080/game/project"
	var headers = ["Content-Type: application/json"]
	
	var error = http_client.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("Failed to send project status request")
		return
	
	print("Project status request sent")

func _on_project_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var response_body = body.get_string_from_utf8()
		print("Project status response: ", response_body)
	else:
		print("Project status request failed: ", response_code)

func test_user_creation():
	"""Test user creation endpoint"""
	var http_client = HTTPRequest.new()
	add_child(http_client)
	http_client.request_completed.connect(_on_user_creation_response)
	
	var url = "http://localhost:8080/users"
	var headers = ["Content-Type: application/json"]
	var user_data = {
		"userPubkey": "test_user_" + str(Time.get_unix_time_from_system())
	}
	
	var json_string = JSON.stringify(user_data)
	var error = http_client.request(url, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		print("Failed to send user creation request")
		return
	
	print("User creation request sent")

func _on_user_creation_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 200:
		var response_body = body.get_string_from_utf8()
		print("User creation response: ", response_body)
	else:
		print("User creation request failed: ", response_code)

# Signal handlers
func _on_backend_connected():
	status_label.text = "✅ Backend connected via HoneycombManager!"

func _on_backend_error(error_message: String):
	status_label.text = "❌ Backend error: " + error_message

func _on_xp_gained(amount: int):
	print("XP gained from backend: ", amount)

func _on_level_up(new_level: int):
	print("Level up from backend: ", new_level)

func _on_mission_completed(mission_id: String, reward_xp: int):
	print("Mission completed from backend: ", mission_id, " (+", reward_xp, " XP)")

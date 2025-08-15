# BackendConfig.gd - Configuration for backend connection
extends Resource
class_name BackendConfig

# Backend server configuration
@export var backend_url: String = "http://localhost:8080"
@export var backend_port: int = 8080
@export var use_https: bool = false
@export var timeout_seconds: float = 10.0

# Game-specific configuration
@export var enable_xp_tracking: bool = true
@export var enable_mission_tracking: bool = true
@export var enable_character_tracking: bool = true

# Development settings
@export var debug_mode: bool = true
@export var log_all_requests: bool = true

func get_full_backend_url() -> String:
	"""Get the complete backend URL with protocol and port"""
	# If backend_url already contains a port, use it as is
	if ":" in backend_url.split("//")[-1]:
		return backend_url
	
	# Otherwise, construct the URL properly
	var protocol = "https://" if use_https else "http://"
	var host = backend_url.replace("http://", "").replace("https://", "")
	return protocol + host + ":" + str(backend_port)

func is_local_backend() -> bool:
	"""Check if the backend is running locally"""
	return "localhost" in backend_url or "127.0.0.1" in backend_url

func get_health_check_url() -> String:
	"""Get the health check endpoint URL"""
	return get_full_backend_url() + "/health"

func get_users_endpoint() -> String:
	"""Get the users endpoint URL"""
	return get_full_backend_url() + "/users"

func get_game_endpoint() -> String:
	"""Get the game endpoint URL"""
	return get_full_backend_url() + "/game"

func get_logs_endpoint() -> String:
	"""Get the logs endpoint URL"""
	return get_full_backend_url() + "/logs"

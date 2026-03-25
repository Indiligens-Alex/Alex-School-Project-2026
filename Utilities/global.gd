extends Node

const UDP_IP: String = "127.0.0.1"
const UDP_PORT: int = 4242

static var server: UDPServer = UDPServer.new()

var DIR: String = OS.get_executable_path().get_base_dir()
var script_path: String = DIR.path_join("res://PythonFiles/capture_data.py")

func _ready() -> void:
	server.listen(UDP_PORT)
	if !OS.has_feature("standalone"): # If NOT exported version
		script_path = ProjectSettings.globalize_path("res://PythonFiles/packet_capture.py")

func _process(_delta: float) -> void:
	server.poll()

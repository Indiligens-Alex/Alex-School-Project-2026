extends Node

const UDP_IP: String = "127.0.0.1"
const UDP_PORT: int = 4242

static var server: UDPServer = UDPServer.new()

var packet_capture_py_path: String = ProjectSettings.globalize_path("res://PythonFiles/packet_capture.py")

func _ready() -> void:
	print("packet_capture_py_path is: ", packet_capture_py_path)
	server.listen(UDP_PORT)

func _process(_delta: float) -> void:
	server.poll()

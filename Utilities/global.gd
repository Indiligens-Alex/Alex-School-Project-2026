extends Node

const UDP_IP: String = "127.0.0.1"
const UDP_PORT: int = 4242
static var server: UDPServer = UDPServer.new()
var main_py_path: String = ProjectSettings.globalize_path("res://PythonFiles/main.py")

func _ready() -> void:
	#print("main.py_path is: ", main_py_path)
	server.listen(UDP_PORT)

func _process(_delta: float) -> void:
	server.poll()

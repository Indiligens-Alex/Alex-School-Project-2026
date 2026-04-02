extends Node

const UDP_IP: String = "127.0.0.1"
const UDP_PORT: int = 4242
static var server: UDPServer = UDPServer.new()
var main_loop_py_path: String

func _ready() -> void:
	## In editor: res:// points to the project folder on disk
	## When exported: Python files sit next to the .exe, not inside the .pck
	if OS.is_debug_build():
		main_loop_py_path = ProjectSettings.globalize_path("res://PythonFiles/main_loop.py")
	else:
		var exe_dir: String = OS.get_executable_path().get_base_dir()
		main_loop_py_path = exe_dir.path_join("PythonFiles").path_join("main_loop.py")

	server.listen(UDP_PORT)

func _process(_delta: float) -> void:
	server.poll()

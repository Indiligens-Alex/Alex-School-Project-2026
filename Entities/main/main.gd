extends Node

const UDP_IP: String = "127.0.0.1"
const UDP_PORT: int = 4242

@onready var interpreter_path: String = DIR.path_join("res://PythonFiles/Scripts/python.exe")
@onready var server: UDPServer = UDPServer.new()

var DIR: String = OS.get_executable_path().get_base_dir()
var script_path: String = DIR.path_join("res://PythonFiles/capture_data.py")

func exec_py_file() -> void:
	OS.execute(interpreter_path, [script_path])

func _ready() -> void:
	server.listen(UDP_PORT)
	if !OS.has_feature("standalone"): # If NOT exported version
		interpreter_path = ProjectSettings.globalize_path("res://PythonFiles/Scripts/python.exe")
		script_path = ProjectSettings.globalize_path("res://PythonFiles/capture_data.py")

func _process(_delta: float) -> void:
	## While open, the project acts as a server and
	server.poll()
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		var packet: PackedByteArray = peer.get_packet()
		print("Received: '%s' %s:%s" % [packet.get_string_from_utf8(), peer.get_packet_ip(), peer.get_packet_port()])
		peer.put_packet("Hello from Godot!".to_utf8_buffer())


#exec_py_file()

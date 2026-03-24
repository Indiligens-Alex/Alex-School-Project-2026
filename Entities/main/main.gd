extends Node

const UDP_IP: String = "127.0.0.1"
const UDP_PORT: int = 4242

var filter_ip: String
var filter_port: String
var filter_protocol: String

@onready var interpreter_path: String = DIR.path_join("res://PythonFiles/Scripts/python.exe")
@onready var filter_settings: FilterSettings = %"Filter Settings"

var server: UDPServer = UDPServer.new()
var peers: Array

var DIR: String = OS.get_executable_path().get_base_dir()
var script_path: String = DIR.path_join("res://PythonFiles/capture_data.py")

func _ready() -> void:
	filter_settings.ip_filter_sent.connect(func (data: String) -> void: filter_ip = data)
	filter_settings.port_filter_sent.connect(func (data: String) -> void: filter_port = data)
	filter_settings.protocol_filter_sent.connect(func (data: String) -> void: filter_protocol = data)

	server.listen(UDP_PORT)
	if !OS.has_feature("standalone"): # If NOT exported version
		interpreter_path = ProjectSettings.globalize_path("res://PythonFiles/Scripts/python.exe")
		script_path = ProjectSettings.globalize_path("res://PythonFiles/capture_data.py")
	execute_py()

func _process(_delta: float) -> void:
	## While open, the project acts as a server
	server.poll()
	if server.is_connection_available():
		var peer = server.take_connection()
		var packet = peer.get_packet()
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		print("Received data: %s" % [packet.get_string_from_utf8()])
		# Reply so it knows we received the message.
		peer.put_packet("Hello from Godot!".to_utf8_buffer())
		# Keep a reference so we can keep contacting the remote peer.
		peers.append(peer)
		#for i in range(0, peers.size()):
			#peers

func execute_py() -> void:
	#filter_ip
	#filter_port
	#filter_protocol
	OS.execute(interpreter_path, [script_path])

#exec_py_file()

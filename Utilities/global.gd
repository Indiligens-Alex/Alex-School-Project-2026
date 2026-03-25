extends Node

const UDP_IP: String = "127.0.0.1"
const UDP_PORT: int = 4242

static var server: UDPServer = UDPServer.new()
var peers: Array[PacketPeerUDP]

var DIR: String = OS.get_executable_path().get_base_dir()
var script_path: String = DIR.path_join("res://PythonFiles/capture_data.py")

func _ready() -> void:
	server.listen(UDP_PORT)
	if !OS.has_feature("standalone"): # If NOT exported version
		script_path = ProjectSettings.globalize_path("res://PythonFiles/packet_capture.py")

func _process(_delta: float) -> void:
	server.poll()
	if server.is_connection_available():
		var peer: PacketPeerUDP = server.take_connection()
		## Recieved data from Python
		var packet: PackedByteArray  = peer.get_packet()
		print("Accepted peer: %s:%s" % [peer.get_packet_ip(), peer.get_packet_port()])
		print("Received data: %s" % [packet.get_string_from_utf8()])
		## Reply so it knows we received the message.
		peer.put_packet("Hello from Godot!".to_utf8_buffer())
		## Keep a reference so we can keep contacting the remote peer.
		peers.append(peer)

class_name Main extends Node

@onready var filter_settings: FilterSettings = %"Filter Settings"
@onready var packet_loss_probability: PacketLossProbability = %"Packet Loss Probability"

var peers: Array[PacketPeerUDP]
var filter_ip: String
var filter_port: String
var filter_protocol: String
var loss_percange: float

func _ready() -> void:
	filter_settings.ip_filter_sent.connect(func (data: String) -> void: filter_ip = data)
	filter_settings.port_filter_sent.connect(func (data: String) -> void: filter_port = data)
	filter_settings.protocol_filter_sent.connect(func (data: String) -> void: filter_protocol = data)
	packet_loss_probability.percent_value_changed.connect(func (data: float) -> void: loss_percange = data)

func _process(_delta: float) -> void:
	if GLOBAL.server.is_connection_available():
		## UDP packet peer, used to send and receive raw UDP packets and Variants.
		## Returns the first pending connection, null if no new connection is available.
		var peer: PacketPeerUDP = GLOBAL.server.take_connection()
		print("Accepted peer: %s :%s" % [peer.get_packet_ip(), peer.get_packet_port()])

		## Recieved data from Python
		var packet: PackedByteArray  = peer.get_packet()
		#print("Packet: %s" % packet)
		print("Received Packet Data: %s" % [packet.get_string_from_utf8()])

		## Reply so it knows we received the message.
		peer.put_packet("Hello from Godot!".to_utf8_buffer())

		""" ## Keep a reference so we can keep contacting the remote peer.
		peers.append(peer)
		print("Peers list %s" % peers)

		for i: int in range(0, peers.size()):
			print(peers[i].get_packet().get_string_from_utf8())
		#filter_ip
		#filter_port
		#filter_protocol"""
	#else:
		#print_debug("No Connection Found")

func execute_py() -> void:
	OS.execute("python", [GLOBAL.script_path], [])

func _on_temp_button_pressed() -> void:
	execute_py()

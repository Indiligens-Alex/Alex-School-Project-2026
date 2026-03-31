class_name Main extends Node

@onready var filter_settings: FilterSettings = %"Filter Settings"
@onready var packet_loss_probability: PacketLossProbability = %"Packet Loss Probability"

var is_python_connected: bool
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
	if not is_python_connected and GLOBAL.server.is_connection_available():
		is_python_connected = true
		print("Python connected!")
	else:
		print("No Connection Found")

		### Recieved data from Python
		#var packet: PackedByteArray  = peer.get_packet()
		##print("Packet: %s" % packet)
		#print("Received Packet Data: %s" % [packet.get_string_from_utf8()])

func send_params_to_python() -> void:
	## UDP packet peer, used to send and receive raw UDP packets and Variants.
	## Returns the first pending connection, null if no new connection is available.
	var peer: PacketPeerUDP = GLOBAL.server.take_connection()
	print("Accepted peer: %s :%s" % [peer.get_packet_ip(), peer.get_packet_port()])

	## Send the parameters of the filters and percentage to python
	var params_msg: String = "ip=%s;port=%s;proto=%s;loss=%f" % [filter_ip, filter_port, filter_protocol, loss_percange]
	peer.put_packet(params_msg.to_utf8_buffer())

	## Keep a reference so we can keep contacting the remote peer.
	peers.append(peer)
	print("Peers list %s" % peers)

func execute_py() -> void:
	OS.execute("python", [GLOBAL.packet_capture_py_path], [])

func _on_temp_button_pressed() -> void:
	execute_py()


func _on_send_params__get_packet_button_2_pressed() -> void:
	pass # Replace with function body.

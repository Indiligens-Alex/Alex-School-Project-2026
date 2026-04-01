class_name Main extends Node

@onready var filter_settings: FilterSettings = %"Filter Settings"
@onready var packet_loss_probability: PacketLossProbability = %"Packet Loss Probability"

var python_peer: PacketPeerUDP
var filter_ip: String = "0"
var filter_port: String = "0"
var filter_protocol: String = "0"
var loss_percange: float = 0.0

func _ready() -> void:
	if OS.is_debug_build():
		OS.create_process("cmd", ["/k", "python", GLOBAL.main_loop_py_path], true)
	else:
		OS.create_process("python", [GLOBAL.main_loop_py_path])

	filter_settings.ip_filter_changed.connect(func (data: String) -> void: filter_ip = data)
	filter_settings.port_filter_changed.connect(func (data: String) -> void: filter_port = data)
	filter_settings.protocol_filter_changed.connect(func (data: String) -> void: filter_protocol = data)
	packet_loss_probability.percent_value_changed.connect(func (data: float) -> void: loss_percange = data)

func _process(_delta: float) -> void:
	## UDP packet peer, used to send and receive raw UDP packets and Variants.
	## Connect to the Python file when it sends the first piece of data
	if python_peer == null and GLOBAL.server.is_connection_available():
		python_peer = GLOBAL.server.take_connection()
		print("Python connected from: %s:%s" % [python_peer.get_packet_ip(), python_peer.get_packet_port()])

func _on_send_params_to_python_button_pressed() -> void:
	if python_peer == null:
		print("Python not connected yet — can't send params")
		return
	## Send the parameters of the filters and percentage to python
	var params_msg: String = "ip=%s;port=%s;proto=%s;loss=%f" % [filter_ip, filter_port, filter_protocol, loss_percange]
	python_peer.put_packet(params_msg.to_utf8_buffer())
	print("Params sent to Python: ", params_msg)

		### Recieved data from Python
		#var packet: PackedByteArray  = peer.get_packet()
		##print("Packet: %s" % packet)
		#print("Received Packet Data: %s" % [packet.get_string_from_utf8()])

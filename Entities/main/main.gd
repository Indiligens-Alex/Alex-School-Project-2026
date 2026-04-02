class_name Main extends Node

## ——— UI References ———
@onready var filter_settings: FilterSettings = %"Filter Settings"
@onready var packet_loss_probability: PacketLossProbability = %"Packet Loss Probability"
@onready var latency_settings: LatencySettings = %"Latency Settings"
@onready var jitter_settings: JitterSettings = %"Jitter Settings"
@onready var packet_log_display: PacketLogDisplay = %"Packet Log Display"
@onready var start_stop_button: Button = %StartStopButton
@onready var interface_selector: OptionButton = %InterfaceSelector

## ——— Parameters (synced to Python in real-time) ———
var python_peer: PacketPeerUDP
var filter_ip: String = "0"
var filter_port: String = "0"
var filter_protocol: String = "0"
var loss_percentage: float = 0.0
var latency_ms: float = 0.0
var jitter_ms: float = 0.0
var selected_iface_ip: String = "0"

## ——— State ———
var simulation_active: bool = false
var interface_ips: PackedStringArray = []  ## Stores IPs matching dropdown indices

func _ready() -> void:
	## Launch Python backend
	if OS.is_debug_build():
		OS.create_process("cmd", ["/k", "python", GLOBAL.main_loop_py_path], true)
	else:
		OS.create_process("python", [GLOBAL.main_loop_py_path])

	## Connect filter signals — auto-send params to Python on every change
	filter_settings.ip_filter_changed.connect(func (data: String) -> void:
		filter_ip = data if data != "" else "0"
		_send_params_to_python()
	)
	filter_settings.port_filter_changed.connect(func (data: String) -> void:
		filter_port = data if data != "" else "0"
		_send_params_to_python()
	)
	filter_settings.protocol_filter_changed.connect(func (data: String) -> void:
		filter_protocol = data if data != "" else "0"
		_send_params_to_python()
	)

	## Connect error simulation signals — auto-send on change
	packet_loss_probability.percent_value_changed.connect(func (data: float) -> void:
		loss_percentage = data
		_send_params_to_python()
	)
	latency_settings.latency_value_changed.connect(func (data: float) -> void:
		latency_ms = data
		_send_params_to_python()
	)
	jitter_settings.jitter_value_changed.connect(func (data: float) -> void:
		jitter_ms = data
		_send_params_to_python()
	)

	## Connect start/stop button
	start_stop_button.pressed.connect(_on_start_stop_pressed)

	## Connect interface selector
	interface_selector.item_selected.connect(_on_interface_selected)

	## Initial button state
	start_stop_button.text = "Start Simulation"

func _process(_delta: float) -> void:
	## Accept Python connection when it arrives
	if python_peer == null and GLOBAL.server.is_connection_available():
		python_peer = GLOBAL.server.take_connection()
		if OS.is_debug_build():
			print("Python server connected from: %s:%s" % [
				python_peer.get_packet_ip(), python_peer.get_packet_port()
			])

	## Poll for incoming data from Python
	if python_peer != null and python_peer.get_available_packet_count() > 0:
		var packet: PackedByteArray = python_peer.get_packet()
		var message: String = packet.get_string_from_utf8()
		_handle_python_message(message)

## ——— Send all current parameters to Python ———
func _send_params_to_python() -> void:
	if python_peer == null:
		return
	var params_msg: String = "ip=%s;port=%s;proto=%s;iface_ip=%s;loss=%f;latency=%f;jitter=%f" % [
		filter_ip, filter_port, filter_protocol, selected_iface_ip,
		loss_percentage, latency_ms, jitter_ms
	]
	python_peer.put_packet(params_msg.to_utf8_buffer())

## ——— Start / Stop simulation toggle ———
func _on_start_stop_pressed() -> void:
	if python_peer == null:
		if OS.is_debug_build():
			print("Python not connected yet — can't start simulation")
		return

	simulation_active = !simulation_active

	if simulation_active:
		## Send current params first, then start command
		_send_params_to_python()
		python_peer.put_packet("cmd=start".to_utf8_buffer())
		start_stop_button.text = "Stop Simulation"
		packet_log_display.clear_log()
		if OS.is_debug_build():
			print("Simulation STARTED")
	else:
		python_peer.put_packet("cmd=stop".to_utf8_buffer())
		start_stop_button.text = "Start Simulation"
		if OS.is_debug_build():
			print("Simulation STOPPED")

## ——— Handle messages received from Python ———
func _handle_python_message(message: String) -> void:
	if message.begins_with("log="):
		_handle_log_message(message.substr(4))  ## Strip "log="
	elif message.begins_with("ifaces="):
		_handle_interface_list(message.substr(7))  ## Strip "ifaces="
	elif message.begins_with("status="):
		var status: String = message.substr(7)
		if status == "stopped":
			simulation_active = false
			start_stop_button.text = "Start Simulation"
	elif message.begins_with("stats="):
		_handle_stats_message(message.substr(6))
	elif message.begins_with("error="):
		var error_msg: String = message.substr(6)
		if OS.is_debug_build():
			print("Python error: ", error_msg)
		simulation_active = false
		start_stop_button.text = "Start Simulation"
	elif message == "hello":
		if OS.is_debug_build():
			print("Python server connected and ready")

## ——— Parse and display a log entry from Python ———
func _handle_log_message(log_data: String) -> void:
	## Format: "DROPPED;proto=TCP;src=1.2.3.4:80;dst=5.6.7.8:443"
	var parts: PackedStringArray = log_data.split(";", true, 1)
	var action: String = parts[0] if parts.size() > 0 else "UNKNOWN"
	var details: String = parts[1] if parts.size() > 1 else ""
	packet_log_display.add_log_entry(action, details)

## ——— Parse the interface list from Python and populate the dropdown ———
func _handle_interface_list(iface_data: String) -> void:
	## Format: "Ethernet|192.168.1.5,Wi-Fi|10.0.0.2,Loopback|127.0.0.1"
	interface_selector.clear()
	interface_ips.clear()

	interface_selector.add_item("All Interfaces")
	interface_ips.append("0")

	var entries: PackedStringArray = iface_data.split(",")
	for entry: String in entries:
		var pair: PackedStringArray = entry.split("|")
		if pair.size() == 2:
			var iface_name: String = pair[0]
			var iface_ip: String = pair[1]
			interface_selector.add_item("%s (%s)" % [iface_name, iface_ip])
			interface_ips.append(iface_ip)

	if OS.is_debug_build():
		print("Interfaces loaded: ", interface_ips.size() - 1, " interfaces found")

## ——— Handle interface dropdown selection ———
func _on_interface_selected(index: int) -> void:
	if index >= 0 and index < interface_ips.size():
		selected_iface_ip = interface_ips[index]
	else:
		selected_iface_ip = "0"
	_send_params_to_python()

## ——— Handle final stats from Python ———
func _handle_stats_message(stats_data: String) -> void:
	## Format: "total:1000;dropped:50;delayed:200;passed:750"
	var total: int = 0
	var dropped: int = 0
	var delayed: int = 0
	var passed: int = 0

	for part: String in stats_data.split(";"):
		var kv: PackedStringArray = part.split(":")
		if kv.size() == 2:
			match kv[0]:
				"total":
					total = int(kv[1])
				"dropped":
					dropped = int(kv[1])
				"delayed":
					delayed = int(kv[1])
				"passed":
					passed = int(kv[1])

	packet_log_display.set_final_stats(total, dropped, delayed, passed)

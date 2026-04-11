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

var simulation_active: bool = false
var simulation_stopping: bool = false  ## True while Python is winding down after Stop
var interface_ips: PackedStringArray = []  ## Stores IPs matching dropdown indices
var active_connections_data: Array = []

func _ready() -> void:
	## Launch Python backend
	if OS.is_debug_build():
		OS.create_process("cmd", ["/k", "python", GLOBAL.main_loop_py_path], true)
	else:
		OS.create_process("python", [GLOBAL.main_loop_py_path])

	## Filter signals — empty string falls back to "0" (means "no filter" in Python)
	filter_settings.ip_filter_changed.connect(func(data: String) -> void:
		filter_ip = data if data != "All IPs" else "0"
		update_filter_dropdowns()
		_send_params_to_python())
	filter_settings.port_filter_changed.connect(func(data: String) -> void:
		filter_port = data if data != "All Ports" else "0"
		update_filter_dropdowns()
		_send_params_to_python())
	filter_settings.protocol_filter_changed.connect(func(data: String) -> void:
		filter_protocol = data if data != "All Protocols" else "0"
		update_filter_dropdowns()
		_send_params_to_python())

	## Simulation signals
	packet_loss_probability.percent_value_changed.connect(func(data: float) -> void:
		loss_percentage = data
		_send_params_to_python())
	latency_settings.latency_value_changed.connect(func(data: float) -> void:
		latency_ms = data
		_send_params_to_python())
	jitter_settings.jitter_value_changed.connect(func(data: float) -> void:
		jitter_ms = data
		_send_params_to_python())

	## UI
	start_stop_button.pressed.connect(_on_start_stop_pressed)
	interface_selector.item_selected.connect(_on_interface_selected)
	start_stop_button.text = "Start Simulation"

## ——— Lock or unlock all controls except the Start/Stop button ———
func _set_controls_enabled(enabled: bool) -> void:
	filter_settings.mouse_filter = Control.MOUSE_FILTER_STOP if not enabled else Control.MOUSE_FILTER_PASS
	filter_settings.modulate.a = 1.0 if enabled else 0.5
	filter_settings.ip_option_button.disabled = not enabled
	filter_settings.port_option_button.disabled = not enabled
	filter_settings.protocol_option_button.disabled = not enabled
	packet_loss_probability.set_editable(enabled)
	latency_settings.set_editable(enabled)
	jitter_settings.set_editable(enabled)
	interface_selector.disabled = not enabled

func _process(_delta: float) -> void:
	## Accept Python connection when it arrives
	if python_peer == null and GLOBAL.server.is_connection_available():
		python_peer = GLOBAL.server.take_connection()
		if OS.is_debug_build():
			print("Python server connected from: %s:%s" % [
				python_peer.get_packet_ip(), python_peer.get_packet_port()])

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
		loss_percentage, latency_ms, jitter_ms]
	python_peer.put_packet(params_msg.to_utf8_buffer())

## ——— Start / Stop simulation toggle ———
func _on_start_stop_pressed() -> void:
	if python_peer == null:
		if OS.is_debug_build():
			print("Python not connected yet — can't start simulation")
		return

	## Block double-press while winding down
	if simulation_stopping:
		return

	simulation_active = !simulation_active

	if simulation_active:
		## Lock controls, send params, then start
		_set_controls_enabled(false)
		_send_params_to_python()
		python_peer.put_packet("cmd=start".to_utf8_buffer())
		start_stop_button.text = "Stop Simulation"
		start_stop_button.disabled = false
		packet_log_display.clear_log()
		if OS.is_debug_build():
			print("Simulation STARTED")
	else:
		## Enter stopping state — keep everything locked, button shows feedback
		simulation_stopping = true
		start_stop_button.text = "Stopping..."
		start_stop_button.disabled = true
		python_peer.put_packet("cmd=stop".to_utf8_buffer())
		if OS.is_debug_build():
			print("Simulation STOP requested — waiting for Python...")

## ——— Handle messages received from Python ———
func _handle_python_message(message: String) -> void:
	if message.begins_with("log="):
		_handle_log_message(message.substr(4))  ## Strip "log="
	elif message.begins_with("ifaces="):
		_handle_interface_list(message.substr(7))  ## Strip "ifaces="
	elif message.begins_with("conns="):
		_handle_connections_list(message.substr(6))
	elif message.begins_with("status="):
		var status: String = message.substr(7)
		if status == "stopped":
			## Python has fully wound down — re-enable everything
			simulation_active = false
			simulation_stopping = false
			start_stop_button.text = "Start Simulation"
			start_stop_button.disabled = false
			_set_controls_enabled(true)
	elif message.begins_with("stats="):
		_handle_stats_message(message.substr(6))
	elif message.begins_with("error="):
		var error_msg: String = message.substr(6)
		if OS.is_debug_build():
			print("Python error: ", error_msg)
		simulation_active = false
		simulation_stopping = false
		start_stop_button.text = "Start Simulation"
		start_stop_button.disabled = false
		_set_controls_enabled(true)
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

## ——— Handle dynamic connection lists for filters ———
func _handle_connections_list(data: String) -> void:
	active_connections_data.clear()
	if data.strip_edges() != "":
		var entries: PackedStringArray = data.split("|")
		for entry in entries:
			var pairs = entry.split(",")
			if pairs.size() == 3:
				active_connections_data.append({"ip": pairs[0], "port": pairs[1], "proto": pairs[2]})
	update_filter_dropdowns()

func update_filter_dropdowns() -> void:
	var current_ip = filter_ip if filter_ip != "0" else "All IPs"
	var current_port = filter_port if filter_port != "0" else "All Ports"
	var current_proto = filter_protocol if filter_protocol != "0" else "All Protocols"

	var valid_ips = {}
	var valid_ports = {}
	var valid_protocols = {}

	for conn in active_connections_data:
		var ip_match = (current_ip == "All IPs" or conn["ip"] == current_ip)
		var port_match = (current_port == "All Ports" or conn["port"] == current_port)
		var proto_match = (current_proto == "All Protocols" or conn["proto"] == current_proto)

		if port_match and proto_match:
			valid_ips[conn["ip"]] = true
		if ip_match and proto_match:
			valid_ports[conn["port"]] = true
		if ip_match and port_match:
			valid_protocols[conn["proto"]] = true

	_populate_option_button(filter_settings.ip_option_button, valid_ips.keys(), current_ip, "All IPs", "0")
	_populate_option_button(filter_settings.port_option_button, valid_ports.keys(), current_port, "All Ports", "0")
	_populate_option_button(filter_settings.protocol_option_button, valid_protocols.keys(), current_proto, "All Protocols", "0")

func _populate_option_button(btn: OptionButton, items: Array, selected_val: String, default_text: String, default_val: String) -> void:
	var callback = Callable()
	if btn == filter_settings.ip_option_button: callback = filter_settings._on_ip_selected
	elif btn == filter_settings.port_option_button: callback = filter_settings._on_port_selected
	elif btn == filter_settings.protocol_option_button: callback = filter_settings._on_protocol_selected

	if btn.item_selected.is_connected(callback):
		btn.item_selected.disconnect(callback)

	btn.clear()
	btn.add_item(default_text)
	btn.set_item_metadata(0, default_val)

	var idx = 1
	var match_found = false
	items.sort()

	for item in items:
		btn.add_item(str(item))
		btn.set_item_metadata(idx, str(item))
		if str(item) == selected_val:
			btn.select(idx)
			match_found = true
		idx += 1

	if not match_found and selected_val != default_text and selected_val != default_val:
		# Keep stale but currently selected options
		btn.add_item(selected_val)
		btn.set_item_metadata(idx, selected_val)
		btn.select(idx)
	elif selected_val == default_text or selected_val == default_val:
		btn.select(0)

	if not btn.item_selected.is_connected(callback):
		btn.item_selected.connect(callback)

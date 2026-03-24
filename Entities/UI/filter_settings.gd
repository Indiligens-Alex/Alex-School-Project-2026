class_name FilterSettings extends Control

signal ip_filter_sent(text_data: String)
signal port_filter_sent(text_data: String)
signal protocol_filter_sent(text_data: String)

@onready var ip_text_edit: LineEdit = %"IP TextEdit"
@onready var port_text_edit: LineEdit = %"Port TextEdit"
@onready var protocol_text_edit: LineEdit = %"Protocol TextEdit"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ip_text_edit.text_submitted.connect(_on_ip_submitted)
	port_text_edit.text_submitted.connect(_on_port_submitted)
	protocol_text_edit.text_submitted.connect(_on_protocol_submitted)

func _on_ip_submitted(ip_data: String) -> void:
	ip_filter_sent.emit(ip_data)
	print("IP: ", ip_data)

func _on_port_submitted(port_data: String) -> void:
	port_filter_sent.emit(port_data)
	print("Port: ", port_data)

func _on_protocol_submitted(protocol_data: String) -> void:
	protocol_filter_sent.emit(protocol_data)
	print("Protocol: ", protocol_data)

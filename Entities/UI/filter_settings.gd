extends Control

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

func _on_ip_submitted(data: String) -> void:
	ip_filter_sent.emit(data)
	print("IP: ", data)

func _on_port_submitted(data: String) -> void:
	port_filter_sent.emit(data)
	print("Port: ", data)

func _on_protocol_submitted(data: String) -> void:
	protocol_filter_sent.emit(data)
	print("Protocol: ", data)

class_name FilterSettings extends Control

signal ip_filter_changed(text_data: String)
signal port_filter_changed(text_data: String)
signal protocol_filter_changed(text_data: String)

@onready var ip_option_button: OptionButton = %"IP TextEdit"
@onready var port_option_button: OptionButton = %"Port TextEdit"
@onready var protocol_option_button: OptionButton = %"Protocol TextEdit"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ip_option_button.item_selected.connect(_on_ip_selected)
	port_option_button.item_selected.connect(_on_port_selected)
	protocol_option_button.item_selected.connect(_on_protocol_selected)

func _on_ip_selected(index: int) -> void:
	ip_filter_changed.emit(str(ip_option_button.get_item_metadata(index)))

func _on_port_selected(index: int) -> void:
	port_filter_changed.emit(str(port_option_button.get_item_metadata(index)))

func _on_protocol_selected(index: int) -> void:
	protocol_filter_changed.emit(str(protocol_option_button.get_item_metadata(index)))

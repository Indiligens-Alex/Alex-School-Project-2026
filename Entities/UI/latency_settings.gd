class_name LatencySettings extends Control

signal latency_value_changed(value: float)

@onready var spin_box: SpinBox = %LatencySpinBox

func _ready() -> void:
	spin_box.value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: float) -> void:
	latency_value_changed.emit(new_value)

func set_editable(enabled: bool) -> void:
	spin_box.editable = enabled
	modulate.a = 1.0 if enabled else 0.5

class_name JitterSettings extends Control

signal jitter_value_changed(value: float)

@onready var spin_box: SpinBox = %JitterSpinBox

func _ready() -> void:
	spin_box.value_changed.connect(_on_value_changed)

func _on_value_changed(new_value: float) -> void:
	jitter_value_changed.emit(new_value)

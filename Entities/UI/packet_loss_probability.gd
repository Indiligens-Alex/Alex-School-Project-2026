extends Control
signal percent_value_changed(value: float)

@onready var spin_box: SpinBox = %SpinBox
@onready var v_slider: VSlider = %VSlider

func _ready() -> void:
	spin_box.value_changed.connect(match_values)
	v_slider.value_changed.connect(match_values)

func match_values(new_value: float) -> void:
	spin_box.value = new_value
	v_slider.value = new_value
	percent_value_changed.emit(new_value)

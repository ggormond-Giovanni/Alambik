extends Control

var _anim := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	Retro16.dessiner_cadre(self, size, _anim)

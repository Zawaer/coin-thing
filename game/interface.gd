extends Control

@export var duration: float = 10.0
@export var fade_time: float = 1.0
@export var height: int = 80
@export var max_width: int = 800
@export var text := "WASD: Move, Space: Jump, Shift: Sprint\nLeft click: Single shoot, Right click: Rapid-fire (after hitting target)"

func _ready() -> void:
	print("this works right, text is: ", text)

	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = height

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.anchor_left = 0.0
	bg.anchor_right = 1.0
	bg.anchor_top = 0.0
	bg.anchor_bottom = 1.0
	bg.offset_left = 0
	bg.offset_right = 0
	bg.offset_top = 0
	bg.offset_bottom = 0
	add_child(bg)

	var center = CenterContainer.new()
	center.anchor_left = 0.0
	center.anchor_right = 1.0
	center.anchor_top = 0.0
	center.anchor_bottom = 1.0
	center.offset_left = 0
	center.offset_right = 0
	center.offset_top = 0
	center.offset_bottom = 0
	add_child(center)

	var lbl := RichTextLabel.new()
	lbl.name = "TutorialLabel"
	lbl.bbcode_enabled = false
	lbl.bbcode_text = text
	lbl.custom_minimum_size = Vector2(max_width, max(1, height - 12))
	center.add_child(lbl)

	modulate = Color(1, 1, 1, 1)
	lbl.modulate = Color(1, 1, 1, 1)

	print("Tutorial nodes:", get_child_count(), "center children:", center.get_child_count())

	# wait duration and then fade out
	await get_tree().create_timer(duration).timeout
	var t = create_tween()
	t.tween_property(lbl, "modulate", Color(1, 1, 1, 0), fade_time)
	t.tween_property(self, "modulate", Color(1, 1, 1, 0), fade_time)
	await t.finished
	queue_free()

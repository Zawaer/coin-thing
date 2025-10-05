extends RigidBody3D

@onready var hit_area := $HitArea
@onready var GameState = get_node("/root/GameState")

func _ready():
	hit_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("coins"):
		GameState.unlock_rapid_fire()
		queue_free()
		

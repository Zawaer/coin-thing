extends RigidBody3D

@onready var hit_area := $HitArea
@onready var GameState = get_node("/root/GameState")

# Optional: tiny bob animation
@export var bob_amount := 0.25
@export var bob_speed := 1.2
var _bob_phase := 0.0

func _ready():
	hit_area.body_entered.connect(_on_body_entered)

func _process(delta):
	_bob_phase += delta * bob_speed
	global_transform.origin.y += sin(_bob_phase) * bob_amount * delta

func _on_body_entered(body):
	# check group to avoid false positives
	if body.is_in_group("coins"):
		GameState.unlock_rapid_fire()
		# Optional: play effect/sound then free
		queue_free()
		

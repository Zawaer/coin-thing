extends RigidBody3D

@export var max_fall_distance: float = 200.0 # how far below spawn the coin must fall before disappearing

var _spawn_y: float
var _spawned: bool = false

func _ready():
	add_to_group("coins")

func _physics_process(_delta: float) -> void:
	# capture spawn height on the first physics frame (deferred positioning will be applied by then)
	if not _spawned:
		_spawn_y = global_position.y
		_spawned = true
		return

	# if the coin has fallen more than the allowed distance, remove it
	if global_position.y < _spawn_y - max_fall_distance:
		queue_free()

extends Node3D

@onready var camera = $Camera3D
@onready var pipe = $Pipe

@export var coin_scene: PackedScene

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var dir = camera.project_ray_normal(mouse_pos)

	var plane = Plane(Vector3.UP, 2.0)
	var hit = plane.intersects_ray(from, dir)
	if hit != null:
		pipe.global_position = hit

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		spawn_coins(5)

func spawn_coins(count = 5):
	if not coin_scene:
		return
	for i in range(count):
		var coin_instance = coin_scene.instantiate()
		add_child(coin_instance)

		# Randomize spawn position around pipe
		var offset = Vector3(randf() - 0.5, randf() * 0.2, randf() - 0.5)
		coin_instance.global_transform.origin = pipe.global_position + Vector3(0, 0.5, -1) + offset

		# Random rotation
		coin_instance.rotation_degrees = Vector3(randf()*360, randf()*360, randf()*360)

		# Shoot forward
		var direction = -pipe.global_transform.basis.z.normalized()
		var random_dir = direction + Vector3(randf() - 0.5, randf() * 0.2, randf() - 0.5) * 0.3
		coin_instance.apply_central_impulse(random_dir * 5.0)

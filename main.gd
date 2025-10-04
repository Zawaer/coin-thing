extends Node3D

@onready var camera = $Camera3D
@onready var pipe = $Pipe

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var dir = camera.project_ray_normal(mouse_pos)

	var plane = Plane(Vector3.UP, 2.0)
	var hit = plane.intersects_ray(from, dir)
	if hit != null:
		pipe.global_position = hit

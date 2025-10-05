extends CharacterBody3D

const NORMAL_SPEED = 8.0
const SPRINT_SPEED = 14.0
const JUMP_VELOCITY = 6
@export var coin_scene: PackedScene
@export var shoot_force: float = 50.0
@export var spin_strength: float = 6.0

@export var rapid_fire_rate: float = 0.04  # seconds between shots
@onready var GameState = get_node("/root/GameState")
var _rapid_fire_timer: Timer


@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var pipe := $Neck/Camera3D/Pipe # make sure this exists

func _ready():
	_rapid_fire_timer = Timer.new()
	_rapid_fire_timer.wait_time = rapid_fire_rate
	_rapid_fire_timer.one_shot = false
	add_child(_rapid_fire_timer)
	_rapid_fire_timer.timeout.connect(_on_rapid_fire_timeout)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot_coin()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if GameState.rapid_fire_unlocked:
				shoot_coin()
				_rapid_fire_timer.start()
		else:
			_rapid_fire_timer.stop()

func _on_rapid_fire_timeout():
	if GameState.rapid_fire_unlocked:
		shoot_coin()
	else:
		_rapid_fire_timer.stop()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	if direction.length() > 0.001:
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO

	var is_sprinting = Input.is_action_pressed("sprint")
	var real_speed = SPRINT_SPEED if is_sprinting else NORMAL_SPEED

	# smooth acceleration and slower on air
	var accel = 50.0 if is_on_floor() else 20.0

	var target = direction * real_speed

	var horizontal = Vector3(velocity.x, 0, velocity.z)
	horizontal = horizontal.move_toward(target, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

func shoot_coin():
	if not coin_scene:
		return

	var coin = coin_scene.instantiate()

	var spawn_distance := 1.0
	var forward: Vector3 = -pipe.global_transform.basis.z.normalized()
	var spawn_transform: Transform3D = pipe.global_transform
	spawn_transform.origin += forward * spawn_distance
	coin.global_transform = spawn_transform

	get_tree().current_scene.add_child(coin)

	if coin.has_method("set_linear_velocity"):
		coin.set_linear_velocity(forward * shoot_force)
	elif "linear_velocity" in coin:
		coin.linear_velocity = forward * shoot_force

	if "angular_velocity" in coin:
		coin.angular_velocity = Vector3(randf(), randf(), randf()) * spin_strength

	var PLAYER_LAYER_BIT := 0
	if "collision_mask" in coin and "collision_mask" in self:
		var orig_mask: int = coin.collision_mask
		coin.collision_mask = coin.collision_mask & ~(1 << PLAYER_LAYER_BIT)
		call_deferred("_restore_coin_mask", coin, orig_mask, 0.08)

func _restore_coin_mask(coin, orig_mask, delay):
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(coin):
		coin.collision_mask = orig_mask

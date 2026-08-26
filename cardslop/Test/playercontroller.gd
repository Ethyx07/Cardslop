extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var mouse_sensitivity := 0.001
@onready var head : Node3D = $Head
@onready var eye_camera: Camera3D = $Head/EyeCamera

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	var steam_id = Steam.getSteamID()
	var player_name = Steam.getFriendPersonaName(steam_id)
	$Head/Label3D.text = player_name

func _ready() -> void:
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not eye_camera.current:
		eye_camera.make_current()
		
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
	var direction := (eye_camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion:
		var relative = event.relative * mouse_sensitivity
		head.rotate_y(-relative.x)
		eye_camera.rotate_x(-relative.y)
		eye_camera.rotation.x = clamp(eye_camera.rotation.x, deg_to_rad(-40), deg_to_rad(40))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		try_spawn_object()
		

func try_spawn_object() -> void:
	var startPos := eye_camera.global_position
	var endPos := startPos + -(eye_camera.global_basis.z * 20)
	
	var ray := PhysicsRayQueryParameters3D.create(startPos, endPos)
	ray.collision_mask = 1 << 1
	var result := get_world_3d().direct_space_state.intersect_ray(ray)
	
	if result:
		if multiplayer.is_server():
			request_spawn(result.position)
		else:
			request_spawn.rpc_id(1, result.position)
		

@rpc("any_peer", "call_remote", "reliable")
func request_spawn(spawn_position : Vector3) -> void:
	if not multiplayer.is_server():
		return
	
	get_parent().spawn_object(spawn_position)

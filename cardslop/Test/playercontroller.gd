extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var mouse_sensitivity := 0.001
@onready var head : Node3D = $Head
@onready var eye_camera: Camera3D = $Head/EyeCamera

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

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
	if event is InputEventMouseMotion:
		var relative = event.relative * mouse_sensitivity
		head.rotate_y(-relative.x)
		eye_camera.rotate_x(-relative.y)
		eye_camera.rotation.x = clamp(eye_camera.rotation.x, deg_to_rad(-40), deg_to_rad(40))

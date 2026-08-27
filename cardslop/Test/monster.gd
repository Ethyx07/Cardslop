extends CharacterBody3D

@onready var nav : NavigationAgent3D = $NavigationAgent3D
var trainer : Node3D

const SPEED : float = 2.0
const ACCEL : float = 5.0
const TARGET_DISTANCE : float = 3.0

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if global_position.distance_to(trainer.global_position) > TARGET_DISTANCE:
		nav.target_position = trainer.global_position
		
		var next_position = nav.get_next_path_position()
		var direction = global_position.direction_to(next_position)
		
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCEL * delta)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCEL * delta)
		move_and_slide()
	

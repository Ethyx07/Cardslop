extends CharacterBody3D

class_name Monster

@onready var nav : NavigationAgent3D = $NavigationAgent3D
var trainer : Node3D

const SPEED : float = 2.0
const ACCEL : float = 5.0
const TARGET_DISTANCE : float = 3.0

func _enter_tree() -> void:
	var material = $MeshInstance3D.get_active_material(0) as StandardMaterial3D
	var new_material = material.duplicate()
	new_material.albedo_color = Color(randf(), randf(), randf(), 1)
	$MeshInstance3D.set_surface_override_material(0, new_material)

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
	
	if velocity.length() > 0:
		var facing_angle = atan2(velocity.x, velocity.z)
		global_rotation.y = facing_angle
	

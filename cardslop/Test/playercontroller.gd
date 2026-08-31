extends CharacterBody3D

class_name PlayerController

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const INVENTORY_SIZE = 5

var current_monster : Monster
var monster_spawned := false

var hovered_interactable : Interactable

@export var mouse_sensitivity := 0.001

@onready var head : Node3D = $Head
@onready var eye_camera: Camera3D = $Head/EyeCamera
@onready var player_inventory : PlayerInventory = $PlayerUI/PlayerInventory

#Server side REAL inventory (not just the visual stuff the ui does)
var inventory : Array[ItemData] = [] #Empty so sad :(

var current_monster_data : String

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
	var steam_id = Steam.getSteamID()
	var player_name = Steam.getFriendPersonaName(steam_id)
	$Head/Label3D.text = player_name
	
	
func _ready() -> void:
	$PlayerUI.visible = is_multiplayer_authority()
	
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not eye_camera.current:
		eye_camera.make_current()
		
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("Interact") and hovered_interactable:
		hovered_interactable.on_interacted(self)
	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var startPos := eye_camera.global_position
	var endPos := startPos + -(eye_camera.global_basis.z * 20)
	
	var ray := PhysicsRayQueryParameters3D.create(startPos, endPos)
	ray.collision_mask = 1 << 2
	var result := get_world_3d().direct_space_state.intersect_ray(ray)
	if result:
		var collider = result.collider as Interactable
		if collider:
			if hovered_interactable and hovered_interactable != collider:
				hovered_interactable.set_hovered_over(false) #Disables hovered interactable if we go from one to another in one frame
				
			hovered_interactable = collider
			hovered_interactable.set_hovered_over(true)
	else:
		if hovered_interactable:
			clear_hovered_interactable()
			
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

func clear_hovered_interactable() -> void:
	hovered_interactable.set_hovered_over(false)
	hovered_interactable = null

func get_inventory_size() -> int:
	return INVENTORY_SIZE

#--------------------------------------------
#		INVENTORY LOGIC
#--------------------------------------------

#If server we can just add the item
#If client we want to get the server to add it first then replicate it on our clients
func request_add_item(item_data : ItemData) -> void:
	if multiplayer.is_server():
		add_item_to_inventory(item_data)
	else:
		request_add_item_server.rpc_id(1, item_data)

@rpc("any_peer", "call_remote", "reliable")
func request_add_item_server(item_data : ItemData) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != get_multiplayer_authority(): #Gotta make sure we only adjust the senders inventory
		return
	
	add_item_to_inventory(item_data)

#SERVER ONLY
func add_item_to_inventory(item_data : ItemData) -> void:
	if not multiplayer.is_server(): 
		return
	
	if inventory.size() >= INVENTORY_SIZE:
		return
	
	inventory.append(item_data)
	sync_inventory_to_owner()

#SERVER ONLY
func remove_item_from_inventory(slot_index : int) -> void:
	if not multiplayer.is_server(): 
		return
	
	if slot_index < 0 or slot_index >= inventory.size(): #Cant remove from slot if its an empty one
		return
	
	inventory.remove_at(slot_index)
	
	sync_inventory_to_owner()

func sync_inventory_to_owner() -> void:
	if not multiplayer.is_server():
		return
	
	var owner_id := get_multiplayer_authority() 
	if owner_id == multiplayer.get_unique_id(): #Checks if its server that we are updating
		update_inventory_ui(inventory)
	else:
		update_inventory_ui.rpc_id(1, inventory)
		
@rpc("authority", "call_remote", "reliable")
func update_inventory_ui(new_inventory : Array[ItemData]) -> void:
	if not is_multiplayer_authority():
		return
	
	player_inventory.set_inventory(new_inventory)


func set_monster(monster : Monster) -> void:
	if not monster:
		return
	current_monster = monster
	monster_spawned = true
	
func clear_monster() -> void:
	current_monster = null
	monster_spawned = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion:
		var relative = event.relative * mouse_sensitivity
		head.rotate_y(-relative.x)
		eye_camera.rotate_x(-relative.y)
		eye_camera.rotation.x = clamp(eye_camera.rotation.x, deg_to_rad(-40), deg_to_rad(40))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#if not current_monster:
			#try_spawn_monster()
		var hovered_item = player_inventory.get_currently_hovered() as Item
		if hovered_item:
			hovered_item.on_item_use(self)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if current_monster:
			if multiplayer.is_server():
				request_despawn(current_monster.name)
			else:
				request_despawn.rpc_id(1, current_monster.name)

func try_spawn_monster(key : String) -> void:
	if current_monster:
		return
	var startPos := eye_camera.global_position
	var endPos := startPos + -(eye_camera.global_basis.z * 20)
	
	var ray := PhysicsRayQueryParameters3D.create(startPos, endPos)
	ray.collision_mask = 1 << 1
	var result := get_world_3d().direct_space_state.intersect_ray(ray)
	
	if result:
		if multiplayer.is_server():
			request_spawn(result.position, multiplayer.get_unique_id(), key)
		else:
			request_spawn.rpc_id(1, result.position, multiplayer.get_unique_id(), key)
		

@rpc("any_peer", "call_remote", "reliable")
func request_spawn(spawn_position : Vector3, peer_id : int, monster_data : String) -> void:
	if not multiplayer.is_server():
		return
	
	get_parent().spawn_monster(spawn_position, peer_id, monster_data)

@rpc("any_peer", "call_remote", "reliable")
func request_despawn(monster_name : String) -> void:
	var monster = get_parent().get_node_or_null(monster_name) as Monster
	if not monster:
		return
	
	monster.queue_free()	

	
	

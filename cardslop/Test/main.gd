extends Node3D

const PLAYERCONTROLLER = preload("uid://cl4xivdhhcbae")
const OBJECT = preload("uid://bspd4g0rn741p")
var players : Array[CharacterBody3D]

func _ready() -> void:
	Networking.host_created.connect(on_host_created)
	
	$MultiplayerSpawner.spawn_function = spawn_from_data
	

func on_host_created() -> void:
	#Spawns host player
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)


func spawn_player(peer_id : int) -> void:	
	if not multiplayer.is_server():
		return
	
	var spawn_data := {
		"type": "player",
		"peer_id": peer_id,
		"position": $SpawnPoint.position
	}
	
	$MultiplayerSpawner.spawn(spawn_data)

func spawn_object(spawn_position : Vector3, peer_id : int) -> void:
	$MultiplayerSpawner.spawn({
		"type": "object",
		"position": spawn_position,
		"peer_id": peer_id
		})

func spawn_from_data(data : Dictionary) -> Node:
	if data["type"] == "player":
		var new_player := PLAYERCONTROLLER.instantiate() as CharacterBody3D
		
		new_player.name = str(data["peer_id"])
		new_player.position = data["position"]
		return new_player
	
	elif data["type"] == "object":
		var new_object := OBJECT.instantiate()
		new_object.position = data["position"] + Vector3(0,2,0)
		new_object.trainer = get_node_or_null(str(data["peer_id"]))
		return new_object 
	
	return null
	
func initialise_player(player : CharacterBody3D) -> void:	
	for other in players:
		player.add_collision_exception_with(other)
		other.add_collision_exception_with(player)
	players.append(player)


func _on_host_pressed() -> void:
	Networking.host_lobby()
	
	if not multiplayer.is_server():
		for child in get_children():
			if child is CharacterBody3D:
				$DebugLabel.text = (
					"Peer: " + str(multiplayer.get_unique_id()) +
					"\nPlayer: " + child.name +
					"\nPlayer pos: " + str(child.global_position) +
					"\nSpawn pos: " + str($SpawnPoint.global_position)
				)

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is CharacterBody3D:
		initialise_player(node)
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Quit"):
		get_tree().quit()
	elif event.is_action_pressed("Host"):
		Networking.host_lobby()

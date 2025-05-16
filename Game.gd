extends Node

const NPC_SCENE = preload("res://scenes/creatures/npc.tscn")
@export var spawning_npcs:int = 100
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	for i in spawning_npcs:
		spawn_npc()
	
func _process(_delta: float) -> void:
	pass

func spawn_npc(goal = get_spawnpoint()):
	var npc = NPC_SCENE.instantiate()
	npc.global_position = goal.global_position
	npc.Goal = get_goal()
	add_child(npc)
	pass

func get_spawnpoint() -> Node:
	var goals := get_tree().get_nodes_in_group("goals")
	if goals.size() > 0:
		return goals[randi_range(0, goals.size() - 1)]
	else:
		print("No Goals Found")
		get_tree().quit()
		return # For error handling
func get_goal():
	return get_spawnpoint()

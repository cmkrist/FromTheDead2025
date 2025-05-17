extends Node

const NPC_SCENE = preload("res://scenes/creatures/npc.tscn")
const COP_SCENE = preload("res://scenes/creatures/cop.tscn")
@export var spawning_npcs:int = 100
var Cops := 0
var cop_respawn_timer := 0.0

@onready var CopSpawns: Array[Node]
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	for i in spawning_npcs:
		spawn_npc()
	# Specified for GDScript Error
	CopSpawns = get_tree().get_nodes_in_group("goals")
	
	
func _process(delta: float) -> void:
	if cop_respawn_timer > 5:
		if Cops < 20:
			cop_respawn_timer -= 5
			spawn_cop()
		pass
	else:
		cop_respawn_timer += delta
	
	pass

func spawn_cop():
	var cop = COP_SCENE.instantiate()
	cop.global_position = CopSpawns[randi_range(0,len(CopSpawns)-1)].global_position
	cop.Goal = get_goal()
	add_child(cop);
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

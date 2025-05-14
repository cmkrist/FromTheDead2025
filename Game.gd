extends Node

const NPC_SCENE = preload("res://scenes/creatures/npc.tscn")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _ready():
	var npc = NPC_SCENE.instantiate()
	add_child(npc)
	
func _process(_delta: float) -> void:
	pass

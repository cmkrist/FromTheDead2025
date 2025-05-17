# scenes/creatures/npc.gd
extends Character
class_name NPC

# Additional properties specific to NPCs
var is_afraid_of: Node2D
var is_afraid = false
var is_inquisitive = false

@onready var highlight_material = load("res://assets/effects/highlight_material.tres")

func _ready() -> void:
	# Set up events
	$Icon.hide()
	if $FearTimer:
		$FearTimer.timeout.connect(_become_normal)
	
	# Set default character sprite if none is set
	if $HumanSprite:
		if $HumanSprite.texture == null:
			var keys = Characters.keys()
			set_sprite(Characters[keys[randi_range(0, keys.size() - 1)]])
	
	# Set initial Goal
	if Goal:
		$NavigationAgent2D.target_position = Goal.global_position

func _physics_process(delta: float) -> void:
	if is_afraid:
		_afraid_physics_process(delta)
	
	if has_node("NavigationAgent2D") && !$NavigationAgent2D.is_target_reached():
		velocity = to_local($NavigationAgent2D.get_next_path_position()).normalized() * SPEED * delta
	else:
		get_new_target()
	
	set_state()
	update_sprite()
	move_and_slide()

func _afraid_physics_process(delta: float) -> void:
	# Run away from the target
	if is_afraid_of:
		# Get the direction to the target
		var direction = (global_position - is_afraid_of.global_position).normalized()
		# Move in the opposite direction
		velocity = direction * SPEED * delta
		$NavigationAgent2D.target_position = global_position + velocity
	else:
		get_new_target()

func _become_normal() -> void:
	$Icon.hide()
	is_afraid_of = null
	is_afraid = false

func scare(entity: Node2D) -> void:
	$AudioStreamPlayer2D.play()
	if !is_afraid:
		is_afraid = true
	is_afraid_of = entity
	$Icon.show()
	$FearTimer.start()

# Mouse interaction functions
func _mouse_shape_enter(_i) -> void:
	$HumanSprite.material = highlight_material

func _mouse_shape_exit(_i) -> void:
	$HumanSprite.material = null

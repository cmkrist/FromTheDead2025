extends Character
class_name NPC

# Additional properties specific to NPCs
var is_afraid_of: Node2D
var is_afraid = false
var is_inquisitive = false
var is_being_fed_on = false

signal on_npc_clicked(npc)

@onready var highlight_material = load("res://assets/effects/highlight_material.tres")

func _ready() -> void:
	Global.total_NPCs += 1
	# Set up events
	$Icon.hide()
	if has_node("FearTimer"):
		$FearTimer.timeout.connect(_become_normal)
	
	# Set default character sprite if none is setd
	var keys = Characters.keys()
	set_sprite(Characters[keys[randi_range(0, keys.size() - 1)]])
			
	
	# Set initial Goal
	if Goal:
		$NavigationAgent2D.target_position = Goal.global_position
		
	# Connect input event signal
	input_event.connect(_on_input_event)

func _physics_process(delta: float) -> void:
	if is_frozen:
		return
	if is_being_fed_on:
		# Don't move when being fed on
		return
		
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
	is_being_fed_on = false

func scare(entity: Node2D) -> void:
	$AudioStreamPlayer2D.play()
	if !is_afraid:
		is_afraid = true
	is_afraid_of = entity
	$Icon.frame = 3
	$Icon.show()
	$FearTimer.start()

# Mouse interaction functions
func _mouse_shape_enter(_i) -> void:
	$HumanSprite.material = highlight_material

func _mouse_shape_exit(_i) -> void:
	$HumanSprite.material = null
	
func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("on_npc_clicked", self)

func die():
	Global.total_NPCs -= 1
	queue_free()

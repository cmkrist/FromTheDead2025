# scenes/creatures/player.gd
extends NPC
class_name Player

signal state_changed(new_state)
signal summon
# Sprint properties
const SPRINT_DURATION := 5.0  # Maximum sprint time in seconds
const SPRINT_COOLDOWN := 3.0  # Cooldown before sprinting again
const SPRINT_RECOVERY_DELAY := 1.5  # Delay before sprint meter starts recovering

# Player-specific properties
var is_casting := false
var is_scary := false
var is_sprinting := false
var casting_timer := 0.0
var sprint_timer := 0.0
var sprint_cooldown_timer := 0.0
var sprint_recovery_delay_timer := 0.0
var can_sprint := true
var is_sprint_recovering := false

# Feeding properties
var target_npc: Node2D = null
var is_flying_to_target := false
var feeding_effect_scene = preload("res://scenes/feeding_effect.tscn")
@onready var feeding_effect: Node2D = $FeedingEffect
var is_feeding := false

func _ready() -> void:
	# Set default character sprite if none is set
	if $HumanSprite.texture == null:
		_randomize_sprite()
	
	# Initially hide bat sprite
	$BatSprite.hide()
	
	# Initialize sprint variables
	is_sprint_recovering = false
	sprint_recovery_delay_timer = 0.0
	
	feeding_effect.feeding_completed.connect(_on_feeding_completed)
	
	# Connect to NPC clicked signals
	for npc in get_tree().get_nodes_in_group("NavNodes"):
		if npc is NPC and npc != self:
			npc.on_npc_clicked.connect(_on_npc_clicked)

func _physics_process(delta: float) -> void:
	if is_scary:
		terrorize_citizens()
	if is_casting:
		process_casting(delta)
		return
	_handle_sprint_mechanics(delta)
	if is_feeding:
		# Don't move while feeding
		velocity = Vector2.ZERO
	elif is_flying_to_target and target_npc:
		# Flying to target (feeding target)
		_fly_to_target(delta)
	else:
		# Normal movement
		_handle_movement(delta)
	
	_handle_abilities()
	_update_sprite()
	move_and_slide()

# Override scare method to prevent player from being scared
func scare(_player) -> void:
	# Override parent method - player cannot be scared
	pass
func process_casting(delta):
	casting_timer -= delta
	var bodies = $RitualArea.get_overlapping_bodies()
	for body in bodies:
		if body is NPC:
			body.freeze()
		
	if casting_timer <= 0:
		_on_casting_finished()
		cast_ability_1()
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_randomize_sprite()
	
	if event.is_action_pressed("sprint") and can_sprint and !is_feeding:
		_toggle_sprint(true)
	elif event.is_action_released("sprint") and is_sprinting:
		_toggle_sprint(false)
	
	if event.is_action_pressed("ability_1"):
		is_casting = true
		is_scary = true
		casting_timer = 3.0
		$ability1particles.emitting = true
		$RitualArea.show()
		$RitualArea.global_position = get_global_mouse_position()
		terrorize_citizens()
		summon.emit()
	# Handle camera zoom with proper input detection
	if event.is_action_pressed("zoom_in") or event.is_action_pressed("zoom_out"):
		var zoom_direction = 1 if event.is_action_pressed("zoom_in") else -1
		var cam = get_viewport().get_camera_2d()
		if cam:
			cam.zoom += Vector2(zoom_direction, zoom_direction) * 0.1

func _randomize_sprite() -> void:
	var keys = Characters.keys()
	if keys.size() > 0:
		set_sprite(Characters[keys[randi() % keys.size()]])
func _on_casting_finished():
	is_casting = false
	is_scary = false
	$ability1particles.emitting = false
	$RitualArea.hide()
	
func _toggle_sprint(enable: bool) -> void:
	if enable and can_sprint:
		is_sprinting = true
		SPEED *= SPRINT_MOD
		$HumanSprite.hide()
		$BatSprite.show()
		# Force animation update when form changes
		_update_sprite()
	else:
		is_sprinting = false
		is_sprint_recovering = false  # Reset recovery flag
		sprint_recovery_delay_timer = 0.0  # Reset recovery delay timer
		SPEED /= SPRINT_MOD
		$BatSprite.hide()
		$HumanSprite.show()
		# Force animation update when form changes
		_update_sprite()

func _handle_sprint_mechanics(delta: float) -> void:
	if is_sprinting:
		# Increase sprint timer while sprinting
		sprint_timer += delta
		if sprint_timer >= SPRINT_DURATION:
			_toggle_sprint(false)
			can_sprint = false
	elif can_sprint:
		if sprint_timer > 0:
			if !is_sprint_recovering:
				# Start recovery delay when player stops sprinting
				sprint_recovery_delay_timer += delta
				if sprint_recovery_delay_timer >= SPRINT_RECOVERY_DELAY:
					is_sprint_recovering = true
					sprint_recovery_delay_timer = 0.0
			else:
				# Decrease sprint timer after recovery delay
				sprint_timer = max(0, sprint_timer - delta)
				# Reset recovery flag when fully recovered
				if sprint_timer == 0:
					is_sprint_recovering = false
	elif not can_sprint:
		# Handle cooldown after sprint meter is depleted
		sprint_cooldown_timer += delta
		if sprint_cooldown_timer >= SPRINT_COOLDOWN:
			can_sprint = true
			sprint_cooldown_timer = 0.0
			sprint_timer = 0.0

func _handle_abilities() -> void:
	$ability1particles.global_position = get_global_mouse_position()

func _handle_movement(delta: float) -> void:
	var input_direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	# Normalize the input for consistent diagonal movement
	if input_direction.length() > 1.0:
		input_direction = input_direction.normalized()
	
	# Apply speed
	var speed_modifier = DIAGONAL_SPEED_MODIFIER if input_direction.x != 0.0 and input_direction.y != 0.0 else 1.0
	var target_velocity = input_direction * SPEED * speed_modifier * delta
	
	# Apply movement or deceleration
	if input_direction.length() > 0:
		velocity = target_velocity
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta)

func _update_sprite() -> void:
	previous_state = current_state
	
	# Determine current state based on velocity
	if velocity.length() < 1.0:
		current_state = STATE.IDLE
	elif abs(velocity.x) > abs(velocity.y):
		current_state = STATE.WALK_LEFT if velocity.x < 0 else STATE.WALK_RIGHT
	else:
		current_state = STATE.WALK_UP if velocity.y < 0 else STATE.WALK_DOWN
	
	# Only update animation if state changed
	if current_state != previous_state:
		emit_signal("state_changed", current_state)
	
	_play_appropriate_animation()

func _play_appropriate_animation() -> void:
	var animation_name := ""
	
	if current_state == STATE.IDLE:
		$AnimationPlayer.stop()
		_set_idle_frame(previous_state)
		return
	
	if is_sprinting:
		match current_state:
			STATE.WALK_LEFT:
				animation_name = "bat_side"
				$BatSprite.flip_h = true
			STATE.WALK_RIGHT:
				animation_name = "bat_side"
				$BatSprite.flip_h = false
			STATE.WALK_UP:
				animation_name = "bat_up"
			STATE.WALK_DOWN:
				animation_name = "bat_down"
	else:
		match current_state:
			STATE.WALK_LEFT:
				animation_name = "walk_left"
			STATE.WALK_RIGHT:
				animation_name = "walk_right"
			STATE.WALK_UP:
				animation_name = "walk_up"
			STATE.WALK_DOWN:
				animation_name = "walk_down"
				
	if not $AnimationPlayer.is_playing() or $AnimationPlayer.current_animation != animation_name:
		$AnimationPlayer.play(animation_name)

# Override to handle both sprites
func _set_idle_frame(previous_state: int) -> void:
	if is_sprinting:
		# Set bat idle frame based on previous direction
		match previous_state:
			STATE.WALK_LEFT:
				$BatSprite.flip_h = true
				$BatSprite.frame = 0
			STATE.WALK_RIGHT:
				$BatSprite.flip_h = false
				$BatSprite.frame = 0
			STATE.WALK_UP:
				$BatSprite.frame = 0
			STATE.WALK_DOWN:
				$BatSprite.frame = 0
	else:
		# Set human idle frame based on previous direction
		match previous_state:
			STATE.WALK_LEFT:
				$HumanSprite.frame = 0
			STATE.WALK_RIGHT:
				$HumanSprite.frame = 3
			STATE.WALK_UP:
				$HumanSprite.frame = 2
			STATE.WALK_DOWN:
				$HumanSprite.frame = 1
			_:
				$HumanSprite.frame = 0

func terrorize_citizens() -> void:
	var citizens_near_player = $FearRadius.get_overlapping_bodies()
	var citizens_near_castsite = $RitualArea/FearRadius.get_overlapping_bodies()
	var citizens = []
	citizens.append_array(citizens_near_player)
	citizens.append_array(citizens_near_castsite)
	for person in citizens:
		if person is Cop:
			person.attack(self)
		elif person is NPC:
			person.scare(self)

# New functions for feeding mechanic
func _on_npc_clicked(npc: Node2D) -> void:
	if is_feeding or is_flying_to_target:
		return
	
	# Set target and enable flying mode
	target_npc = npc
	is_flying_to_target = true
	
	# Automatically start sprinting to target
	if !is_sprinting and can_sprint:
		_toggle_sprint(true)

func _fly_to_target(delta: float) -> void:
	if target_npc == null:
		is_flying_to_target = false
		if is_sprinting:
			_toggle_sprint(false)
		return
	
	# Calculate direction to target
	var direction = (target_npc.global_position - global_position).normalized()
	
	# Move towards target
	velocity = direction * SPEED * delta
	
	# Check if we've reached the target (within 10 pixels)
	if global_position.distance_to(target_npc.global_position) < 10:
		_start_feeding()

func _start_feeding() -> void:
	if target_npc and !is_feeding:
		is_feeding = true
		is_flying_to_target = false
		
		# Mark target as being fed on
		if target_npc is NPC:
			target_npc.is_being_fed_on = true
		
		# Start feeding effect
		feeding_effect.start_feeding(self, target_npc)
func cast_ability_1():
	var bodies = $RitualArea.get_overlapping_bodies()
	for thing in bodies:
		if thing == self:
			pass
		elif thing is NPC:
			thing.die();
	pass
func _take_damage(amount):
	super(amount)
	if is_casting:
		_on_casting_finished() # Just resets variables, does not cast spell.
		unfreeze_entities()
		
func unfreeze_entities():
	for body in $RitualArea.get_overlapping_bodies():
		if body is NPC or body is Cop:
			body.unfreeze()
func _on_feeding_completed() -> void:
	is_feeding = false
	
	# Clear target
	if target_npc is NPC:
		target_npc.is_being_fed_on = false
	
	target_npc = null
	
	# Stop sprinting if we were
	if is_sprinting:
		_toggle_sprint(false)

# scenes/creatures/player.gd
extends NPC
class_name Player

signal state_changed(new_state)

# Sprint properties
const SPRINT_DURATION := 5.0  # Maximum sprint time in seconds
const SPRINT_COOLDOWN := 3.0  # Cooldown before sprinting again
const SPRINT_RECOVERY_DELAY := 1.5  # Delay before sprint meter starts recovering

# Player-specific properties
var is_casting := false
var is_sprinting := false
var sprint_timer := 0.0
var sprint_cooldown_timer := 0.0
var sprint_recovery_delay_timer := 0.0
var can_sprint := true
var is_sprint_recovering := false

func _ready() -> void:
	# Set default character sprite if none is set
	if $HumanSprite.texture == null:
		_randomize_sprite()
	
	# Initially hide bat sprite
	$BatSprite.hide()
	
	# Initialize sprint variables
	is_sprint_recovering = false
	sprint_recovery_delay_timer = 0.0

func _physics_process(delta: float) -> void:
	_handle_sprint_mechanics(delta)
	_handle_movement(delta)
	_handle_abilities()
	_update_sprite()
	move_and_slide()

# Override scare method to prevent player from being scared
func scare(_player) -> void:
	# Override parent method - player cannot be scared
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_randomize_sprite()
	
	if event.is_action_pressed("sprint") and can_sprint:
		_toggle_sprint(true)
	elif event.is_action_released("sprint") and is_sprinting:
		_toggle_sprint(false)
	
	if event.is_action_pressed("ability_1"):
		is_casting = true
		$ability1particles.emitting = true
		terrorize_citizens()
	elif event.is_action_released("ability_1"):
		is_casting = false
		$ability1particles.emitting = false
	
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
	var citizens = $FearRadius.get_overlapping_bodies()
	for person in citizens:
		if person is Cop:
			person.attack(self)
		elif person is NPC:
			person.scare(self)

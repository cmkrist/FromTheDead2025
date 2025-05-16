extends NPC
class_name Player

var is_casting := false

func _ready() -> void:
	# Set default character sprite if none is set
	if $Sprite2D.texture == null:
		var keys = Characters.keys()
		set_sprite(Characters[keys[randi_range(0, keys.size() - 1)]])

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_abilities()
	update_sprite()
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var keys = Characters.keys()
		set_sprite(Characters[keys[randi_range(0, keys.size() - 1)]])
	if event.is_action_pressed("sprint"):
		SPEED *= SPRINT_MOD
		$AnimationPlayer.speed_scale = 2
	if event.is_action_released("sprint"):
		SPEED /= SPRINT_MOD
		$AnimationPlayer.speed_scale = 1
	if event.is_action_pressed("ability_1"):
		is_casting = true
		$ability1particles.emitting = true
	if event.is_action_released("ability_1"):
		is_casting = false
		$ability1particles.emitting = false
	if event.is_action("zoom_in"):
		var cam = get_viewport().get_camera_2d()
		cam.zoom += Vector2(1, 1)
	if event.is_action_pressed("zoom_out"):
		var cam = get_viewport().get_camera_2d()
		cam.zoom += Vector2(-1, -1)

func handle_abilities():
	$ability1particles.global_position = get_global_mouse_position()

func handle_movement(delta) -> void:
	var lr_direction := Input.get_axis("move_left", "move_right")
	var ud_direction := Input.get_axis("move_up", "move_down")
	# Calculate velocity based on input
	if lr_direction != 0.0 and ud_direction != 0.0:
		# Moving diagonally - apply speed modifier
		velocity.x = lr_direction * SPEED * DIAGONAL_SPEED_MODIFIER * delta
		velocity.y = ud_direction * SPEED * DIAGONAL_SPEED_MODIFIER * delta
	elif lr_direction != 0.0:
		# Moving horizontally
		velocity.x = lr_direction * SPEED * delta
		velocity.y = move_toward(velocity.y, 0, SPEED)
	elif ud_direction != 0.0:
		# Moving vertically
		velocity.y = ud_direction * SPEED * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# Not moving - decelerate
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		velocity.y = move_toward(velocity.y, 0, SPEED * delta)

func update_sprite() -> void:
	# Determine current state based on velocity and facing direction
	var previous_state = current_state
	
	if velocity.length() < 10.0:  # Small threshold to detect idle state
		current_state = STATE.IDLE
	elif abs(velocity.x) > abs(velocity.y):
		# Horizontal movement is dominant
		current_state = STATE.WALK_LEFT if velocity.x < 0 else STATE.WALK_RIGHT
	else:
		# Vertical movement is dominant
		current_state = STATE.WALK_UP if velocity.y < 0 else STATE.WALK_DOWN
	
	# Only update animation if state changed
	if current_state != previous_state:
		match current_state:
			STATE.IDLE:
				$AnimationPlayer.stop()
				match previous_state:
					STATE.WALK_LEFT:
						$Sprite2D.frame = 0
					STATE.WALK_RIGHT:
						$Sprite2D.frame = 3
					STATE.WALK_UP:
						$Sprite2D.frame = 2
					STATE.WALK_DOWN:
						$Sprite2D.frame = 1
					_:
						$Sprite2D.frame = 0
			STATE.WALK_LEFT:
				if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "walk_left"):
					$AnimationPlayer.play("walk_left")
			STATE.WALK_RIGHT:
				if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "walk_right"):
					$AnimationPlayer.play("walk_right")
			STATE.WALK_UP:
				if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "walk_up"):
					$AnimationPlayer.play("walk_up")
			STATE.WALK_DOWN:
				if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "walk_down"):
					$AnimationPlayer.play("walk_down")

func set_sprite(res_location):
	$Sprite2D.texture = load(res_location)
	$Sprite2D.frame = 1
	
# Setup function to be called when node is added to scene

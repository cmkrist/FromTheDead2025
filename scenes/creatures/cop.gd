extends NPC
class_name Cop

const cop_texture = preload("res://assets/textures/policeman.png")
const bullet_scene = preload("res://scenes/Objects/bullet.tscn")

# Cop-specific properties
var is_aggro = false
var target: Node2D
var range = 40
var shooting_range = 150  # Maximum distance to shoot
var can_shoot = true
var shoot_cooldown_time = 1.5  # Seconds between shots
var bullet_speed = 300

func _ready() -> void:
	super._ready()
	$Icon.hide()
	
	# Set default character sprite if none is set
	if $Sprite2D.texture == null:
		var keys = Characters.keys()
		set_sprite(Characters[keys[randi_range(0, keys.size() - 1)]])
	
	# Connect timer timeout signal
	$ShotCooldown.timeout.connect(_on_shoot_cooldown_timeout)

func _physics_process(delta: float) -> void:
	if is_being_fed_on:
		# Don't move when being fed on
		return
		
	if is_aggro:
		aggro_logic(delta)
	
	super._physics_process(delta)

func aggro_logic(delta: float) -> void:
	# Run towards the target
	if target:
		var distance_to_target = global_position.distance_to(target.global_position)
		
		# If target is in shooting range, try to shoot
		if distance_to_target <= shooting_range:
			# If target is out of melee range, stop to shoot
			if distance_to_target > range:
				$NavigationAgent2D.target_position = global_position
				if can_shoot:
					shoot_at_target()
			else:
				# If target is in melee range, play audio
				$NavigationAgent2D.target_position = global_position
				if !$MeleeSound.playing:
					$MeleeSound.play()
		else:
			# If target is out of range, move towards it
			$NavigationAgent2D.target_position = target.global_position
	else:
		get_new_target()

func attack(player: Node2D) -> void:
	is_aggro = true
	target = player
	$Icon.show()

func shoot_at_target() -> void:
	if target and can_shoot:
		# Visual feedback for shooting
		var muzzle_flash = create_muzzle_flash()
		add_child(muzzle_flash)
		
		# Create bullet
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		# Set bullet direction and position
		var direction = (target.global_position - global_position).normalized()
		bullet.global_position = global_position
		bullet.direction = direction
		
		# Play shooting sound if available
		if has_node("GunSound") and !$GunSound.playing:
			$GunSound.play()
		
		# Set cooldown
		can_shoot = false
		$ShotCooldown.start(shoot_cooldown_time)

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true

func create_muzzle_flash() -> Node2D:
	var flash = Node2D.new()
	flash.name = "MuzzleFlash"
	
	# Set up the muzzle flash to automate itself
	flash.set_script(GDScript.new())
	flash.script.source_code = """
extends Node2D

var lifetime = 0.2
var timer = 0.0
var size = 10.0

func _process(delta):
	timer += delta
	if timer >= lifetime:
		queue_free()
	queue_redraw()

func _draw():
	var alpha = 1.0 - (timer / lifetime)
	draw_circle(Vector2.ZERO, size * alpha, Color(1, 0.8, 0.2, alpha))
"""
	
	# Position the muzzle flash slightly ahead of the cop
	var direction = Vector2.RIGHT
	if target:
		direction = (target.global_position - global_position).normalized()
	
	flash.position = direction * 20  # 20 pixels ahead in the direction of the target
	
	return flash

# Sprite handling - using Sprite2D instead of HumanSprite
func update_sprite() -> void:
	set_state()
	
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
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_left"):
				$AnimationPlayer.play("human_animations/walk_left")
		STATE.WALK_RIGHT:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_right"):
				$AnimationPlayer.play("human_animations/walk_right")
		STATE.WALK_UP:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_up"):
				$AnimationPlayer.play("human_animations/walk_up")
		STATE.WALK_DOWN:
			if !($AnimationPlayer.is_playing() && $AnimationPlayer.current_animation == "human_animations/walk_down"):
				$AnimationPlayer.play("human_animations/walk_down")

# Override set_sprite to work with Sprite2D
func set_sprite(res_location: String) -> void:
	$Sprite2D.texture = load(res_location)
	$Sprite2D.frame = 1
	
# Override input event method
func _on_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("on_npc_clicked", self)

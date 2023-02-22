extends KinematicBody2D

export(int) var SPEED = 90
export var direction = Vector2.ZERO
onready var orc = Globals.orc
var hp = 100

onready var sprite = $AnimatedSprite
var can_attack 

func _physics_process(delta):
	var input = Vector2.ZERO
	
	input.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	direction = input.normalized()
	direction = move_and_slide(direction * SPEED)
	
	if direction == Vector2.ZERO:
		sprite.play("idle")
	else:
		sprite.play("run")
		
	sprite.flip_h = direction.x < 0
	
	if(hp == 0):
		queue_free()
	


func _process(delta):
	var collision = detect_collision()
	if(collision == "Orc" and can_attack and Globals.orc.hp > 0 and Input.is_action_pressed("ui_attack")):
		Globals.orc.hp = Globals.orc.hp - 2
		can_attack = false
		$Timer.start(0.5)
		
func _ready():
	Globals.player = self


func detect_collision():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		#print("I collided with ", collision.collider.name)
		return (collision.collider.name)


func _on_Timer_timeout():
	can_attack = true

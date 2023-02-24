extends KinematicBody2D

func detect_collision():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		print("I, invisible_orc,  collided with ", collision.collider.name)
		return (collision.collider.name)

func _process(delta):
	return detect_collision()

func _ready():
	Globals.invisible_orc = self

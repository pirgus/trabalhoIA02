extends KinematicBody2D

# vetores para a implementação do a*
var path = []
var open_list = []
var closed_list = []

# estados da máquina de estados (durr)
enum {
	IDLE,
	FETCH,
	ATTACK,
	HEAL,
	MOVE_AWAY
}

const TILE_SIZE = 16
var can_attack
var can_heal
var is_colliding = false
const SPEED = 50
var hp = 40
const HP_TOTAL = 40
var state = IDLE
onready var player = Globals.player
var direction = Vector2.ZERO
onready var player_position = player.global_position
onready var self_position = global_position
onready var distance = player_position.distance_to(self_position)
onready var orc_scene = get_node("res://characters/Goblin.tscn")

func _process(delta):
	if(hp == 0):
		queue_free()
	
	match state:
		IDLE:
			print("de boa!!")
			$AnimatedSprite.play("idle")
		
		FETCH:
			print("perseguindo!!")
			var vizinhos = gerar_vizinhos(self)
			print(vizinhos)
			$AnimatedSprite.play("run")
			fetch(delta) # vai ter o A* depois, por enquanto só pega a posição global e segue
			
		ATTACK:
			print("atacando!!")
			$AnimatedSprite.play("idle")
			var collision = detect_collision()
			npc_attacks_player(collision)
			print("hp do player = ", player.hp)
			print("hp do orc = ", self.hp)
			if(hp < (HP_TOTAL * 0.3)):
				state = MOVE_AWAY
			
		MOVE_AWAY:
			print("se afastando")
			var direction = Vector2.LEFT
			var velocity = direction * SPEED
			velocity = move_and_slide(velocity)	
			
		
		HEAL:
			print("se curando")
			if(can_heal):
				hp += 2
				can_heal = false
				$Timer.start(0.5)
			print("curando hp... ", hp)
			if(hp >= 0.7 * HP_TOTAL):
				state = IDLE
			
		
		
		
func fetch(delta):
	if(player != null):
		direction = global_position.direction_to(player.global_position)
		
	var velocity = direction * SPEED
	velocity = move_and_slide(velocity)			
	$AnimatedSprite.flip_h = direction.x < 0
	
	var collision = detect_collision()
	if(collision == "Player"):
		state = ATTACK

func _on_Area2D_body_entered(body):
	if(body == player and state == IDLE):
		state = FETCH
	elif(state == HEAL):
		state = MOVE_AWAY


func _on_Area2D_body_exited(body):
	if(body == player and state == MOVE_AWAY):
		state = HEAL
	else:
		state = IDLE


func detect_collision():
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		#print("I collided with ", collision.collider.name)
		return (collision.collider.name)
	

func npc_attacks_player(collision):
	if(collision == "Player"):
		if(player.hp > 0 and can_attack):
			player.hp = player.hp - 2
			can_attack = false
			$Timer.start(1)
	state = FETCH

func _on_Timer_timeout():
	can_attack = true
	can_heal = true
	
func _ready():
	Globals.orc = self

# funções do a*
func distance_to(target):
	return position.distance_to(target.position)

func is_node_in_list(node, list):
	for n in list:
		if n.position == node.position:
			return true
	return false

func gerar_vizinhos(node):
	var neighbors = []
	
	var tilemap = Globals.obstacles
	var cell = tilemap.get_cell(0, 0)
	var tileset = tilemap.get_tileset()
	var size = tilemap.cell_size
	var posicao_atual = self.position
	var celulas_usadas = tilemap.get_used_cells()
	
	var local_position = tilemap.to_local(global_position)
	var tile_position = tilemap.world_to_map(local_position)
	print("tile_position = ", tile_position)
	#var tile_id = tilemap.get_cellv(tile_position)
	
	

func a_estrela(objetivo):
	pass

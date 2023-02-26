extends KinematicBody2D

# estados da máquina de estados (durr)
enum {
	IDLE,
	FETCH,
	ATTACK,
	HEAL,
	MOVE_AWAY
}

class Node_A_Star:
	var state : Vector2
	var parent : Node_A_Star
	var action : Vector2
	var g : int
	var h : int
	var f : int
	

var execute = true
const TILE_SIZE = 16
var can_attack
var can_heal
var is_colliding = false
const SPEED = 20
var hp = 40
const HP_TOTAL = 40
var state = IDLE
onready var player = Globals.player
var direction = Vector2.ZERO
onready var player_position = player.global_position
onready var self_position = global_position
onready var distance = player_position.distance_to(self_position)
onready var orc_scene = get_node("res://characters/Goblin.tscn")
var caminho = []

func _process(delta):
	if(hp == 0):
		queue_free()
	
	match state:
		IDLE:
			print("de boa!!")
			$AnimatedSprite.play("idle")
		
		FETCH:
			print("perseguindo!!")
			$AnimatedSprite.play("run")
			
			var pos_player = player.global_position
			fetch(pos_player)
			
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
#	var posicao_player 
#	if(player != null):
#		posicao_player = player.global_position
#		direction = global_position.direction_to(player.global_position)
	
	var tilemap = Globals.obstacles
	var posicao_enemy = global_position
	
	#print("----------------posicao atual do orc no mundo = ", posicao_enemy)
	var local_position_enemy = tilemap.to_local(posicao_enemy)
	var posicao_atual_enemy = tilemap.world_to_map(local_position_enemy)
	#print("----------------posicao atual do orc no grid = ", posicao_atual_enemy)
	
	# converte para posição no grid do tilemap
	var local_position_player = tilemap.to_local(delta)
	var posicao_atual_player = tilemap.world_to_map(local_position_player)
	# --------------------------------------------------------------------------
	
	# recupera para a coordenada do mundo (tem uma pequena diferença acho que por
	# arredondamento)
	local_position_player = tilemap.map_to_world(posicao_atual_player)
	var player_global_position = tilemap.to_global(local_position_player)
	# --------------------------------------------------------------------------
	
	
	#var velocity = direction * SPEED
	#velocity = move_and_slide(velocity)		
	#print("posicao atual do ORC no grid = ", posicao_atual_enemy)
	#print("posicao atual do PLAYER no grid = ", posicao_atual_player)
	
#	if (execute):
	caminho = a_estrela_2(posicao_atual_enemy, posicao_atual_player)
#		execute = false 
#		$Timer2.start(0.5)
	#print("caminho gerado = ", caminho)	
	
	for item in caminho:
		var index = caminho.find(item)
		var local = tilemap.map_to_world(item)
		var global = tilemap.to_global(local)
		caminho[index] = global
		#print("caminho convertido = ", caminho[index])
	#print("caminho depois de voltar p/ mundo = ", caminho)
	
	var erro_x = global_position.x - caminho[0].x
	var erro_y = global_position.y - caminho[0].y

	for item in caminho:
		var index = caminho.find(item)
		var x_certo = caminho[index].x + erro_x
		var y_certo = caminho[index].y + erro_y
		var caminho_c = Vector2(x_certo, y_certo)
		caminho[index] = caminho_c
		#print("caminho 'consertado' = ", caminho[index])
	
	
#	direction = global_position.direction_to(player.global_position)
	#print("direcao normal = ", direction)
	
	$AnimatedSprite.flip_h = direction.x < 0
	for item in caminho:
		if caminho.find(item) != 0:
			#print("item de caminho = ", item)
			direction = global_position.direction_to(item)
			#print("direcao para o item = ", direction)
			var velocity = direction * SPEED
			velocity = move_and_slide(velocity)
	
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

# --------------------------------------------------------------------------------------------------

# funções do a*
# heuristica com base na distancia de manhattan
func heuristic(pos, target):
	var heuristic = pos.distance_to(target)
	#print("heuristica com distancia de manhattan = ", heuristic)
	return heuristic


# nova função de gerar vizinhos para a estrutura criada
# debuguei e parece estar funcionando normalmente assim como a outra
# o atributo .state do node_a_star precisa ser passado já como coordenadas do grid
func gerar_vizinhos2(node_a_star):
	var neighbors = []
	
	var tilemap = Globals.obstacles
	#var posicao = Vector2(node_a_star.state.x, node_a_star.state.y)
	#var local_position = tilemap.to_local(posicao)
	#var posicao_atual = tilemap.world_to_map(local_position)
	#print("posicao atual no gerar vizinhos = ", posicao_atual)
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			# ignora a própria posição (0, 0)
			if((x == 0 and y == 0)):
				continue
			
			var possivel_vizinho = Vector2(node_a_star.state.x + x, node_a_star.state.y + y)
			
			# se a célula tiver valor != -1 quer dizer que está preenchida com um obstáculo
			if(tilemap.get_cell(possivel_vizinho.x, possivel_vizinho.y) == -1):
				var p_vizinho = Node_A_Star.new()
				p_vizinho.state = Vector2(possivel_vizinho.x, possivel_vizinho.y)
				p_vizinho.parent = node_a_star
				p_vizinho.action = Vector2(x, y)
				p_vizinho.g = node_a_star.g + 1
				p_vizinho.h = 0
				p_vizinho.f = 0
				# adiciona à lista de vizinhos
				neighbors.append(p_vizinho)
			
	return neighbors

#class Node_A_Star:
#	var state : Vector2
#	var parent : Node_A_Star
#	var action : Vector2
#	var path_cost : int

func a_estrela_2(inicio, objetivo): 
	#print("entrou no a_estrela_2")
	# parâmetros inicio e objetivo são dois Vector2
	# com valores equivalentes às coordenadas do grid do tilemap obstacles (16, 16)
	
	# listas OPEN e CLOSED para determinar caminhos já explorados (ou não)
	var open = []
	var closed = []
	
	# lista para armazenar os passos necessários para alcançar o objetivo
	var caminho = []
	
	# lista para armazenar geração de vizinhos
	var vizinhos = []
	
	# coloca o inicio na lista OPEN
		# mas pra isso, precisamos construir a estrutura Node_A_Star com base no inicio
	var inicio_node = Node_A_Star.new()
	inicio_node.state = inicio
	inicio_node.parent = null
	inicio_node.action = Vector2.ZERO
	# o nó inicial possui como custo apenas o valor da heuristica
	inicio_node.g = 0
	inicio_node.h = heuristic(inicio_node.state, objetivo) 
	
	open.append(inicio_node)
	#print("tamanho da lista open = ", open.size())
	
	#open.erase(inicio_node)
	
	# executar enquanto ainda houverem nós não explorados, ou seja
	# até que a lista open não esteja vazia
	while (not(open.empty())):
		#print("lista OPEN = ", open)
		
		# obter o nó com menos custo de caminho na lista open
		#var no_atual = Node_A_Star.new()
#		no_atual.path_cost = 0
		
		var no_atual = Node_A_Star.new()
		no_atual.f = 1000
		var index
		
		for i in open:
			if i.f < no_atual.f:
				no_atual = i
				index = open.find(i)
		
		# remove o nó da lista OPEN e passa pra CLOSED
		closed.append(no_atual)
		open.remove(index)		
		
		# se o no_atual é = objetivo, retorna os passos necessários para alcança-lo
		if no_atual.state == objetivo:
			#print("encontrou objetivo")
			var current = no_atual
			while current != null:
				caminho.append(current.state)
				current = current.parent
			# reverte a lista para obter o caminho certo
			#print("caminho dentro do a_estrela = ", caminho)
			caminho.invert()
			return caminho
		
		# senão, gera os possíveis vizinhos
		vizinhos = gerar_vizinhos2(no_atual)
		for vizinho in vizinhos:
			#print("gerou vizinhos")
			if closed.has(vizinho):
				continue
			
			vizinho.h = heuristic(vizinho.state, objetivo)
			vizinho.f = vizinho.g + vizinho.h
			
			for open_node in open:
				if vizinho.state == open_node.state and vizinho.g > open_node.g:
					continue
			
			open.append(vizinho)
#			for item in open:
#				print("lista OPEN = ", item.state)
			


func _on_Timer2_timeout():
	execute = true

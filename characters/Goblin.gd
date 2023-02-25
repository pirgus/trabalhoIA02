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
	var path_cost : int
	

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
			$AnimatedSprite.play("run")
			
			fetch(delta) 
			
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
	var posicao_player
	if(player != null):
		posicao_player = player.global_position
		direction = global_position.direction_to(player.global_position)
	
	var tilemap = Globals.obstacles
	var posicao_enemy = global_position
	var local_position_enemy = tilemap.to_local(posicao_enemy)
	var posicao_atual_enemy = tilemap.world_to_map(local_position_enemy)
	
	
	#print("posicao do player no mundo = ", player.global_position)
	
	# converte para posição no grid do tilemap
	var local_position_player = tilemap.to_local(posicao_player)
	var posicao_atual_player = tilemap.world_to_map(local_position_player)
	#print("posicao do player no grid = ", posicao_atual_player)
	# --------------------------------------------------------------------------
	
	# recupera para a coordenada do mundo (tem uma pequena diferença acho que por
	# arredondamento)
	local_position_player = tilemap.map_to_world(posicao_atual_player)
	var player_global_position = tilemap.to_global(local_position_player)
	#print("posicao do player 'restaurada' = ", player_global_position)
	# --------------------------------------------------------------------------
	

	#direction = global_position.direction_to(player_global_position)
	#var caminho = a_estrela(posicao_atual_enemy, posicao_atual_player)
	
	#var velocity = direction * SPEED
	#velocity = move_and_slide(velocity)		
	var caminho = a_estrela(posicao_atual_enemy, posicao_atual_player)	
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

# --------------------------------------------------------------------------------------------------

# funções do a*
# heuristica com base na distancia de manhattan
func heuristic(pos, target):
	var heuristic = abs(target.x - pos.x) + abs(target.y - pos.y)
	#print("heuristica com distancia de manhattan = ", heuristic)
	return heuristic

# gera os vizinhos de acordo com o tilemap Obstacles que apenas possui tiles que representam obstáculos
# essa função funciona 
func gerar_vizinhos(x, y):
	var neighbors = []
	
	var tilemap = Globals.obstacles
	var posicao = Vector2(x, y)
	var local_position = tilemap.to_local(posicao)
	var posicao_atual = tilemap.world_to_map(local_position)
	#print("tile_position = ", posicao_atual)
	#print("posicao_atual.x = ", posicao_atual.x)
	#print("posicao_atual.y = ", posicao_atual.y)
	#var tile_id = tilemap.get_cellv(tile_position)
	
	for x in range(-1, 2):
		for y in range(-1, 2):
			
			# ignora a própria posição (0, 0)
			if(x == 0 and y == 0):
				continue
							
			var possivel_vizinho = Vector2(posicao_atual.x + x, posicao_atual.y + y)
			
			# se a célula tiver valor != -1 quer dizer que está preenchida com um obstáculo
			if(tilemap.get_cell(possivel_vizinho.x, possivel_vizinho.y) == -1):
				# adiciona à lista de vizinhos
				neighbors.append(possivel_vizinho)
			
	return neighbors
	
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
			if(x == 0 and y == 0):
				continue
			
			var possivel_vizinho = Vector2(node_a_star.state.x + x, node_a_star.state.y + y)
			
			# se a célula tiver valor != -1 quer dizer que está preenchida com um obstáculo
			if(tilemap.get_cell(possivel_vizinho.x, possivel_vizinho.y) == -1):
				var p_vizinho = Node_A_Star.new()
				p_vizinho.state = Vector2(possivel_vizinho.x, possivel_vizinho.y)
				p_vizinho.parent = node_a_star
				p_vizinho.action = Vector2(x, y)
				p_vizinho.path_cost = node_a_star.path_cost + 1
				# adiciona à lista de vizinhos
				neighbors.append(p_vizinho)
			
	return neighbors

#class Node_A_Star:
#	var state : Vector2
#	var parent : Node_A_Star
#	var action : Vector2
#	var path_cost : int

# função que realiza o algoritmo a*
func a_estrela(inicio, objetivo):
	print("iniciou o a_estrela")
	
	# vetores para a implementação do a*
	var path = []
	var open_list = []
	var closed_list = []
	var vizinhos = []
	var temp_heuristica
	var minimo
	var posicao_inicial = Node_A_Star.new()
	
	posicao_inicial.state = inicio
	posicao_inicial.parent = null
	posicao_inicial.action = Vector2.ZERO
	posicao_inicial.path_cost = heuristic(inicio, objetivo)
	print("heuristica inicial = ", posicao_inicial.path_cost)
	
	open_list.append(posicao_inicial)
	
	while not(open_list.empty()):
		minimo = Node_A_Star.new()
		minimo.path_cost = 0
		
		# procura o item com menor custo de caminho
		for i in open_list:
			if i.path_cost < minimo.path_cost:
				minimo = i
		
		# retira o menor da lista OPEN
		open_list.erase(minimo)
		
		# se for o objetivo, termina
		if(minimo.state == objetivo):
			return path
		
		# senão, gera os nós filhos desse
		vizinhos = gerar_vizinhos2(minimo)
		
		# percorre os nós filhos/vizinhos
		for vizinho in vizinhos:
			# como os vizinhos percorrem apenas uma posição no grid,
			# definimos que o custo será o custo do pai + 1
			var successor_current_cost = minimo.path_cost + 1
			
			# se o vizinho está na lista OPEN
			if open_list.has(vizinho):
				# e o seu custo de caminho é menor do que o custo calculado anteriormente
				if vizinho.path_cost <= successor_current_cost:
					# -------------- nao sei se tá certo assim
					path.append(vizinho.state)
					break
					# ----------------------------------------
					# precisa ir pro final do for mas como aaaa
			
			# se estiver na lsta CLOSED		
			elif closed_list.has(vizinho):
				if vizinho.path_cost <= successor_current_cost:
					# -------------- nao sei se tá certo assim
					path.append(vizinho.state)
					break
					# ----------------------------------------
					# pula pro final do for
				
				# senão... sai de closed e vai pra open
				closed_list.erase(vizinho)
				open_list.append(vizinho)
				
			# se não estiver nem na OPEN e nem na CLOSED
			else:
				open_list.append(vizinho)
				temp_heuristica = heuristic(vizinho.state, objetivo)
				
			vizinho.path_cost = minimo.path_cost + temp_heuristica
			vizinho.parent = minimo
			
		closed_list.append(minimo)
	
	# lista OPEN está vazia e o objetivo não foi atingido	
	if(minimo.state != objetivo.position):
		print("erro: lista OPEN está vazia.")
		return -1

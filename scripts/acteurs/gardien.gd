class_name Gardien
extends CharacterBody2D

# Le gardien est une vraie cible ennemie : il possede ses PV, peut tomber et se
# reforme apres un delai. Son dessin reste geometrique pour respecter le repli.

var heros: Node2D
var pv := Reglages.GARDIEN_PV
var _reapparition := 0.0
var _attaque := 0.0
var _anim := 0.0

func _ready() -> void:
	add_to_group("cibles_ennemis")
	collision_layer = 1
	collision_mask = 2 | 4
	var collision := CollisionShape2D.new()
	var cercle := CircleShape2D.new()
	cercle.radius = 24.0
	collision.shape = cercle
	add_child(collision)

func _physics_process(delta: float) -> void:
	_anim += delta
	queue_redraw()
	if heros == null or not is_instance_valid(heros):
		return
	if _reapparition > 0.0:
		_reapparition -= delta
		global_position = heros.global_position + Vector2(-70.0, -25.0)
		if _reapparition <= 0.0:
			pv = Reglages.GARDIEN_PV
			visible = true
			collision_layer = 1
		return
	_attaque = maxf(0.0, _attaque - delta)
	var cible := _ennemi_plus_proche()
	if cible == null:
		velocity = global_position.direction_to(heros.global_position + Vector2(-70.0, -25.0)) * 360.0
		move_and_slide()
		return
	var distance := global_position.distance_to(cible.global_position)
	if distance > 62.0:
		velocity = global_position.direction_to(cible.global_position) * 390.0
		move_and_slide()
	elif _attaque <= 0.0:
		_attaque = Reglages.GARDIEN_INTERVALLE
		var degats: float = float(heros.stats.degats) * Reglages.GARDIEN_PART_DEGATS
		var effets: Array[String] = []
		for element in Jeu.elements_de_augment("familier_gardien"):
			if element == "feu":
				effets.append("feu")
			elif element == "eau":
				effets.append("eau")
			elif element == "terre":
				effets.append("terre")
			elif element == "lumiere":
				effets.append("lumiere")
			elif element == "tenebres" and Jeu.rng.randf() < Reglages.TENEBRES_CHANCE_SURCHARGE:
				degats *= Reglages.TENEBRES_SURCHARGE_MULT
		cible.recevoir_degats(degats, effets)
		if "lumiere" in effets:
			heros.stats.soigner(degats * Reglages.LUMIERE_VOL_DE_VIE)

func recevoir_degats(montant: float, _effets: Array = []) -> void:
	if _reapparition > 0.0:
		return
	pv -= montant
	if pv <= 0.0:
		visible = false
		collision_layer = 0
		_reapparition = Reglages.GARDIEN_REAPPARITION

func _ennemi_plus_proche() -> Node2D:
	var resultat: Node2D = null
	var distance := INF
	for ennemi in get_tree().get_nodes_in_group("ennemis"):
		if not is_instance_valid(ennemi):
			continue
		var d := global_position.distance_squared_to(ennemi.global_position)
		if d < distance:
			distance = d
			resultat = ennemi
	return resultat

func _draw() -> void:
	if _reapparition > 0.0:
		return
	var image := int(_anim * 8.0) % 4
	var bob: float = [-4.0, 0.0, 4.0, 0.0][image]
	Retro16.contour_rectangle(self, Rect2(-24.0, -24.0 + bob, 48.0, 48.0),
		Color(0.22, 0.18, 0.34), Palette.ESSENCE, 6.0)
	Retro16.rectangle(self, Rect2(-8.0, -8.0 + bob, 16.0, 16.0), Retro16.PAPIER)
	if _attaque > 0.0:
		Retro16.rectangle(self, Rect2(24.0, -6.0 + bob, 20.0, 12.0), Retro16.OR)

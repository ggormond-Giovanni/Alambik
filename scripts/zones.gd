extends Node2D

# Zones persistantes au sol : flaques de feu, nuages mordants, sillage.
# Une liste et un seul noeud plutot qu'une Area2D par flaque : sur un
# telephone, la difference se voit.

class Zone:
	var position: Vector2
	var rayon: float
	var effets: Array[String]
	var degats_par_seconde: float
	var vie: float
	var vie_max: float
	var couleur: Color
	var hostile: bool
	var gel: float

var _zones: Array[Zone] = []
var _tic := 0.0

# Fonction pure : sert aussi bien au rendu qu'aux tests.
static func touche(centre: Vector2, rayon: float, position: Vector2) -> bool:
	return centre.distance_squared_to(position) <= rayon * rayon

func ajouter(position: Vector2, genre: String) -> void:
	var z := Zone.new()
	z.position = position
	z.hostile = false
	z.gel = 0.0
	match genre:
		"flaque":
			z.rayon = Reglages.FLAQUE_RAYON
			z.effets = ["braise"]
			z.degats_par_seconde = Reglages.BRAISE_DEGATS_PAR_SECONDE
			z.vie = Reglages.FLAQUE_DUREE
			z.couleur = Palette.BRAISE
		"nuage":
			z.rayon = Reglages.NUAGE_RAYON
			z.effets = ["braise", "acide"]
			z.degats_par_seconde = Reglages.BRAISE_DEGATS_PAR_SECONDE * 0.8
			z.vie = Reglages.NUAGE_DUREE
			z.couleur = Palette.ACIDE
		"sillage":
			z.rayon = Reglages.SILLAGE_RAYON
			z.effets = ["givre"]
			z.degats_par_seconde = 0.0
			z.vie = Reglages.SILLAGE_DUREE
			z.couleur = Palette.GIVRE.darkened(0.2)
		"sillage_gelant":
			z.rayon = Reglages.SILLAGE_RAYON
			z.effets = ["givre"]
			z.degats_par_seconde = 0.0
			z.vie = Reglages.SILLAGE_DUREE
			z.couleur = Palette.GIVRE
			z.gel = 0.35
		_:
			return
	z.vie_max = z.vie
	_zones.append(z)

func vider() -> void:
	_zones.clear()

func _process(delta: float) -> void:
	_tic += delta
	var applique := false
	if _tic >= 0.15:
		_tic = 0.0
		applique = true
	var ennemis := get_tree().get_nodes_in_group("ennemis")
	for i in range(_zones.size() - 1, -1, -1):
		var z := _zones[i]
		z.vie -= delta
		if z.vie <= 0.0:
			_zones.remove_at(i)
			continue
		if not applique:
			continue
		for ennemi in ennemis:
			if not is_instance_valid(ennemi):
				continue
			if not touche(z.position, z.rayon, ennemi.global_position):
				continue
			ennemi.recevoir_degats(z.degats_par_seconde * 0.15, z.effets)
			if z.gel > 0.0 and ennemi.has_method("geler"):
				ennemi.geler(z.gel)
	queue_redraw()

func _draw() -> void:
	for z in _zones:
		var t: float = clampf(z.vie / z.vie_max, 0.0, 1.0)
		var c: Color = z.couleur
		c.a = 0.22 * t
		draw_circle(z.position, z.rayon, c)
		c.a = 0.5 * t
		draw_arc(z.position, z.rayon * 0.92, 0.0, TAU, 20, c, 2.5, true)

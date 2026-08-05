extends Area2D

# Projectile generique : il n'a aucune logique propre a un reactif, il execute
# le Tir qu'on lui attache. Une fusion n'est donc jamais du code special
# disperse dans le combat.

signal fragments_demandes(origine: Vector2, direction: Vector2, tir_source: Tir, hostile: bool)
signal chaine_demandee(depuis: Vector2, cible: Node, tir_source: Tir)
signal zone_demandee(position: Vector2, genre: String)
signal impact_visuel(position: Vector2, couleur: Color, ampleur: float)

const RAYON := 13.0
const MEMOIRE_TRAINEE := 9

var tir: Tir
var direction := Vector2.RIGHT
var hostile := false
var couleur := Palette.TIR_HALO

var _facteur_degats := 1.0
var _distance_parcourue := 0.0
var _rebonds_restants := 0
var _perforations_restantes := 0
var _deja_touches: Array[int] = []
var _trainee: Array[Vector2] = []
var _age := 0.0

func _ready() -> void:
	_rebonds_restants = tir.rebonds
	_perforations_restantes = tir.perforations
	couleur = Palette.TIR_ENNEMI_HALO if hostile else Palette.teinte_du_tir(tir.effets)
	if hostile:
		add_to_group("tirs_ennemis")
		collision_layer = 16
		collision_mask = 1 | 4
	else:
		collision_layer = 8
		collision_mask = 2 | 4
	body_entered.connect(_sur_contact)

func _physics_process(delta: float) -> void:
	var pas := direction * tir.vitesse * delta
	position += pas
	_distance_parcourue += pas.length()
	_age += delta
	_trainee.push_front(position)
	if _trainee.size() > MEMOIRE_TRAINEE:
		_trainee.resize(MEMOIRE_TRAINEE)
	queue_redraw()
	if _distance_parcourue > tir.portee:
		if not hostile:
			Jeu.tirs_perdus += 1
		queue_free()

func _sur_contact(corps: Node) -> void:
	if not corps.has_method("recevoir_degats"):
		_heurter_un_mur(corps)
		return
	# Un projectile perforant ne doit pas frapper deux fois le meme ennemi.
	if corps.get_instance_id() in _deja_touches:
		return
	_deja_touches.append(corps.get_instance_id())

	if not hostile:
		Jeu.tirs_touches += 1
	# Le Tir est partage entre tous les projectiles d'une salve : on ne le mute
	# jamais, la perte de puissance vit dans le projectile.
	corps.recevoir_degats(tir.degats * _facteur_degats, tir.effets)
	impact_visuel.emit(global_position, couleur, 1.0)
	Sons.jouer("impact", -18.0, randf_range(0.9, 1.2))

	if "gel_bref" in tir.drapeaux and corps.has_method("geler"):
		corps.geler(Reglages.GEL_BREF_DUREE)
	if "foudre" in tir.effets:
		chaine_demandee.emit(global_position, corps, tir)

	if _perforations_restantes > 0:
		_perforations_restantes -= 1
		_facteur_degats *= 1.0 - Reglages.PERFORATION_PERTE
		return
	if _rebonds_restants > 0:
		_rebonds_restants -= 1
		_facteur_degats *= 1.0 - Reglages.REBOND_PERTE
		if "flaque_au_rebond" in tir.drapeaux:
			zone_demandee.emit(global_position, "flaque")
		_rebondir_vers_une_autre_cible()
		return
	_finir()

func _heurter_un_mur(_mur: Node) -> void:
	if not hostile:
		Jeu.tirs_dans_un_mur += 1
	if _rebonds_restants > 0:
		_rebonds_restants -= 1
		_facteur_degats *= 1.0 - Reglages.REBOND_PERTE
		if "flaque_au_rebond" in tir.drapeaux:
			zone_demandee.emit(global_position, "flaque")
		# Sans normale de contact fiable sur une Area2D, on repart vers la cible
		# la plus proche : le rebond reste utile au lieu d'etre aleatoire.
		_rebondir_vers_une_autre_cible()
		return
	impact_visuel.emit(global_position, couleur, 0.6)
	_finir()

func _rebondir_vers_une_autre_cible() -> void:
	var positions: Array[Vector2] = []
	var noeuds: Array[Node] = []
	var groupe := "heros" if hostile else "ennemis"
	for noeud in get_tree().get_nodes_in_group(groupe):
		if not is_instance_valid(noeud) or noeud.get_instance_id() in _deja_touches:
			continue
		noeuds.append(noeud)
		positions.append(noeud.global_position)
	var index := Ciblage.plus_proche(global_position, positions)
	if index == -1:
		direction = -direction
	else:
		direction = global_position.direction_to(positions[index])
	_distance_parcourue = 0.0

func _finir() -> void:
	if tir.fragments > 0:
		fragments_demandes.emit(global_position, direction, tir, hostile)
	if "nuage_a_la_mort" in tir.drapeaux:
		zone_demandee.emit(global_position, "nuage")
	queue_free()

func _draw() -> void:
	# Trainee : quelques segments derriere le noyau, d'autant plus fins qu'ils
	# sont vieux. Ce que le joueur suit des yeux, c'est ce sillage.
	for i in range(_trainee.size() - 1, 0, -1):
		var t := float(i) / float(MEMOIRE_TRAINEE)
		var a := _trainee[i] - position
		var b := _trainee[i - 1] - position
		var c := couleur
		c.a = (1.0 - t) * 0.55
		draw_line(a, b, c, RAYON * 1.6 * (1.0 - t), true)
	Dessin.halo(self, Vector2.ZERO, RAYON * 3.2, couleur, 4)
	draw_circle(Vector2.ZERO, RAYON, couleur)
	draw_circle(Vector2.ZERO, RAYON * 0.55, Palette.TIR_ENNEMI_NOYAU if hostile else Palette.TIR_NOYAU)
	if tir.perforations > 0:
		# Un projectile perforant s'etire : sa forme dit ce qu'il fait.
		draw_set_transform(Vector2.ZERO, direction.angle(), Vector2.ONE)
		draw_colored_polygon(Dessin.dard(RAYON * 2.6, RAYON * 0.8), couleur)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

extends Area2D

# Projectile generique : il n'a aucune logique propre a un reactif, il execute
# le Tir qu'on lui attache. Une fusion n'est donc jamais du code special
# disperse dans le combat.

signal fragments_demandes(origine: Vector2, direction: Vector2, tir_source: Tir, hostile: bool, cible_exclue: int)
signal impact_visuel(position: Vector2, couleur: Color, ampleur: float)
signal soin_demande(montant: float)

const RAYON := Reglages.TIR_RAYON
const MEMOIRE_TRAINEE := 9

var tir: Tir
var direction := Vector2.RIGHT
var hostile := false
var couleur := Palette.TIR_HALO
# Cible que ce projectile ne doit jamais toucher. Un eclat nait dans la creature
# qui vient d'etre percutee : sans cette exclusion il la refrappe a bout portant,
# ce qui transforme Fragmentation en multiplicateur de degats sur cible unique.
var cible_exclue := 0

var _facteur_degats := 1.0
var _distance_parcourue := 0.0
var _rebonds_restants := 0
var _perforations_restantes := 0
var _deja_touches: Array[int] = []
var _trainee: Array[Vector2] = []
var _age := 0.0
var _facteur_tenebres := 1.0
var _dernier_touche := 0
var _termine := false

func _ready() -> void:
	# Le rendu suit les positions entre deux ticks physiques, indispensable sur
	# les projectiles rapides quand l'ecran du telephone rafraichit au-dessus de 60 Hz.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	($CollisionShape2D.shape as CircleShape2D).radius = RAYON
	_rebonds_restants = tir.rebonds
	_perforations_restantes = tir.perforations
	if cible_exclue != 0:
		_deja_touches.append(cible_exclue)
	if not hostile and "tenebres" in tir.drapeaux and Jeu.rng.randf() < Reglages.TENEBRES_CHANCE_SURCHARGE:
		_facteur_tenebres = Reglages.TENEBRES_SURCHARGE_MULT
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
	_appliquer_trajectoire_fusion(delta)
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
	if _termine:
		return
	if not corps.has_method("recevoir_degats"):
		_heurter_un_mur(corps)
		return
	# Un projectile perforant ne doit pas frapper deux fois le meme ennemi.
	if corps.get_instance_id() in _deja_touches:
		return
	_deja_touches.append(corps.get_instance_id())
	_dernier_touche = corps.get_instance_id()

	if not hostile:
		Jeu.tirs_touches += 1
	# Le Tir est partage entre tous les projectiles d'une salve : on ne le mute
	# jamais, la perte de puissance vit dans le projectile.
	var degats_infliges := tir.degats * _facteur_degats * _facteur_tenebres
	corps.recevoir_degats(degats_infliges, tir.effets)
	if not hostile and "lumiere" in tir.effets:
		soin_demande.emit(degats_infliges * Reglages.LUMIERE_VOL_DE_VIE)
	impact_visuel.emit(global_position, couleur, 1.0)
	Sons.jouer("impact", -18.0, randf_range(0.9, 1.2))

	if "perfore_tout" in tir.drapeaux:
		return
	match PrioriteProjectile.apres_impact(_rebonds_restants, _perforations_restantes):
		"rebond":
			_rebonds_restants -= 1
			_facteur_degats *= 1.0 - Reglages.REBOND_PERTE
			_rebondir_vers_une_autre_cible()
		"perforation":
			_perforations_restantes -= 1
			_facteur_degats *= 1.0 - Reglages.PERFORATION_PERTE
		"fin":
			_finir()

func _heurter_un_mur(_mur: Node) -> void:
	if not hostile:
		Jeu.tirs_dans_un_mur += 1
	# Ricochet ne concerne que les impacts sur une creature. Rediriger un tir
	# depuis l'interieur de la collision d'un mur le faisait ressortir de l'autre
	# cote sans nouveau body_entered.
	impact_visuel.emit(global_position, couleur, 0.6)
	_finir(false)

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

func _appliquer_trajectoire_fusion(delta: float) -> void:
	if hostile:
		return
	if "homing" in tir.drapeaux:
		var positions: Array[Vector2] = []
		for cible in get_tree().get_nodes_in_group("ennemis"):
			if is_instance_valid(cible) and not cible.get_instance_id() in _deja_touches:
				positions.append(cible.global_position)
		var index := Ciblage.plus_proche(global_position, positions)
		if index != -1:
			direction = direction.lerp(global_position.direction_to(positions[index]), minf(1.0, delta * 4.5)).normalized()

func _finir(creer_fragments := true) -> void:
	if _termine:
		return
	_termine = true
	if creer_fragments and tir.fragments > 0:
		fragments_demandes.emit(global_position, direction, tir, hostile, _dernier_touche)
	queue_free()

func _draw() -> void:
	Retro16.dessiner_projectile(self, _trainee, position, couleur, hostile,
		"trait_familier" in tir.drapeaux)

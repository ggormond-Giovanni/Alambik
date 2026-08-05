extends CharacterBody2D

# L'alchimiste. Elle ne lit jamais Input : joystick et bot headless passent par
# la meme porte, definir_intention(). Piloter des entrees simulees a deja fait
# rapporter des succes faux ailleurs.

signal tir_demande(tir_courant: Tir, origine: Vector2, direction: Vector2)
signal touchee(position: Vector2)
signal bouclier_brise(position: Vector2, explosif: bool)
signal morte
signal sillage_depose(position: Vector2, gelant: bool)

var stats := Stats.depuis_reglages()
var tir_courant: Tir
var bouclier := 0
var limites := Rect2(Vector2(80, 300), Vector2(920, 1400))

var _intention := Vector2.ZERO
var _intensite := 0.0
var _temps_immobile := 0.0
var _recharge := 0.0
var _invulnerable := 0.0
var _fiole_appliquee := false
var _sillage_minuterie := 0.0
var _rafale_restante := 0
var _rafale_minuterie := 0.0
var _rafale_direction := Vector2.RIGHT
var _visee := Vector2.UP
var _flottement := 0.0
var _secousse := 0.0

func _ready() -> void:
	add_to_group("heros")
	tir_courant = Tir.de_base(stats)
	recalculer()

func definir_intention(direction: Vector2, intensite := 1.0) -> void:
	_intention = direction
	_intensite = intensite

# Appelee a chaque entree de salle : c'est aussi ce qui reforme le bouclier de
# sel, comme le veut sa description.
func recalculer() -> void:
	tir_courant = Mods.appliquer(Tir.de_base(stats), Jeu.mods())
	var drapeaux := tir_courant.drapeaux
	stats.vitesse = Reglages.HEROS_VITESSE * (Reglages.PAS_DE_CHAT_FACTEUR if "pas_de_chat" in drapeaux else 1.0)
	if "fiole_de_vie" in drapeaux and not _fiole_appliquee:
		_fiole_appliquee = true
		stats.pv_max += Reglages.FIOLE_PV
		stats.soigner(Reglages.FIOLE_PV)
	bouclier = 1 if "bouclier_de_sel" in drapeaux else 0

func _physics_process(delta: float) -> void:
	velocity = _intention * stats.vitesse * _intensite
	move_and_slide()
	global_position.x = clampf(global_position.x, limites.position.x, limites.end.x)
	global_position.y = clampf(global_position.y, limites.position.y, limites.end.y)
	if _intention != Vector2.ZERO:
		_deposer_sillage(delta)

func _process(delta: float) -> void:
	_flottement += delta
	_secousse = maxf(0.0, _secousse - delta * 4.0)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_recharge = maxf(0.0, _recharge - delta)
	_avancer_rafale(delta)
	var immobile := _intention == Vector2.ZERO
	_temps_immobile = _temps_immobile + delta if immobile else 0.0
	queue_redraw()

	# Le tir automatique est la grammaire du genre : on s'arrete, on tire.
	var peut_tirer := immobile or "tir_en_course" in tir_courant.drapeaux
	if not peut_tirer:
		return
	if immobile and _temps_immobile < Reglages.TIR_DELAI_ARRET:
		return
	if _recharge > 0.0:
		return
	var positions := cibles_visibles()
	var index := Ciblage.plus_proche(global_position, positions)
	if index == -1:
		return
	var direction := global_position.direction_to(_point_vise(index))
	_visee = direction
	_recharge = 1.0 / maxf(0.2, tir_courant.cadence)
	if "rafale" in tir_courant.drapeaux:
		_rafale_restante = Reglages.RAFALE_NOMBRE
		_rafale_minuterie = 0.0
		_rafale_direction = direction
	else:
		Jeu.tirs_emis += 1
		tir_demande.emit(tir_courant, global_position, direction)
		Sons.jouer("tir", -20.0, randf_range(0.95, 1.08))

func _avancer_rafale(delta: float) -> void:
	if _rafale_restante <= 0:
		return
	_rafale_minuterie -= delta
	if _rafale_minuterie > 0.0:
		return
	_rafale_minuterie = Reglages.RAFALE_INTERVALLE
	_rafale_restante -= 1
	# La rafale suit la cible pendant qu'elle part : sinon elle tire dans le vide
	# des que l'ennemi bouge un peu.
	var positions := cibles_visibles()
	var index := Ciblage.plus_proche(global_position, positions)
	if index != -1:
		_rafale_direction = global_position.direction_to(_point_vise(index))
		_visee = _rafale_direction
	Jeu.tirs_emis += 1
	tir_demande.emit(tir_courant, global_position, _rafale_direction)
	Sons.jouer("tir", -22.0, randf_range(1.0, 1.15))

func _deposer_sillage(delta: float) -> void:
	if not "sillage" in tir_courant.drapeaux:
		return
	_sillage_minuterie -= delta
	if _sillage_minuterie > 0.0:
		return
	_sillage_minuterie = Reglages.SILLAGE_INTERVALLE
	sillage_depose.emit(global_position, "sillage_gelant" in tir_courant.drapeaux)

func cibles_visibles() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for noeud in get_tree().get_nodes_in_group("ennemis"):
		if is_instance_valid(noeud):
			positions.append(noeud.global_position)
	return positions

# Viser ou la cible sera, pas ou elle est. Sans cette anticipation, un ennemi
# qui recule en ligne droite n'est presque jamais touche : la sonde a vu un
# scribe survivre deux minutes a trois cents projectiles.
func _point_vise(index: int) -> Vector2:
	var noeuds := get_tree().get_nodes_in_group("ennemis")
	var valides: Array[Node] = []
	for noeud in noeuds:
		if is_instance_valid(noeud):
			valides.append(noeud)
	if index < 0 or index >= valides.size():
		return global_position
	var cible: Node2D = valides[index]
	var vitesse := Vector2.ZERO
	if "velocity" in cible:
		vitesse = cible.velocity
	# Anticipation bornee : au-dela, une cible qui change d'avis fait rater tous
	# les tirs au lieu de quelques-uns.
	var vol := minf(0.8, global_position.distance_to(cible.global_position) / maxf(80.0, tir_courant.vitesse))
	return cible.global_position + vitesse * vol * 0.9

func recevoir_degats(montant: float, _effets: Array = []) -> void:
	if _invulnerable > 0.0 or stats.est_mort():
		return
	if bouclier > 0:
		bouclier -= 1
		_invulnerable = Reglages.HEROS_INVULNERABILITE
		bouclier_brise.emit(global_position, "bouclier_explosif" in tir_courant.drapeaux)
		Sons.jouer("impact", -8.0, 0.7)
		return
	_invulnerable = Reglages.HEROS_INVULNERABILITE
	_secousse = 1.0
	stats.blesser(montant)
	touchee.emit(global_position)
	Sons.jouer("degat", -6.0)
	if stats.est_mort():
		morte.emit()

func _draw() -> void:
	var r := Reglages.HEROS_RAYON
	var flotte := sin(_flottement * 2.6) * 3.0
	var tremble := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _secousse * 5.0
	var centre := Vector2(0, flotte) + tremble
	var vers := _visee
	var teinte := Palette.teinte_du_tir(tir_courant.effets if tir_courant != null else [])

	# Ombre portee : ancre la silhouette au sol, sinon elle flotte sans poids.
	draw_set_transform(Vector2(0, r * 0.85), 0.0, Vector2(1.0, 0.40))
	draw_circle(Vector2.ZERO, r * 1.05, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _invulnerable > 0.0 and fmod(_invulnerable, 0.16) > 0.08:
		Dessin.halo(self, centre, r * 2.2, Palette.DANGER, 4)

	# Lueur du reactif en main : c'est la couleur de ce que le joueur a construit.
	Dessin.halo(self, centre + vers * r * 0.5, r * 2.4, Color(teinte, 0.9), 5)

	# Robe : large aux epaules, effilee dans le dos. La pointe derriere donne la
	# direction d'un coup d'oeil, sans fleche ni indicateur ajoute.
	var robe := Dessin.goutte(centre, r * 0.98, vers.angle() + PI, 1.5)
	draw_colored_polygon(robe, Palette.HEROS_ROBE)
	Dessin.contour(self, robe, Palette.HEROS_OMBRE, 3.0)
	# Ourlet dore le long du bas de la robe.
	draw_arc(centre, r * 0.86, vers.angle() - 2.2, vers.angle() + 2.2, 18, Palette.HEROS_ACCENT, 3.0, true)

	# Capuche : demi-lune claire, visage d'encre, et une lueur au creux.
	var tete := centre + vers * r * 0.34
	draw_circle(tete, r * 0.56, Palette.HEROS_ROBE)
	Dessin.contour(self, Dessin.polygone_regulier(tete, r * 0.56, 20), Palette.HEROS_OMBRE, 2.5)
	draw_circle(tete + vers * r * 0.14, r * 0.36, Color(0.10, 0.08, 0.14))
	draw_circle(tete + vers * r * 0.22, r * 0.11, Color(teinte, 0.95))

	# La fiole tenue devant, du cote de la visee.
	var main := centre + vers.rotated(0.95) * r * 0.82
	draw_circle(main, r * 0.24, Color(0.10, 0.09, 0.13))
	draw_circle(main, r * 0.17, teinte)
	draw_circle(main - vers * r * 0.04, r * 0.07, Color(1, 1, 1, 0.9))

	if bouclier > 0:
		var anneau := Dessin.polygone_regulier(centre, r * 1.65, 6, _flottement * 0.8)
		Dessin.contour(self, anneau, Color(0.88, 0.94, 1.0, 0.8), 3.5)
		Dessin.halo(self, centre, r * 2.0, Color(0.70, 0.85, 1.0, 0.55), 3)

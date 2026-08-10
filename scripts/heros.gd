extends CharacterBody2D

const CHEMIN_SPRITES := "res://assets/characters/sheets/hero_alchemist_sheet.png"

# L'alchimiste. Elle ne lit jamais Input : joystick et bot headless passent par
# la meme porte, definir_intention(). Piloter des entrees simulees a deja fait
# rapporter des succes faux ailleurs.

signal tir_demande(tir_courant: Tir, origine: Vector2, direction: Vector2)
signal touchee(position: Vector2)
signal bouclier_brise(position: Vector2, explosif: bool)
signal morte
signal sillage_depose(position: Vector2, gelant: bool)

var stats := Stats.depuis_reglages(ReglagesJoueur.rangs_competences_effectifs(), ReglagesJoueur.bonus_niveau_pv(),
	ReglagesJoueur.multiplicateur_niveau_degats(), ReglagesJoueur.multiplicateur_niveau_vitesse())
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
var _inclinaison := 0.0
var _attaque := 0.0
var _texture_heros: Texture2D

func _ready() -> void:
	add_to_group("heros")
	if ResourceLoader.exists(CHEMIN_SPRITES):
		_texture_heros = load(CHEMIN_SPRITES)
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
	stats.vitesse = Reglages.HEROS_VITESSE * ReglagesJoueur.multiplicateur_niveau_vitesse() \
		* ArbreCompetences.multiplicateur_vitesse(ReglagesJoueur.rangs_competences_effectifs()) \
		* (Reglages.PAS_DE_CHAT_FACTEUR if "pas_de_chat" in drapeaux else 1.0)
	if "fiole_de_vie" in drapeaux and not _fiole_appliquee:
		_fiole_appliquee = true
		stats.pv_max += Reglages.FIOLE_PV
		stats.soigner(Reglages.FIOLE_PV)
	bouclier = 1 if "bouclier_de_sel" in drapeaux else 0

func _physics_process(delta: float) -> void:
	var vise := _intention * stats.vitesse * _intensite
	var reponse := Reglages.HEROS_ACCELERATION if vise != Vector2.ZERO else Reglages.HEROS_FREINAGE
	velocity = velocity.move_toward(vise, reponse * delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, limites.position.x, limites.end.x)
	global_position.y = clampf(global_position.y, limites.position.y, limites.end.y)
	if _intention != Vector2.ZERO:
		_deposer_sillage(delta)

func _process(delta: float) -> void:
	_flottement += delta
	_attaque = maxf(0.0, _attaque - delta)
	var inclinaison_visee := clampf(velocity.x / maxf(1.0, stats.vitesse), -1.0, 1.0) * 0.10
	_inclinaison = lerpf(_inclinaison, inclinaison_visee, minf(1.0, delta * 10.0))
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
		_attaque = 0.42
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
	_attaque = 0.42
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
	stats.blesser(montant * (1.0 - ArbreCompetences.reduction_degats(ReglagesJoueur.rangs_competences_effectifs())))
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
	var vitesse_relative := clampf(velocity.length() / maxf(1.0, stats.vitesse), 0.0, 1.0)

	# Ombre portee : ancre la silhouette au sol, sinon elle flotte sans poids.
	draw_set_transform(Vector2(0, r * 0.85), 0.0, Vector2(1.0, 0.40))
	draw_circle(Vector2.ZERO, r * 1.05, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _invulnerable > 0.0 and fmod(_invulnerable, 0.16) > 0.08:
		Dessin.halo(self, centre, r * 2.2, Palette.DANGER, 4)

	# Lueur du reactif en main : c'est la couleur de ce que le joueur a construit.
	Dessin.halo(self, centre + vers * r * 0.5, r * 2.4, Color(teinte, 0.9), 5)

	# Le sprite peint remplace la silhouette primitive. Sa taille depasse un peu
	# la collision pour rester lisible sur un ecran de telephone.
	var taille := r * 5.0
	var modulation := Color.WHITE
	if _invulnerable > 0.0:
		modulation = Color(1.0, 0.72, 0.76) if fmod(_invulnerable, 0.16) < 0.08 else Color.WHITE
	# Une compression tres legere et l'inclinaison donnent du poids aux changements
	# de direction sans deplacer la collision ni ralentir la commande.
	var echelle := Vector2(1.0 + vitesse_relative * 0.035, 1.0 - vitesse_relative * 0.025)
	draw_set_transform(centre + Vector2(0, vitesse_relative * 3.0), _inclinaison, echelle)
	if _texture_heros != null:
		var cadre := 4 if vitesse_relative < 0.08 else int(_flottement * 10.0) % 4
		if _attaque > 0.0:
			cadre = 4 + clampi(int((1.0 - _attaque / 0.42) * 4.0), 0, 3)
		var cellule := Vector2(_texture_heros.get_width() / 4.0, _texture_heros.get_height() / 2.0)
		var source := Rect2(Vector2(float(cadre % 4) * cellule.x, float(cadre / 4) * cellule.y), cellule)
		# Les poses de course sont plus basses dans leur ligne source que les poses
		# de tir. Deux ancres compensent cet ecart pour garder les pieds au meme point.
		var ancre_y := -0.89 if cadre >= 4 else -1.30
		var destination := Rect2(Vector2(-taille * 0.55, taille * ancre_y), Vector2(taille * 1.10, taille * 2.20))
		draw_texture_rect_region(_texture_heros, destination, source, modulation)
	else:
		_dessiner_repli(r, teinte)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# La couleur du tir reste visible au niveau de la fiole, meme si le sprite
	# est fixe : le joueur lit immediatement l'element equipe.
	var fiole := centre + Vector2(r * 0.72, -r * 0.08)
	Dessin.halo(self, fiole, r * 0.48, Color(teinte, 0.65), 3)
	draw_circle(fiole, r * 0.10, Color(teinte, 0.92))

	if bouclier > 0:
		var anneau := Dessin.polygone_regulier(centre, r * 1.65, 6, _flottement * 0.8)
		Dessin.contour(self, anneau, Color(0.88, 0.94, 1.0, 0.8), 3.5)
		Dessin.halo(self, centre, r * 2.0, Color(0.70, 0.85, 1.0, 0.55), 3)

	# La vie suit le mage : l'oeil ne quitte plus le combat pour lire le haut.
	var part_pv := clampf(stats.pv / maxf(1.0, stats.pv_max), 0.0, 1.0)
	var barre := Rect2(Vector2(-58.0, -116.0), Vector2(116.0, 13.0))
	draw_rect(barre.grow(4.0), Color(0.012, 0.018, 0.025, 0.88))
	draw_rect(barre, Color(0.20, 0.08, 0.11))
	var barre_pv := barre
	barre_pv.size.x *= part_pv
	draw_rect(barre_pv, Palette.DANGER.lerp(Color(0.42, 0.90, 0.55), part_pv))
	draw_rect(barre, Color(1.0, 1.0, 1.0, 0.45), false, 2.0)

func _dessiner_repli(r: float, teinte: Color) -> void:
	var capuche := Dessin.goutte(Vector2(0, -r * 0.15), r * 1.35, PI, 1.15)
	draw_colored_polygon(capuche, Palette.HEROS_ROBE)
	Dessin.contour(self, capuche, Palette.HEROS_ACCENT, 3.0)
	draw_circle(Vector2(0, -r * 0.2), r * 0.62, Color(0.035, 0.02, 0.055))
	for cote in [-1.0, 1.0]:
		draw_circle(Vector2(cote * r * 0.22, -r * 0.22), r * 0.11, Palette.HEROS_ACCENT)
	draw_circle(Vector2(r * 0.65, r * 0.2), r * 0.22, teinte)

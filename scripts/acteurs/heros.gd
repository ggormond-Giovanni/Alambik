extends CharacterBody2D

# L'alchimiste. Elle ne lit jamais Input : joystick et bot headless passent par
# la meme porte, definir_intention(). Piloter des entrees simulees a deja fait
# rapporter des succes faux ailleurs.

signal tir_demande(tir_courant: Tir, origine: Vector2, direction: Vector2)
signal touchee(position: Vector2)
signal bouclier_brise(position: Vector2)
signal morte

var stats := Stats.depuis_reglages(ReglagesJoueur.rangs_competences_effectifs(),
	ReglagesJoueur.passifs_equipes_effectifs(), ReglagesJoueur.bonus_objets_effectifs(),
	ReglagesJoueur.niveau_compte_effectif())
var tir_courant: Tir
var bouclier := 0
var limites := Rect2(Vector2(80, 300), Vector2(920, 1400))

var _intention := Vector2.ZERO
var _intensite := 0.0
var _temps_immobile := 0.0
var _recharge := 0.0
var _invulnerable := 0.0
var _rafale_restante := 0
var _rafale_minuterie := 0.0
var _rafale_direction := Vector2.RIGHT
var _visee := Vector2.UP
var _flottement := 0.0
var _secousse := 0.0
var _inclinaison := 0.0
var _attaque := 0.0
var _seconde_chance_disponible := true
var _transformations_initialisees: Array[String] = []
var _resurrections_feu := 0
var _resurrections_eau := 0
var _resurrections_air := 0
var _resurrections_terre := 0
var _resurrections_lumiere := 0
var _protection_terre := 0.0
var _aureole_lumiere := 0.0
func _ready() -> void:
	add_to_group("heros")
	add_to_group("cibles_ennemis")
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
	stats.vitesse = Reglages.HEROS_VITESSE * ArbreCompetences.multiplicateur_vitesse(ReglagesJoueur.rangs_competences_effectifs()) \
		* Sorts.multiplicateur_vitesse(ReglagesJoueur.passifs_equipes_effectifs()) \
		* (1.0 + float(ReglagesJoueur.bonus_objets_effectifs()["vitesse"]))
	bouclier = 1 if "egide" in drapeaux or ArbreCompetences.donne_bouclier(ReglagesJoueur.rangs_competences_effectifs()) or Sorts.donne_bouclier(ReglagesJoueur.passifs_equipes_effectifs()) else 0
	_initialiser_transformations(drapeaux)

func preparer_nouvelle_salle() -> void:
	recalculer()
	# Seconde chance se rearme a chaque salle : une seule fois par grimoire, elle
	# ne servait qu'une fois sur vingt rencontres.
	_seconde_chance_disponible = true
	if "regeneration" in tir_courant.drapeaux:
		stats.soigner(stats.pv_max * Reglages.REGENERATION_PART \
			* ArbreCompetences.multiplicateur_soin(ReglagesJoueur.rangs_competences_effectifs()))
	var soin := ArbreCompetences.soin_par_salle(ReglagesJoueur.rangs_competences_effectifs()) + Sorts.soin_par_salle(ReglagesJoueur.passifs_equipes_effectifs())
	if soin > 0.0:
		stats.soigner(stats.pv_max * soin * ArbreCompetences.multiplicateur_soin(ReglagesJoueur.rangs_competences_effectifs()))

func _physics_process(delta: float) -> void:
	var vise := _intention * stats.vitesse * _intensite
	var reponse := Reglages.HEROS_ACCELERATION if vise != Vector2.ZERO else Reglages.HEROS_FREINAGE
	velocity = velocity.move_toward(vise, reponse * delta)
	move_and_slide()
	global_position = Geometrie.contraindre_dans_rect(global_position, limites, Reglages.HEROS_RAYON)

func _process(delta: float) -> void:
	_flottement += delta
	_attaque = maxf(0.0, _attaque - delta)
	var inclinaison_visee := clampf(velocity.x / maxf(1.0, stats.vitesse), -1.0, 1.0) * 0.10
	_inclinaison = lerpf(_inclinaison, inclinaison_visee, minf(1.0, delta * 10.0))
	_secousse = maxf(0.0, _secousse - delta * 4.0)
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_protection_terre = maxf(0.0, _protection_terre - delta)
	_aureole_lumiere = maxf(0.0, _aureole_lumiere - delta)
	_recharge = maxf(0.0, _recharge - delta)
	_avancer_rafale(delta)
	var immobile := _intention == Vector2.ZERO
	_temps_immobile = _temps_immobile + delta if immobile else 0.0
	queue_redraw()

	# Le tir automatique est la grammaire du genre : on s'arrete, on tire.
	if not immobile:
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
	var cadence_effective := tir_courant.cadence * (Reglages.MANNEQUIN_CADENCE_MULT \
		if "mannequin" in tir_courant.drapeaux and _temps_immobile >= Reglages.MANNEQUIN_DELAI else 1.0)
	_recharge = 1.0 / maxf(0.2, cadence_effective)
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
	var vitesse: Vector2 = cible.velocity if "velocity" in cible else Vector2.ZERO
	return Geometrie.point_anticipe(cible.global_position, vitesse,
		global_position, tir_courant.vitesse)

func recevoir_degats(montant: float, _effets: Array = []) -> void:
	if _invulnerable > 0.0 or stats.est_mort():
		return
	if bouclier > 0:
		bouclier -= 1
		_invulnerable = Reglages.HEROS_INVULNERABILITE
		bouclier_brise.emit(global_position)
		Sons.jouer("impact", -8.0, 0.7)
		return
	_invulnerable = Reglages.HEROS_INVULNERABILITE
	_secousse = 1.0
	var ratio_pv := stats.pv / maxf(1.0, stats.pv_max)
	stats.blesser(montant * (Reglages.TERRE_PROTECTION_MULT if _protection_terre > 0.0 else 1.0) \
		* ((1.0 - Reglages.PEAU_DE_PIERRE_REDUCTION) if "peau_de_pierre" in tir_courant.drapeaux else 1.0) \
		* ((1.0 - Reglages.SCEAU_GARDE_REDUCTION) if "sceau_garde" in tir_courant.drapeaux else 1.0) \
		* (Reglages.SCEAU_RUINE_VULNERABILITE if "sceau_ruine" in tir_courant.drapeaux else 1.0) \
		* (1.0 - ArbreCompetences.reduction_degats(ReglagesJoueur.rangs_competences_effectifs())) \
		* Sorts.multiplicateur_degats_recus(ReglagesJoueur.passifs_equipes_effectifs()) \
		* Sorts.multiplicateur_degats_recus_conditionnel(ReglagesJoueur.passifs_equipes_effectifs(), ratio_pv))
	touchee.emit(global_position)
	Sons.jouer("degat", -6.0)
	if stats.est_mort():
		if _essayer_resurrection_elementaire():
			return
		if _seconde_chance_disponible and ReglagesJoueur.passifs_equipes_effectifs().has("seconde_chance"):
			_seconde_chance_disponible = false
			stats.pv = stats.pv_max * Reglages.SECONDE_CHANCE_PART \
				* float(ReglagesJoueur.passifs_equipes_effectifs()["seconde_chance"])
			bouclier = 1
			Sons.jouer("fusion", -7.0)
			return
		morte.emit()

func multiplicateur_degats_passif() -> float:
	var ratio := stats.pv / maxf(1.0, stats.pv_max)
	var resultat := Sorts.multiplicateur_degats_conditionnel(ReglagesJoueur.passifs_equipes_effectifs(), ratio)
	if "courageux" in tir_courant.drapeaux:
		resultat *= 1.0 + (1.0 - ratio) * Reglages.COURAGEUX_BONUS_MAX
	if "mannequin" in tir_courant.drapeaux and _temps_immobile >= Reglages.MANNEQUIN_DELAI:
		resultat *= Reglages.MANNEQUIN_DEGATS_MULT
	# Elan vital recompense le deplacement : le bonus persiste un court instant
	# apres l'arret, sinon il ne servirait jamais — on tire a l'arret.
	if "elan_vital" in tir_courant.drapeaux and _temps_immobile <= Reglages.ELAN_VITAL_DUREE:
		resultat *= Reglages.ELAN_VITAL_DEGATS_MULT
	if "transformation_heros_tenebres" in tir_courant.drapeaux:
		resultat *= Reglages.TENEBRES_HEROS_DEGATS_MULT
	if _aureole_lumiere > 0.0:
		resultat *= Reglages.LUMIERE_AUREOLE_DEGATS_MULT
	return resultat

func _initialiser_transformations(drapeaux: Array[String]) -> void:
	for element in CatalogueElements.ids():
		var drapeau := "transformation_heros_%s" % element
		if drapeau not in drapeaux or drapeau in _transformations_initialisees:
			continue
		_transformations_initialisees.append(drapeau)
		match element:
			"feu": _resurrections_feu = Reglages.PHENIX_RESURRECTIONS
			"eau": _resurrections_eau = Reglages.EAU_RESURRECTIONS
			"air": _resurrections_air = Reglages.AIR_RESURRECTIONS
			"terre": _resurrections_terre = Reglages.TERRE_RESURRECTIONS
			"lumiere": _resurrections_lumiere = Reglages.LUMIERE_RESURRECTIONS

func _essayer_resurrection_elementaire() -> bool:
	var part := 0.0
	if _resurrections_eau > 0:
		_resurrections_eau -= 1
		part = 1.0
	elif _resurrections_feu > 0:
		_resurrections_feu -= 1
		part = Reglages.PHENIX_PV_PART
	elif _resurrections_terre > 0:
		_resurrections_terre -= 1
		part = Reglages.TERRE_RESURRECTION_PV_PART
		_protection_terre = Reglages.TERRE_PROTECTION_DUREE
	elif _resurrections_lumiere > 0:
		_resurrections_lumiere -= 1
		part = Reglages.LUMIERE_RESURRECTION_PV_PART
		_aureole_lumiere = Reglages.LUMIERE_AUREOLE_DUREE
	elif _resurrections_air > 0:
		_resurrections_air -= 1
		part = Reglages.AIR_RESURRECTION_PV_PART
	if part <= 0.0:
		return false
	stats.pv = stats.pv_max * part
	bouclier = 1
	_invulnerable = Reglages.HEROS_INVULNERABILITE
	Sons.jouer("fusion", -6.0)
	return true

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
	draw_circle(Vector2.ZERO, r * 1.05, Color(0, 0, 0, 0.26))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _invulnerable > 0.0 and fmod(_invulnerable, 0.16) > 0.08:
		Dessin.halo(self, centre, r * 2.2, Palette.DANGER, 4)

	# Lueur du reactif en main : c'est la couleur de ce que le joueur a construit.
	Dessin.halo(self, centre + vers * r * 0.5, r * 2.4, Color(teinte, 0.9), 5)

	# Une compression tres legere et l'inclinaison donnent du poids aux changements
	# de direction sans deplacer la collision ni ralentir la commande.
	var echelle := Vector2(1.0 + vitesse_relative * 0.035, 1.0 - vitesse_relative * 0.025)
	draw_set_transform(centre + Vector2(0, vitesse_relative * 3.0), _inclinaison, echelle)
	Retro16.dessiner_heros(self, _flottement, _attaque > 0.0, vers, teinte)
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
	var barre := Rect2(Vector2(-76.0, -128.0), Vector2(152.0, 20.0))
	draw_rect(barre.grow(7.0), Color(0.008, 0.014, 0.026, 0.94))
	draw_rect(barre.grow(3.0), Color(Palette.OR, 0.72), false, 3.0)
	draw_rect(barre, Color(0.18, 0.035, 0.055, 0.96))
	var barre_pv := barre.grow(-3.0)
	barre_pv.size.x *= part_pv
	var couleur_pv := Palette.DANGER.lerp(Color(0.34, 0.92, 0.54), part_pv)
	draw_rect(barre_pv, couleur_pv.darkened(0.16))
	if barre_pv.size.x > 4.0:
		draw_rect(Rect2(barre_pv.position, Vector2(barre_pv.size.x, 5.0)), couleur_pv.lightened(0.22))
	for cran in 3:
		var x := barre.position.x + barre.size.x * float(cran + 1) / 4.0
		draw_line(Vector2(x, barre.position.y + 2), Vector2(x, barre.end.y - 2), Color(0.02, 0.02, 0.03, 0.52), 2.0)
	var police := ThemeDB.fallback_font
	draw_string(police, Vector2(-76.0, -137.0), "%d / %d" % [ceili(stats.pv), ceili(stats.pv_max)],
		HORIZONTAL_ALIGNMENT_CENTER, 152.0, 16, Color.WHITE)

func _dessiner_repli(r: float, teinte: Color) -> void:
	var capuche := Dessin.goutte(Vector2(0, -r * 0.15), r * 1.35, PI, 1.15)
	draw_colored_polygon(capuche, Palette.HEROS_ROBE)
	Dessin.contour(self, capuche, Palette.HEROS_ACCENT, 3.0)
	draw_circle(Vector2(0, -r * 0.2), r * 0.62, Color(0.13, 0.08, 0.19))
	for cote in [-1.0, 1.0]:
		draw_circle(Vector2(cote * r * 0.22, -r * 0.22), r * 0.11, Palette.HEROS_ACCENT)
	draw_circle(Vector2(r * 0.65, r * 0.2), r * 0.22, teinte)

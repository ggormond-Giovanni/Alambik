extends Control

const FOND_PREMIUM := preload("res://assets/visual/fin_run_premium.png")

# Le coffre se materialise, cede puis revele son contenu. La recompense est
# deja enregistree : l'animation celebre le palier sans ajouter de decision.

signal termine

var _victoire := false
var _salle := 0
var _anim := 0.0
var _duree := 0.0
var _coffre_gouttes := 0
var _objet_obtenu := ""
var _xp_gagnee := 0
var _coffre: Dictionary = {}
var _salles_vaincues := 0
var _pierres_gagnees := 0
var _son_coffre_joue := false

const COFFRE_DEBUT_OUVERTURE := 1.05
const COFFRE_FIN_OUVERTURE := 1.62
const COFFRE_REVELATION := 1.48
const COFFRE_DUREE_ECRAN := 4.8

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	StyleInterface.animer_entree(self)

func afficher(victoire: bool, salle_atteinte: int) -> void:
	_victoire = victoire
	_salle = salle_atteinte
	_duree = Jeu.duree_run()
	_salles_vaincues = salle_atteinte if victoire else maxi(0, salle_atteinte - 1)
	_coffre = Recompenses.coffre_pour(_salles_vaincues)
	if Jeu.mode_run == "grimoire" and int(_coffre["palier"]) > 0:
		_coffre_gouttes = roundi(float(Recompenses.tirer_gouttes_coffre(_coffre, Jeu.chapitre, Jeu.rng)) \
			* ArbreCompetences.multiplicateur_coffre(ReglagesJoueur.rangs_competences_effectifs()) \
			* (Reglages.AVIDITE_GOUTTES_MULT if "avidite" in Jeu.inventaire else 1.0))
		ReglagesJoueur.ajouter_gouttes(_coffre_gouttes)
		var manquants := CatalogueObjets.manquants(Jeu.chapitre, ReglagesJoueur.objets)
		if not manquants.is_empty() and Recompenses.donne_objet(_coffre,
				ReglagesJoueur.grands_coffres_rates(Jeu.chapitre), Jeu.rng):
			_objet_obtenu = CatalogueObjets.tirer_manquant(Jeu.chapitre, ReglagesJoueur.objets, Jeu.rng)
			ReglagesJoueur.ajouter_objet(_objet_obtenu)
		if int(_coffre["palier"]) >= Reglages.SALLES_PAR_RUN:
			ReglagesJoueur.enregistrer_grand_coffre(Jeu.chapitre, not _objet_obtenu.is_empty())
	elif Jeu.mode_run == "mine" and victoire:
		_pierres_gagnees = ReglagesJoueur.ajouter_pierres_forge(ReglagesJoueur.pierres_mine())
	_xp_gagnee = 0 if Jeu.est_retro() else \
		_salle * (2 if Jeu.mode_run == "grimoire" else 1) + (20 if victoire and Jeu.mode_run == "grimoire" else 0)
	if _xp_gagnee > 0:
		ReglagesJoueur.ajouter_experience_compte(_xp_gagnee)
	if Jeu.mode_run == "grimoire":
		ReglagesJoueur.enregistrer_resultat(salle_atteinte, victoire, Jeu.chapitre)
	elif not Jeu.est_retro():
		ReglagesJoueur.enregistrer_resultat_annexe(victoire)

	_retour_automatique()

func _retour_automatique() -> void:
	var attente := COFFRE_DUREE_ECRAN if _a_un_coffre() else 2.6
	await get_tree().create_timer(attente, true).timeout
	get_tree().paused = false
	if Jeu.mode_auto:
		get_tree().quit()
	else:
		StyleInterface.sortir_puis(self, func() -> void:
			get_tree().change_scene_to_file("res://scenes/menu.tscn"))

func _process(delta: float) -> void:
	_anim += delta
	if _a_un_coffre() and not _son_coffre_joue and _anim >= COFFRE_REVELATION:
		_son_coffre_joue = true
		Sons.jouer("coffre", -5.0)
	queue_redraw()

func _a_un_coffre() -> bool:
	return Jeu.mode_run == "grimoire" and int(_coffre.get("palier", 0)) > 0

static func progression_ouverture(temps: float) -> float:
	var brut := clampf((temps - COFFRE_DEBUT_OUVERTURE) /
		(COFFRE_FIN_OUVERTURE - COFFRE_DEBUT_OUVERTURE), 0.0, 1.0)
	return brut * brut * (3.0 - 2.0 * brut)

static func progression_revelation(temps: float) -> float:
	return clampf((temps - COFFRE_REVELATION) / 0.55, 0.0, 1.0)

const HAUT_FIXE := 1120.0
const BAS_FIXE := 800.0
# Reperes lus sur la peinture, dans sa reference de 1080 de large. L'ecran se
# positionnait en fractions de hauteur : le bilan tombait a cote de ses plaques
# et la recompense s'ecrivait par-dessus la rangee d'icones.
const PLAQUE_TITRE := Rect2(140.0, 150.0, 800.0, 172.0)
const LIGNES_BILAN := [476.0, 539.0, 603.0, 666.0, 729.0]
const CENTRE_COFFRE := Vector2(540.0, 1235.0)
const LIGNE_ICONES := 1610.0
const PLAQUE_RECOMPENSE := Rect2(200.0, 1726.0, 680.0, 132.0)

func _repere(reference: Rect2) -> Rect2:
	return FondAdaptatif.rect(size, FOND_PREMIUM, reference, HAUT_FIXE, BAS_FIXE)

func _point(reference: Vector2) -> Vector2:
	return FondAdaptatif.point(size, FOND_PREMIUM, reference, HAUT_FIXE, BAS_FIXE)

func _centre(police: Font, zone: Rect2, texte: String, taille_police: int, couleur: Color) -> void:
	draw_string(police, Vector2(zone.position.x, zone.get_center().y + float(taille_police) * 0.36),
		texte, HORIZONTAL_ALIGNMENT_CENTER, zone.size.x, taille_police, couleur)

func _draw() -> void:
	var police := Polices.CORPS
	FondAdaptatif.dessiner_premium(self, FOND_PREMIUM, size, HAUT_FIXE, BAS_FIXE)
	var titre := ("Prototype terminé" if Jeu.mode_run == "retro" else "Épreuves relevées" if Jeu.mode_run == "epreuve_sorts" else "Mine nettoyée" if Jeu.mode_run == "mine" else "Grimoire refermé") if _victoire else "L'encre a gagné"
	var teinte := Palette.OR if _victoire else Palette.DANGER
	var plaque_titre := _repere(PLAQUE_TITRE)
	_centre(police, Rect2(plaque_titre.position, Vector2(plaque_titre.size.x, plaque_titre.size.y * 0.42)),
		"RÉSUMÉ DE LA DESCENTE", 22, Color(teinte, 0.8))
	_centre(police, Rect2(Vector2(plaque_titre.position.x, plaque_titre.get_center().y),
		Vector2(plaque_titre.size.x, plaque_titre.size.y * 0.5)), titre.to_upper(), 44, teinte)

	var bilan: Array[String] = [
		"%s  •  SALLE %d / %d" % [Jeu.nom_run().to_upper(), _salle, Jeu.salles_du_chapitre()],
		"CRÉATURES EFFACÉES  •  %d" % Jeu.ennemis_abattus,
		"DURÉE  •  %d MIN %02d S" % [int(_duree / 60.0), int(_duree) % 60],
		"AUCUNE PROGRESSION" if Jeu.est_retro() else "+%d XP DE COMPTE" % _xp_gagnee,
	]
	if Jeu.mode_run == "grimoire":
		bilan.append("MEILLEURE DESCENTE  •  SALLE %d" % ReglagesJoueur.meilleure_du_chapitre(Jeu.chapitre))
	for index in mini(bilan.size(), LIGNES_BILAN.size()):
		var ligne := _repere(Rect2(150.0, float(LIGNES_BILAN[index]) - 26.0, 780.0, 52.0))
		_centre(police, ligne, bilan[index], 25,
			Palette.TEXTE if index == 0 else Palette.TEXTE_ATTENUE)

	_dessiner_recompense(police)

	# Ce que la run a construit : la seule trace qui compte.
	var groupe := Jeu.inventaire_groupe()
	var ecart := 128.0
	var depart := 540.0 - float(mini(groupe.size(), 7) - 1) * ecart * 0.5
	for index in mini(groupe.size(), 7):
		var entree: Array = groupe[index]
		var r := Jeu.reactif(str(entree[0]))
		if r == null:
			continue
		var centre := _point(Vector2(depart + float(index) * ecart, LIGNE_ICONES))
		if r.est_transformation:
			Dessin.halo(self, centre, 40.0, Palette.ESSENCE, 3)
		draw_circle(centre, 30.0, Color(0.10, 0.09, 0.14, 0.85))
		draw_arc(centre, 30.0, 0.0, TAU, 22, Color(r.teinte, 0.8), 2.0, true)
		Dessin.glyphe(self, r.glyphe, centre, 15.0, r.teinte)
		if int(entree[1]) > 1:
			draw_string(police, centre + Vector2(16.0, 26.0), "x%d" % int(entree[1]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Palette.TEXTE)

# Le coffre anime existait deja, entierement ecrit, mais _draw ne l'appelait
# jamais : l'ecran se contentait d'un halo et d'une ligne de texte, et le coffre
# peint dans le decor restait donc ferme quoi qu'il arrive.
func _dessiner_recompense(police: Font) -> void:
	if Jeu.mode_run == "mine" and _victoire:
		_centre(police, _repere(PLAQUE_RECOMPENSE),
			"+%d PIERRES DE FORGE" % _pierres_gagnees, 30, Palette.ESSENCE)
		return
	if not _a_un_coffre():
		return
	var centre := _point(CENTRE_COFFRE)
	var ouverture := progression_ouverture(_anim)
	var revelation := progression_revelation(_anim)
	# Le coffre du decor est peint bien plus finement que tout ce qu'on peut
	# tracer ici : on ne le remplace pas, on ouvre sa lumiere par-dessus.
	Dessin.halo(self, centre, 190.0 + ouverture * 120.0,
		Color(Palette.ESSENCE, 0.10 + ouverture * 0.34), 6)
	if ouverture > 0.0:
		var fente := Rect2(centre + Vector2(-176.0, -128.0 - ouverture * 30.0),
			Vector2(352.0, 22.0 + ouverture * 46.0))
		draw_rect(fente, Color(1.0, 0.94, 0.74, 0.28 + 0.52 * ouverture))
		draw_rect(fente.grow(-7.0), Color(1.0, 1.0, 0.94, 0.60 * ouverture))
		var source := centre + Vector2(0.0, -120.0)
		for index in 9:
			var angle := -PI * 0.5 + (float(index) - 4.0) * 0.20
			var longueur := (190.0 + float(index % 3) * 80.0) * ouverture
			draw_line(source, source + Vector2.RIGHT.rotated(angle) * longueur,
				Color(Palette.OR, 0.34 * ouverture), 5.0, true)
		for index in 16:
			var vie := clampf(ouverture * 1.4 - float(index % 5) * 0.09, 0.0, 1.0)
			var angle := -PI * 0.92 + float(index) / 15.0 * PI * 0.84
			var p := source + Vector2(cos(angle), sin(angle)) * (70.0 + float((index * 37) % 110)) * vie
			p.y += vie * vie * 110.0
			draw_circle(p, 3.0 + float(index % 3) * 1.8,
				Color(Palette.ESSENCE, (1.0 - vie * 0.5) * 0.75))
	if revelation <= 0.0:
		return
	# La plaque du bas est peinte vide et attend justement ce texte : l'ecrire
	# sur le coffre le rendait illisible.
	var plaque := _repere(PLAQUE_RECOMPENSE)
	var haute := Rect2(plaque.position, Vector2(plaque.size.x, plaque.size.y * 0.52))
	if _objet_obtenu.is_empty():
		_centre(police, plaque, "%s  •  +%d GOUTTES" % [str(_coffre["nom"]).to_upper(),
			_coffre_gouttes], 29, Color(Palette.ESSENCE, revelation))
		return
	_centre(police, haute, "%s  •  +%d GOUTTES" % [str(_coffre["nom"]).to_upper(),
		_coffre_gouttes], 26, Color(Palette.ESSENCE, revelation))
	var objet: Dictionary = CatalogueObjets.OBJETS[_objet_obtenu]
	_centre(police, Rect2(Vector2(plaque.position.x, plaque.get_center().y),
		Vector2(plaque.size.x, plaque.size.y * 0.48)), str(objet["nom"]).to_upper(), 25,
		Color(objet["teinte"], revelation))

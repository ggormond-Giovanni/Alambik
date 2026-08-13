extends Control

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
		ReglagesJoueur.ajouter_pierres_forge(Reglages.MINE_PIERRES_RECOMPENSE)
	_xp_gagnee = 0 if Jeu.est_retro() else \
		_salle * (2 if Jeu.mode_run == "grimoire" else 1) + (20 if victoire and Jeu.mode_run == "grimoire" else 0)
	if _xp_gagnee > 0:
		ReglagesJoueur.ajouter_experience_compte(_xp_gagnee)
	if Jeu.mode_run == "grimoire":
		ReglagesJoueur.enregistrer_resultat(salle_atteinte, victoire, Jeu.chapitre)
	elif not Jeu.est_retro():
		ReglagesJoueur.enregistrer_resultat_annexe(victoire)

	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 70)
	marge.add_theme_constant_override("margin_right", 70)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 90)
	add_child(marge)

	var retour := Label.new()
	retour.text = "Retour au grimoire…"
	retour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retour.add_theme_font_size_override("font_size", 25)
	retour.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	marge.add_child(retour)
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

func _draw() -> void:
	var police := ThemeDB.fallback_font
	StyleInterface.dessiner_fond(self, size, Palette.OR if _victoire else Palette.DANGER,
		_anim, 0.98)
	var haut := size.y * 0.22
	var titre := ("Prototype terminé" if Jeu.mode_run == "retro" else "Épreuves relevées" if Jeu.mode_run == "epreuve_sorts" else "Mine nettoyée" if Jeu.mode_run == "mine" else "Grimoire refermé") if _victoire else "L'encre a gagné"
	var teinte := Palette.OR if _victoire else Palette.DANGER
	Dessin.halo(self, Vector2(size.x / 2.0, haut - 20.0), 220.0, Color(teinte, 0.5), 5)
	draw_string(police, Vector2(0, haut - 58.0), "RÉSUMÉ DE LA DESCENTE", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(teinte, 0.8))
	draw_string(police, Vector2(0, haut), titre, HORIZONTAL_ALIGNMENT_CENTER, size.x, 62, teinte)
	draw_string(police, Vector2(0, haut + 70.0), "%s — salle %d / %d" % [Jeu.nom_run(), _salle, Jeu.salles_du_chapitre()],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Palette.TEXTE)
	draw_string(police, Vector2(0, haut + 118.0), "Créatures d'encre effacées : %d" % Jeu.ennemis_abattus,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Palette.TEXTE_ATTENUE)
	draw_string(police, Vector2(0, haut + 158.0), "Durée : %d min %02d s" % [int(_duree / 60.0), int(_duree) % 60],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Palette.TEXTE_ATTENUE)
	var bilan_progression := "AUCUNE PROGRESSION ENREGISTRÉE" if Jeu.est_retro() else "+%d XP COMPTE" % _xp_gagnee
	draw_string(police, Vector2(0, haut + 194.0), bilan_progression,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 25, Palette.OR if not Jeu.est_retro() else Palette.TEXTE_ATTENUE)
	if Jeu.mode_run == "grimoire":
		draw_string(police, Vector2(0, haut + 230.0), "Meilleure descente ici : salle %d" % ReglagesJoueur.meilleure_du_chapitre(Jeu.chapitre),
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 28, Color(Palette.OR, 0.8))
	if _a_un_coffre():
		_dessiner_coffre(police, Vector2(size.x * 0.5, haut + 410.0))
	elif Jeu.mode_run == "mine" and _victoire:
		draw_string(police, Vector2(0, haut + 300.0), "+%d PIERRES DE FORGE" % Reglages.MINE_PIERRES_RECOMPENSE,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 29, Palette.ESSENCE)

	# Ce que la run a construit : la seule trace qui compte.
	var groupe := Jeu.inventaire_groupe()
	var x := size.x / 2.0 - float(groupe.size() - 1) * 34.0
	for entree in groupe:
		var id: String = entree[0]
		var r := Jeu.reactif(id)
		if r == null:
			continue
		var inventaire_y := 710.0 if _a_un_coffre() else (475.0 if _victoire else 280.0)
		var centre := Vector2(x, haut + inventaire_y)
		if r.est_transformation:
			Dessin.halo(self, centre, 40.0, Palette.ESSENCE, 3)
		draw_circle(centre, 26.0, Color(0.10, 0.09, 0.14))
		draw_arc(centre, 26.0, 0.0, TAU, 22, Color(r.teinte, 0.8), 2.0, true)
		Dessin.glyphe(self, r.glyphe, centre, 14.0, r.teinte)
		if int(entree[1]) > 1:
			draw_string(police, centre + Vector2(14.0, 24.0), "x%d" % int(entree[1]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.TEXTE)
		x += 68.0

func _dessiner_coffre(police: Font, centre: Vector2) -> void:
	var arrivee := clampf(_anim / 0.62, 0.0, 1.0)
	var rebond := 1.0 - pow(1.0 - arrivee, 3.0)
	var ouverture := progression_ouverture(_anim)
	var revelation := progression_revelation(_anim)
	var secousse := 0.0
	if _anim > 0.62 and _anim < COFFRE_DEBUT_OUVERTURE:
		secousse = sin(_anim * 62.0) * (1.0 - ouverture) * 7.0
	var position := centre + Vector2(secousse, (1.0 - rebond) * 150.0)
	var echelle := 0.58 + rebond * 0.42 + sin(arrivee * PI) * 0.12

	if ouverture > 0.0:
		var flash := sin(clampf((ouverture - 0.08) / 0.92, 0.0, 1.0) * PI)
		Dessin.halo(self, position - Vector2(0, 25), 115.0 + ouverture * 125.0,
			Color(Palette.OR, 0.24 + flash * 0.48), 7)
		var faisceau := PackedVector2Array([
			position + Vector2(-82.0, -12.0), position + Vector2(-155.0, -245.0),
			position + Vector2(155.0, -245.0), position + Vector2(82.0, -12.0)])
		draw_colored_polygon(faisceau, Color(Palette.ESSENCE, 0.045 + ouverture * 0.075))
		for i in 14:
			var angle := TAU * float(i) / 14.0 + sin(float(i) * 7.13) * 0.12
			var longueur := (70.0 + float(i % 4) * 24.0) * ouverture
			var debut := position + Vector2.RIGHT.rotated(angle) * 72.0
			draw_line(debut, debut + Vector2.RIGHT.rotated(angle) * longueur,
				Color(Palette.ESSENCE, flash * (0.20 + float(i % 3) * 0.09)), 3.0, true)
		for i in 18:
			var vie := clampf((ouverture * 1.45 - float(i % 6) * 0.08), 0.0, 1.0)
			var angle := -PI * 0.92 + float(i) / 17.0 * PI * 0.84
			var distance := (55.0 + float((i * 37) % 90)) * vie
			var p := position + Vector2(cos(angle), sin(angle)) * distance
			p.y += vie * vie * 85.0
			draw_circle(p, 3.0 + float(i % 3) * 1.6, Color(Palette.ESSENCE, (1.0 - vie * 0.55) * 0.8))
		if revelation > 0.0:
			for i in 12:
				var a := _anim * (0.65 + float(i % 4) * 0.08) + float(i) * TAU / 12.0
				var rayon_etincelle := 105.0 + sin(_anim * 2.1 + float(i) * 1.7) * 32.0
				var p := position + Vector2(cos(a), sin(a) * 0.58) * rayon_etincelle
				var taille := 2.5 + 2.5 * (0.5 + 0.5 * sin(_anim * 4.0 + float(i)))
				draw_circle(p, taille, Color(Palette.ESSENCE, 0.42 + revelation * 0.38))

	draw_set_transform(position, 0.0, Vector2.ONE * echelle)
	# Ombre, cuve et ferrures gardent une silhouette lisible meme sur petit ecran.
	draw_set_transform(position + Vector2(0, 44), 0.0, Vector2(echelle, echelle * 0.30))
	draw_circle(Vector2.ZERO, 126.0, Color(0, 0, 0, 0.42))
	draw_set_transform(position, 0.0, Vector2.ONE * echelle)
	var corps := Rect2(-112.0, -18.0, 224.0, 82.0)
	if ouverture > 0.0:
		draw_rect(Rect2(-94.0, -30.0, 188.0, 36.0), Color(Palette.ESSENCE, 0.20 + ouverture * 0.42))
	draw_rect(corps, Color(0.24, 0.075, 0.18))
	draw_rect(Rect2(-102.0, -8.0, 204.0, 58.0), Color(0.48, 0.16, 0.27))
	draw_rect(corps, Color(Palette.OR, 0.88), false, 6.0)
	for x in [-72.0, 72.0]:
		draw_rect(Rect2(x - 7.0, -15.0, 14.0, 76.0), Color(Palette.OR, 0.75))
	# Le couvercle se souleve en conservant sa charniere visuelle.
	var haut_couvercle := -55.0 - ouverture * 70.0
	var bas_couvercle := -16.0 - ouverture * 16.0
	var couvercle := PackedVector2Array([
		Vector2(-112.0, bas_couvercle), Vector2(-98.0, haut_couvercle),
		Vector2(98.0, haut_couvercle), Vector2(112.0, bas_couvercle)])
	draw_colored_polygon(couvercle, Color(0.42, 0.12, 0.25))
	Dessin.contour(self, couvercle, Color(Palette.OR, 0.92), 6.0)
	if ouverture < 0.82:
		draw_rect(Rect2(-19.0, -26.0 - ouverture * 20.0, 38.0, 45.0), Color(Palette.OR, 0.95))
		draw_circle(Vector2(0, -5.0 - ouverture * 20.0), 6.0, Color(0.18, 0.06, 0.16))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if revelation > 0.0:
		var alpha := revelation * revelation
		var largeur := minf(620.0, size.x - 40.0)
		var gauche := centre.x - largeur * 0.5
		draw_string(police, Vector2(gauche, centre.y + 132.0),
			"%s  •  +%d GOUTTES" % [str(_coffre["nom"]).to_upper(), _coffre_gouttes],
			HORIZONTAL_ALIGNMENT_CENTER, largeur, 27, Color(Palette.ESSENCE, alpha))
		if not _objet_obtenu.is_empty():
			var objet: Dictionary = CatalogueObjets.OBJETS[_objet_obtenu]
			draw_string(police, Vector2(gauche, centre.y + 174.0), str(objet["nom"]),
				HORIZONTAL_ALIGNMENT_CENTER, largeur, 29, Color(objet["teinte"], alpha))
			draw_string(police, Vector2(gauche, centre.y + 207.0), "Ajouté à l'équipement",
				HORIZONTAL_ALIGNMENT_CENTER, largeur, 22, Color(Palette.TEXTE_ATTENUE, alpha))

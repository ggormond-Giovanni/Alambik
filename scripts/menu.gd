extends Control

const ARBRE := preload("res://ui/arbre_competences.tscn")
const MENU_SORTS := preload("res://ui/sorts.tscn")
const SELECTION_GRIMOIRE := preload("res://ui/selection_grimoire.tscn")
const REGLAGES := preload("res://ui/reglages.tscn")
const EQUIPEMENT := preload("res://ui/equipement.tscn")
const TRANSITION := preload("res://ui/transition_grimoire.tscn")
const ONGLET_MENU := preload("res://ui/onglet_menu.gd")
const DUREE_INTRO := 1.55
const PAGES := ["equipement", "aventure", "maitrises", "sorts"]

# Reperes lus sur la peinture d'accueil, dans sa reference de 1080 de large.
# Tout passe ensuite par Retro16.rect_menu : le texte, sa zone tactile et le
# decor partagent donc une seule source. Auparavant les zones etaient posees a
# une distance fixe du bas de l'ecran pendant que la peinture etirait sa bande
# centrale, et les libelles flottaient au-dessus de leur plaque.
const PLAQUE_CAMPAGNE := Rect2(38.0, 506.0, 196.0, 226.0)
const PLAQUE_MINE := Rect2(38.0, 766.0, 196.0, 226.0)
const PLAQUE_EPREUVE := Rect2(846.0, 506.0, 196.0, 226.0)
const PLAQUE_LIVRE := Rect2(846.0, 766.0, 196.0, 226.0)
# L'en-tete de la peinture affiche un niveau, une barre d'XP et un nombre de
# Gouttes graves dans l'image : ils ne bougeaient jamais, quel que soit le
# compte. Ces deux plaques sont recouvertes par les vraies valeurs.
const PLAQUE_NIVEAU := Rect2(183.0, 108.0, 140.0, 96.0)
const PLAQUE_GOUTTES := Rect2(848.0, 114.0, 84.0, 56.0)
const BANDE_CHAPITRE := Rect2(200.0, 1288.0, 680.0, 76.0)
const PLAQUE_ETAGE := Rect2(390.0, 1502.0, 300.0, 68.0)
const PLAQUE_JOUER := Rect2(110.0, 1588.0, 860.0, 134.0)
const PLAQUE_APERCU := Rect2(200.0, 1364.0, 680.0, 140.0)

var _anim := 0.0
var _temps_intro := 0.0
var _intro_active := false
var _particules: Array[Dictionary] = []
var _conteneur_pages: Control
var _page_actuelle: Control
var _navigation: Control
var _superposition: Control
var _bouton_jouer: Button
var _onglets: Array[Button] = []
var _page := 1
var _doigt_swipe := -1
var _depart_swipe := Vector2.ZERO
var _lancement := false

static var _intro_deja_vue := false

func _ready() -> void:
	if OS.get_name() == "Android":
		get_tree().set_auto_accept_quit(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Sons.musique_menu()
	print("Alambic pret")
	_preparer_particules()
	_construire_structure()
	_afficher_page(1, false)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--page-menu="):
			var page_capture := PAGES.find(argument.trim_prefix("--page-menu="))
			if page_capture >= 0:
				_afficher_page(page_capture, false)
	_intro_active = not _intro_deja_vue
	_conteneur_pages.visible = not _intro_active
	_navigation.visible = not _intro_active
	if not _intro_active:
		StyleInterface.animer_entree(_conteneur_pages, 28.0)
	if "--ouvrir-reglages" in OS.get_cmdline_user_args():
		call_deferred("_ouvrir_reglages")
	Capture.programmer(self)

func _preparer_particules() -> void:
	var alea := RandomNumberGenerator.new()
	alea.seed = 20260801
	for i in 28:
		_particules.append({
			"position": Vector2(alea.randf_range(0.0, 1080.0), alea.randf_range(160.0, 1540.0)),
			"vitesse": Vector2(alea.randf_range(-8.0, 8.0), alea.randf_range(-22.0, -7.0)),
			"rayon": alea.randf_range(2.0, 5.0),
			"phase": alea.randf() * TAU,
		})

func _construire_structure() -> void:
	_conteneur_pages = Control.new()
	_conteneur_pages.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_conteneur_pages)
	_construire_navigation()

func _construire_navigation() -> void:
	_navigation = Control.new()
	_navigation.set_anchors_preset(Control.PRESET_FULL_RECT)
	_navigation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_navigation)
	var socle := PanelContainer.new()
	socle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	socle.offset_left = 14.0
	socle.offset_right = -14.0
	socle.offset_top = -214.0 - Ecran.marge_basse()
	socle.offset_bottom = -10.0 - Ecran.marge_basse()
	socle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	socle.add_theme_stylebox_override("panel", StyleInterface.panneau(
		Color(0.018, 0.035, 0.085, 0.98), Color(Palette.OR, 0.62), 10, 12))
	_navigation.add_child(socle)
	var barre := HBoxContainer.new()
	barre.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barre.offset_left = 24.0
	barre.offset_right = -24.0
	barre.offset_top = -204.0 - Ecran.marge_basse()
	barre.offset_bottom = -18.0 - Ecran.marge_basse()
	barre.add_theme_constant_override("separation", 8)
	_navigation.add_child(barre)
	var donnees := [
		["stuff", "ÉQUIPEMENT", 2],
		["aventure", "AVENTURE", 0],
		["arbre", "MAÎTRISES", 3],
		["sorts", "SORTS", 4],
	]
	for index in donnees.size():
		var onglet := OngletMenu.new()
		onglet.configurer(donnees[index][0], donnees[index][1], donnees[index][2])
		onglet.pressed.connect(func() -> void: _afficher_page(index))
		barre.add_child(onglet)
		_onglets.append(onglet)

func _creer_page(index: int) -> Control:
	match PAGES[index]:
		"equipement":
			var equipement := EQUIPEMENT.instantiate()
			equipement.integre_menu = true
			return equipement
		"maitrises":
			var arbre := ARBRE.instantiate()
			arbre.integre_menu = true
			return arbre
		"sorts":
			var sorts := MENU_SORTS.instantiate()
			sorts.integre_menu = true
			return sorts
	return _creer_aventure()

func _afficher_page(index: int, anime := true) -> void:
	if _superposition != null or _lancement:
		return
	index = clampi(index, 0, PAGES.size() - 1)
	if _page_actuelle != null and index == _page:
		return
	var ancienne := _page_actuelle
	var ancienne_page := _page
	_page = index
	# Chaque page premium peint son propre chassis et son onglet actif. La barre
	# globale reste au-dessus uniquement comme couche tactile persistante.
	_navigation.modulate.a = 0.02
	var nouvelle := _creer_page(index)
	_page_actuelle = nouvelle
	_conteneur_pages.add_child(nouvelle)
	for i in _onglets.size():
		_onglets[i].actif = i == _page
	if ancienne == null:
		return
	Sons.jouer("choix", -17.0, 1.08)
	if not anime:
		ancienne.queue_free()
		return
	var direction := 1.0 if index > ancienne_page else -1.0
	var distance := 32.0 if ReglagesJoueur.effets_reduits else 180.0
	nouvelle.position.x = distance * direction
	nouvelle.modulate.a = 0.0
	var sortie := ancienne.create_tween().set_parallel(true)
	sortie.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	sortie.tween_property(ancienne, "position:x", -distance * direction, 0.22)
	sortie.tween_property(ancienne, "modulate:a", 0.0, 0.16)
	var entree := nouvelle.create_tween().set_parallel(true)
	entree.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entree.tween_property(nouvelle, "position:x", 0.0, 0.34)
	entree.tween_property(nouvelle, "modulate:a", 1.0, 0.24)
	await sortie.finished
	if is_instance_valid(ancienne):
		ancienne.queue_free()

func _creer_aventure() -> Control:
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	var reglages := StyleInterface.zone_tactile(_ouvrir_reglages)
	reglages.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	reglages.offset_left = -144.0
	reglages.offset_right = -28.0
	reglages.offset_top = Ecran.marge_haute() + 26.0
	reglages.offset_bottom = reglages.offset_top + 112.0
	page.add_child(reglages)
	_ajouter_acces(page, PLAQUE_CAMPAGNE, _ouvrir_campagne)
	_ajouter_acces(page, PLAQUE_MINE, func() -> void: _lancer_mode("mine", {"nom": "Mine"}))
	_ajouter_acces(page, PLAQUE_EPREUVE,
		func() -> void: _lancer_mode("epreuve_sorts", {"nom": "Défi alchimique"}))
	_ajouter_acces(page, PLAQUE_LIVRE, _ouvrir_livre)
	var chapitre := _ajouter_acces(page, BANDE_CHAPITRE.merge(PLAQUE_APERCU), _ouvrir_campagne)
	chapitre.tooltip_text = "Changer de monde ou de chapitre"
	_bouton_jouer = _ajouter_acces(page, PLAQUE_JOUER, _jouer_immediatement)
	page.resized.connect(func() -> void: _replacer_zones(page))
	_replacer_zones(page)
	return page

func _ajouter_acces(parent: Control, reference: Rect2, action: Callable) -> Button:
	var bouton := StyleInterface.zone_tactile(action)
	bouton.set_meta("reference", reference)
	parent.add_child(bouton)
	return bouton

# Les zones suivent la peinture, pas le bord de l'ecran : c'est la seule facon
# qu'elles restent sur leur plaque quand la bande centrale s'etire.
func _replacer_zones(parent: Control) -> void:
	var taille := get_viewport_rect().size
	for enfant in parent.get_children():
		if enfant is Button and enfant.has_meta("reference"):
			var adapte := Retro16.rect_menu(taille, enfant.get_meta("reference"))
			enfant.position = adapte.position
			enfant.size = adapte.size

func _jouer_immediatement() -> void:
	var chapitre := Chapitres.par_index(ReglagesJoueur.chapitre_choisi)
	_lancer_mode("grimoire", chapitre)

func _lancer_mode(mode: String, destination: Dictionary) -> void:
	if _lancement:
		return
	_lancement = true
	ReglagesJoueur.choisir_mode_run(mode)
	Sons.jouer("choix", -10.0)
	Sons.demarrer_musique_combat()
	var transition := TRANSITION.instantiate()
	transition.configurer(destination)
	add_child(transition)
	transition.terminee.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/run.tscn"))

func _ouvrir_campagne() -> void:
	var selection := SELECTION_GRIMOIRE.instantiate()
	selection.selection_seulement = true
	_ouvrir_superposition(selection)

func _ouvrir_livre() -> void:
	# Le Livre vivant présente aujourd'hui les chapitres connus. Il pourra recevoir
	# le bestiaire et les collections sans changer la navigation principale.
	_ouvrir_campagne()

func _ouvrir_reglages() -> void:
	_ouvrir_superposition(REGLAGES.instantiate())

func _ouvrir_superposition(panneau: Control) -> void:
	if _superposition != null or _lancement:
		return
	Sons.jouer("choix", -12.0)
	_superposition = panneau
	add_child(panneau)
	move_child(panneau, get_child_count() - 1)
	if panneau.has_signal("ferme"):
		panneau.ferme.connect(func() -> void:
			if is_instance_valid(panneau):
				panneau.queue_free()
			if _superposition == panneau:
				_superposition = null
			queue_redraw())

func _input(evenement: InputEvent) -> void:
	if _intro_active or _superposition != null or _lancement:
		return
	if evenement is InputEventScreenTouch:
		var toucher := evenement as InputEventScreenTouch
		if toucher.pressed and _doigt_swipe == -1:
			_doigt_swipe = toucher.index
			_depart_swipe = toucher.position
		elif not toucher.pressed and toucher.index == _doigt_swipe:
			_traiter_swipe(toucher.position - _depart_swipe)
			_doigt_swipe = -1
	elif evenement is InputEventMouseButton and evenement.button_index == MOUSE_BUTTON_LEFT:
		if evenement.pressed:
			_depart_swipe = evenement.position
		else:
			_traiter_swipe(evenement.position - _depart_swipe)

func _traiter_swipe(ecart: Vector2) -> void:
	if absf(ecart.x) < 120.0 or absf(ecart.x) < absf(ecart.y) * 1.35:
		return
	_afficher_page(_page - 1 if ecart.x > 0.0 else _page + 1)

func _notification(quoi: int) -> void:
	if quoi != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _superposition != null and is_instance_valid(_superposition):
		var cible := _superposition
		StyleInterface.sortir_puis(cible, func() -> void:
			if is_instance_valid(cible): cible.queue_free()
			if _superposition == cible: _superposition = null)
	elif _page != 1:
		_afficher_page(1)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _process(delta: float) -> void:
	_anim += delta
	if _intro_active:
		_temps_intro += delta
		if _temps_intro >= DUREE_INTRO:
			_intro_active = false
			_intro_deja_vue = true
			_conteneur_pages.visible = true
			_navigation.visible = true
			StyleInterface.animer_entree(_conteneur_pages, 34.0)
	var hauteur := get_viewport_rect().size.y
	for p in _particules:
		p["position"] += p["vitesse"] * delta
		if p["position"].y < 150.0: p["position"].y = hauteur * 0.76
	queue_redraw()

func _draw() -> void:
	var police := Polices.CORPS
	var taille := get_viewport_rect().size
	if _page == 1 and not _intro_active:
		Retro16.dessiner_menu_premium(self, taille, _anim)
	else:
		Retro16.dessiner_fond_accueil(self, taille, _anim)
	if _intro_active:
		_dessiner_intro(police, taille)
		return
	if _page != 1:
		return
	# La maquette premium porte le châssis et l'illustration. Les boutons réels
	# sont des zones tactiles invisibles exactement alignées sur elle.
	_dessiner_selection_dynamique(police, taille)

func _dessiner_entete(police: Font, taille: Vector2) -> void:
	var plaque := Retro16.rect_menu(taille, PLAQUE_NIVEAU)
	_masquer_libelle_peint(plaque)
	_texte_centre(police, Rect2(plaque.position, Vector2(plaque.size.x, plaque.size.y * 0.42)),
		"NIVEAU %d" % ReglagesJoueur.niveau_compte_effectif(), 22, Palette.TEXTE)
	var requis := maxi(1, ReglagesJoueur.experience_compte_requise())
	var ratio := clampf(float(ReglagesJoueur.experience_compte) / float(requis), 0.0, 1.0)
	var barre := Rect2(plaque.position.x + 10.0, plaque.get_center().y + 2.0,
		plaque.size.x - 20.0, 10.0)
	draw_rect(barre, Color(0.010, 0.014, 0.030, 0.95))
	draw_rect(Rect2(barre.position, Vector2(barre.size.x * ratio, barre.size.y)), Palette.ESSENCE)
	draw_rect(barre, Color(Palette.OR, 0.55), false, 2.0)
	_texte_centre(police, Rect2(plaque.position.x, barre.end.y, plaque.size.x, 26.0),
		"%d / %d" % [ReglagesJoueur.experience_compte, requis], 18, Palette.TEXTE_ATTENUE)

	var plaque_gouttes := Retro16.rect_menu(taille, PLAQUE_GOUTTES)
	_masquer_libelle_peint(plaque_gouttes)
	_texte_centre(police, plaque_gouttes, ReglagesJoueur.gouttes_affichees(), 26, Palette.OR)

func _dessiner_selection_dynamique(police: Font, taille: Vector2) -> void:
	_dessiner_entete(police, taille)
	var chapitre := Chapitres.par_index(ReglagesJoueur.chapitre_choisi)
	var monde: Dictionary = Chapitres.MONDES[int(chapitre["monde"])]
	var titre := "MONDE %s — %s  ·  CHAPITRE %d" % [monde["numero"],
		str(monde["nom"]).to_upper(), int(chapitre["chapitre_monde"])]
	var bande := Retro16.rect_menu(taille, BANDE_CHAPITRE)
	_masquer_libelle_peint(bande)
	draw_string(police, Vector2(bande.position.x + 14.0, _ligne_de_base(bande, 25)), "‹",
		HORIZONTAL_ALIGNMENT_LEFT, 44.0, 25, Palette.OR)
	draw_string(police, Vector2(bande.end.x - 58.0, _ligne_de_base(bande, 25)), "›",
		HORIZONTAL_ALIGNMENT_RIGHT, 44.0, 25, Palette.OR)
	_texte_centre(police, bande.grow_individual(-62.0, 0.0, -62.0, 0.0), titre, 25, Palette.TEXTE)

	var meilleur := ReglagesJoueur.meilleure_du_chapitre(ReglagesJoueur.chapitre_choisi)
	var monde_termine := true
	var premier_chapitre := int(chapitre["monde"]) * 3
	for index in range(premier_chapitre, premier_chapitre + 3):
		if ReglagesJoueur.meilleure_du_chapitre(index) < Reglages.SALLES_PAR_RUN:
			monde_termine = false
			break
	var progression := "★  MONDE TERMINÉ" if monde_termine else \
		"ÉTAGE MAX  %d / %d" % [meilleur, int(chapitre["salles"])]
	var plaque := Retro16.rect_menu(taille, PLAQUE_ETAGE)
	_masquer_libelle_peint(plaque)
	_texte_centre(police, plaque, progression, 24,
		Palette.OR if monde_termine else Palette.TEXTE)

# La peinture porte un libelle d'exemple grave dans l'image : le texte reel doit
# recouvrir sa plaque, sinon les deux se superposent. Le masque imite le creux
# des cartouches peints plutot que de poser un rectangle plat sur l'illustration.
func _masquer_libelle_peint(plaque: Rect2) -> void:
	var creux := plaque.grow(-4.0)
	draw_rect(creux, Color(0.030, 0.024, 0.055, 0.98))
	draw_rect(creux, Color(0.010, 0.008, 0.022, 0.85), false, 3.0)
	draw_rect(creux.grow(-4.0), Color(Palette.OR, 0.16), false, 2.0)

func _ligne_de_base(zone: Rect2, taille_police: int) -> float:
	return zone.get_center().y + float(taille_police) * 0.36

func _texte_centre(police: Font, zone: Rect2, texte: String, taille_police: int,
		couleur: Color) -> void:
	draw_string(police, Vector2(zone.position.x, _ligne_de_base(zone, taille_police)), texte,
		HORIZONTAL_ALIGNMENT_CENTER, zone.size.x, taille_police, couleur)

func _dessiner_intro(police: Font, taille: Vector2) -> void:
	var alpha := clampf(_temps_intro * 4.0, 0.0, 1.0) * clampf((DUREE_INTRO - _temps_intro) * 5.0, 0.0, 1.0)
	var y := taille.y * 0.46
	var centre := Vector2(taille.x * 0.5, y - 118.0)
	Dessin.halo(self, centre, 150.0, Color(Palette.ESSENCE, alpha * 0.32), 6)
	Dessin.glyphe(self, "fiole", centre, 28.0, Color(Palette.OR, alpha))
	draw_string(police, Vector2(0.0, y), "ALAMBIC", HORIZONTAL_ALIGNMENT_CENTER, taille.x, 92, Color(Palette.TEXTE, alpha))
	draw_string(police, Vector2(0.0, y + 72.0), "Le grimoire vivant s'éveille…", HORIZONTAL_ALIGNMENT_CENTER, taille.x, 29, Color(Palette.TEXTE_ATTENUE, alpha))

func _dessiner_profil(police: Font, taille: Vector2) -> void:
	var haut := Ecran.marge_haute() + 24.0
	var cadre := Rect2(24.0, haut, taille.x - 188.0, 170.0)
	draw_rect(cadre, Color(0.020, 0.042, 0.105, 0.94))
	draw_rect(cadre, Color(Palette.OR, 0.72), false, 4.0)
	draw_rect(cadre.grow(-9.0), Color(Palette.BORD_PAGE, 0.42), false, 2.0)
	var portrait := Rect2(42.0, haut + 18.0, 126.0, 126.0)
	draw_rect(portrait, Color(Retro16.VIOLET, 0.24))
	draw_rect(portrait, Palette.OR, false, 3.0)
	draw_set_transform(portrait.get_center() + Vector2(0.0, 34.0), 0.0, Vector2.ONE * 0.72)
	Retro16.dessiner_heros(self, _anim, false, Vector2.RIGHT, Palette.OR)
	draw_set_transform(Vector2.ZERO)
	draw_string(police, Vector2(190.0, haut + 55.0), ReglagesJoueur.titre_compte(), HORIZONTAL_ALIGNMENT_LEFT, 440.0, 32, Palette.TEXTE)
	draw_string(police, Vector2(190.0, haut + 94.0), "NIVEAU %d" % ReglagesJoueur.niveau_compte_effectif(), HORIZONTAL_ALIGNMENT_LEFT, 260.0, 23, Palette.OR)
	var progression := float(ReglagesJoueur.experience_compte) / float(maxi(1, ReglagesJoueur.experience_compte_requise()))
	var barre := Rect2(190.0, haut + 112.0, 390.0, 20.0)
	draw_rect(barre, Color(0.008, 0.015, 0.040, 0.94))
	draw_rect(Rect2(barre.position + Vector2(3.0, 3.0), Vector2((barre.size.x - 6.0) * progression, barre.size.y - 6.0)), Palette.OR)
	draw_rect(barre, Color(Palette.BORD_PAGE, 0.72), false, 2.0)
	var goutte := Vector2(654.0, haut + 72.0)
	draw_colored_polygon(Dessin.goutte(goutte, 22.0, PI, 1.2), Palette.ESSENCE)
	draw_string(police, goutte + Vector2(34.0, 10.0), ReglagesJoueur.gouttes_affichees(), HORIZONTAL_ALIGNMENT_LEFT, 130.0, 28, Palette.TEXTE)

func _dessiner_heros_menu(centre: Vector2) -> void:
	var flottement := sin(_anim * 2.2) * 7.0
	Dessin.halo(self, centre + Vector2(0.0, 36.0), 178.0, Color(Palette.ESSENCE, 0.18), 6)
	draw_set_transform(centre + Vector2(0.0, flottement), 0.0, Vector2.ONE * 2.72)
	Retro16.dessiner_heros(self, _anim, false, Vector2.RIGHT, Palette.OR)
	draw_set_transform(Vector2.ZERO)

func _dessiner_chapitre(police: Font, taille: Vector2) -> void:
	var chapitre := Chapitres.par_index(ReglagesJoueur.chapitre_choisi)
	var progression := ReglagesJoueur.meilleure_du_chapitre(ReglagesJoueur.chapitre_choisi)
	var rect := Rect2(134.0, taille.y - Ecran.marge_basse() - 548.0, taille.x - 268.0, 138.0)
	draw_rect(rect, Color(0.022, 0.050, 0.115, 0.96))
	draw_rect(rect, Color(chapitre["teinte"], 0.82), false, 4.0)
	draw_rect(rect.grow(-8.0), Color(Palette.OR, 0.36), false, 2.0)
	draw_string(police, rect.position + Vector2(22.0, 48.0), "‹", HORIZONTAL_ALIGNMENT_LEFT, 40.0, 30, Palette.OR)
	draw_string(police, rect.position + Vector2(rect.size.x - 62.0, 48.0), "›", HORIZONTAL_ALIGNMENT_RIGHT, 40.0, 30, Palette.OR)
	draw_string(police, rect.position + Vector2(64.0, 48.0), chapitre["nom"], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 128.0, 29, Palette.TEXTE)
	draw_string(police, rect.position + Vector2(20.0, 91.0), "PROGRESSION  •  %d / %d" % [progression, chapitre["salles"]], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 40.0, 22, Palette.TEXTE_ATTENUE)

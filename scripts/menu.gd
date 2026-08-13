extends Control

const ARBRE := preload("res://ui/arbre_competences.tscn")
const MENU_SORTS := preload("res://ui/sorts.tscn")
const SELECTION_GRIMOIRE := preload("res://ui/selection_grimoire.tscn")
const REGLAGES := preload("res://ui/reglages.tscn")
const EQUIPEMENT := preload("res://ui/equipement.tscn")
const ONGLET_MENU := preload("res://ui/onglet_menu.gd")
const DUREE_INTRO := 1.55
const PAGES := ["stuff", "grimoire", "arbre", "sorts"]

# Titre, bouton, meilleur resultat. Aucun sprite : le grimoire est dessine.

var _anim := 0.0
var _temps_intro := 0.0
var _intro_active := false
var _particules: Array[Dictionary] = []
var _interface: Control
var _bouton_action: Button
var _onglets: Array[Button] = []
var _page := 1
var _panneau_menu: Control
var _superposition: Control
var _doigt_navigation := -1
var _depart_navigation := Vector2.ZERO
var _glissement_page := 0.0
var _animation_page: Tween

static var _intro_deja_vue := false

func _ready() -> void:
	# Sur Android, Retour est une commande de navigation, pas un ordre de tuer
	# l'application au milieu d'un écran.
	if OS.get_name() == "Android":
		get_tree().set_auto_accept_quit(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Sons.musique_menu()
	print("Alambic pret")
	var alea := RandomNumberGenerator.new()
	alea.seed = 20260801
	for i in 34:
		_particules.append({
			"position": Vector2(alea.randf_range(0.0, 1080.0), alea.randf_range(0.0, 1920.0)),
			"vitesse": Vector2(alea.randf_range(-12.0, 12.0), alea.randf_range(-26.0, -8.0)),
			"rayon": alea.randf_range(2.0, 6.0),
			"phase": alea.randf() * TAU,
		})
	_construire_carrousel()
	_intro_active = not _intro_deja_vue
	_interface.visible = not _intro_active
	if not _intro_active:
		StyleInterface.animer_entree(_interface, 16.0)
	Capture.programmer(self)

func _construire_carrousel() -> void:
	_interface = Control.new()
	_interface.set_anchors_preset(Control.PRESET_FULL_RECT)
	_interface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_interface)
	var reglages := Button.new()
	reglages.text = "⚙"
	reglages.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	reglages.offset_left = -146.0
	reglages.offset_right = -34.0
	reglages.offset_top = Ecran.marge_haute() + 22.0
	reglages.offset_bottom = reglages.offset_top + Ecran.CIBLE_TACTILE
	reglages.add_theme_font_size_override("font_size", 38)
	StyleInterface.styliser_bouton(reglages, Palette.TEXTE_ATTENUE, true)
	reglages.pressed.connect(_ouvrir_reglages)
	_interface.add_child(reglages)

	_bouton_action = Button.new()
	_bouton_action.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bouton_action.offset_left = 72.0
	_bouton_action.offset_right = -72.0
	_bouton_action.offset_top = -322.0 - Ecran.marge_basse()
	_bouton_action.offset_bottom = -174.0 - Ecran.marge_basse()
	_bouton_action.add_theme_font_size_override("font_size", 31)
	StyleInterface.styliser_bouton(_bouton_action, Palette.OR)
	_bouton_action.pressed.connect(_ouvrir_page_courante)
	_interface.add_child(_bouton_action)

	var socle_navigation := PanelContainer.new()
	socle_navigation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	socle_navigation.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	socle_navigation.offset_left = 18.0
	socle_navigation.offset_right = -18.0
	socle_navigation.offset_top = -160.0 - Ecran.marge_basse()
	socle_navigation.offset_bottom = -12.0 - Ecran.marge_basse()
	socle_navigation.add_theme_stylebox_override("panel", StyleInterface.panneau(
		Color(0.025, 0.020, 0.045, 0.96), Color(Palette.BORD_PAGE, 0.28), 25, 8))
	_interface.add_child(socle_navigation)

	var navigation := HBoxContainer.new()
	navigation.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	navigation.offset_left = 24.0
	navigation.offset_right = -24.0
	navigation.offset_top = -154.0 - Ecran.marge_basse()
	navigation.offset_bottom = -18.0 - Ecran.marge_basse()
	navigation.add_theme_constant_override("separation", 8)
	_interface.add_child(navigation)
	for index in PAGES.size():
		var onglet := OngletMenu.new()
		onglet.configurer(PAGES[index])
		onglet.pressed.connect(func() -> void: _changer_page(index))
		navigation.add_child(onglet)
		_onglets.append(onglet)
	_changer_page(1, false)

func _changer_page(index: int, ouvrir_contenu := true) -> void:
	if _panneau_menu != null and is_instance_valid(_panneau_menu):
		_panneau_menu.queue_free()
		_panneau_menu = null
	var nouvelle_page := clampi(index, 0, PAGES.size() - 1)
	var ancienne_page := _page
	if nouvelle_page != _page:
		Sons.jouer("choix", -17.0, 1.08)
	_page = nouvelle_page
	if ancienne_page != _page:
		if _animation_page != null and _animation_page.is_valid():
			_animation_page.kill()
		var direction := 1.0 if _page > ancienne_page else -1.0
		_glissement_page = direction * (20.0 if ReglagesJoueur.effets_reduits else 74.0)
		_interface.position.x = direction * (8.0 if ReglagesJoueur.effets_reduits else 30.0)
		_interface.modulate.a = 0.70
		_animation_page = create_tween()
		_animation_page.set_parallel(true)
		_animation_page.set_trans(Tween.TRANS_QUINT)
		_animation_page.set_ease(Tween.EASE_OUT)
		_animation_page.tween_property(self, "_glissement_page", 0.0,
			0.14 if ReglagesJoueur.effets_reduits else 0.38)
		_animation_page.tween_property(_interface, "position:x", 0.0,
			0.14 if ReglagesJoueur.effets_reduits else 0.38)
		_animation_page.tween_property(_interface, "modulate:a", 1.0,
			0.10 if ReglagesJoueur.effets_reduits else 0.25)
	for i in _onglets.size():
		_onglets[i].set("actif", i == _page)
	match PAGES[_page]:
		"grimoire":
			_bouton_action.text = "CHOISIR UN GRIMOIRE"
			_bouton_action.disabled = false
			_bouton_action.visible = true
		"stuff":
			_bouton_action.text = "GÉRER L'ÉQUIPEMENT"
			_bouton_action.disabled = false
			_bouton_action.visible = true
		_:
			_bouton_action.visible = false
	queue_redraw()
	if ouvrir_contenu and PAGES[_page] == "arbre":
		_ouvrir_arbre()
	elif ouvrir_contenu and PAGES[_page] == "sorts":
		_ouvrir_sorts()

func _ouvrir_page_courante() -> void:
	if PAGES[_page] == "grimoire":
		_ouvrir_bibliotheque()
	elif PAGES[_page] == "stuff":
		_ouvrir_equipement()

func _ouvrir_equipement() -> void:
	Sons.jouer("choix", -12.0)
	var equipement := EQUIPEMENT.instantiate()
	_superposition = equipement
	add_child(equipement)
	equipement.ferme.connect(func() -> void:
		equipement.queue_free()
		_superposition = null
		queue_redraw())

func _gui_input(evenement: InputEvent) -> void:
	if _intro_active:
		return
	if evenement is InputEventScreenTouch:
		var toucher := evenement as InputEventScreenTouch
		if toucher.pressed and _doigt_navigation == -1:
			_doigt_navigation = toucher.index
			_depart_navigation = toucher.position
		elif not toucher.pressed and toucher.index == _doigt_navigation:
			var ecart := toucher.position.x - _depart_navigation.x
			_doigt_navigation = -1
			if absf(ecart) >= 110.0:
				_changer_page(_page - 1 if ecart > 0.0 else _page + 1)
				accept_event()

func _ouvrir_arbre() -> void:
	Sons.jouer("choix", -12.0)
	var arbre := ARBRE.instantiate()
	arbre.integre_menu = true
	_panneau_menu = arbre
	add_child(arbre)
	move_child(_interface, get_child_count() - 1)
	arbre.ferme.connect(func() -> void:
		arbre.queue_free()
		_panneau_menu = null
		_changer_page(1, false))

func _ouvrir_sorts() -> void:
	Sons.jouer("choix", -12.0)
	var sorts := MENU_SORTS.instantiate()
	sorts.integre_menu = true
	_panneau_menu = sorts
	add_child(sorts)
	move_child(_interface, get_child_count() - 1)
	sorts.ferme.connect(func() -> void:
		sorts.queue_free()
		_panneau_menu = null
		_changer_page(1, false))

func _ouvrir_bibliotheque() -> void:
	Sons.jouer("choix", -12.0)
	var bibliotheque := SELECTION_GRIMOIRE.instantiate()
	_superposition = bibliotheque
	add_child(bibliotheque)
	bibliotheque.ferme.connect(func() -> void:
		bibliotheque.queue_free()
		_superposition = null)

func _ouvrir_reglages() -> void:
	Sons.jouer("choix", -12.0)
	var panneau := REGLAGES.instantiate()
	_superposition = panneau
	add_child(panneau)
	panneau.ferme.connect(func() -> void:
		panneau.queue_free()
		_superposition = null)

func _notification(quoi: int) -> void:
	if quoi != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _superposition != null and is_instance_valid(_superposition):
		var cible := _superposition
		StyleInterface.sortir_puis(cible, func() -> void:
			if is_instance_valid(cible):
				cible.queue_free()
			if _superposition == cible:
				_superposition = null)
	elif _panneau_menu != null and is_instance_valid(_panneau_menu):
		_changer_page(1, false)
	elif _page != 1:
		_changer_page(1, false)
	else:
		# Au centre, Retour laisse Android gérer la mise en arrière-plan via son
		# geste système ; aucune confirmation minuscule ni fermeture accidentelle.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _process(delta: float) -> void:
	_anim += delta
	if _intro_active:
		_temps_intro += delta
		if _temps_intro >= DUREE_INTRO:
			_intro_active = false
			_intro_deja_vue = true
			_interface.visible = true
			StyleInterface.animer_entree(_interface, 16.0)
	var hauteur := get_viewport_rect().size.y
	for p in _particules:
		p["position"] += p["vitesse"] * delta
		if p["position"].y < -20.0:
			p["position"].y = hauteur + 20.0
	queue_redraw()

func _draw() -> void:
	var police := ThemeDB.fallback_font
	var taille := get_viewport_rect().size
	StyleInterface.dessiner_fond(self, taille, Palette.OR, _anim)
	if _intro_active:
		var alpha := clampf(_temps_intro * 4.0, 0.0, 1.0) * clampf((DUREE_INTRO - _temps_intro) * 5.0, 0.0, 1.0)
		var y := taille.y * 0.46
		var centre_intro := Vector2(taille.x * 0.5, y - 118.0)
		Dessin.halo(self, centre_intro, 150.0, Color(Palette.ESSENCE, alpha * 0.32), 6)
		for index in 3:
			var rayon := 42.0 + float(index) * 22.0
			var debut := _temps_intro * (0.8 + index * 0.24) * (-1.0 if index % 2 else 1.0)
			draw_arc(centre_intro, rayon, debut, debut + PI * 1.15, 28,
				Color(Palette.OR.lerp(Palette.ESSENCE, float(index) / 2.0), alpha * 0.74), 3.0, true)
		Dessin.glyphe(self, "fiole", centre_intro, 28.0, Color(Palette.OR, alpha))
		draw_string(police, Vector2(0.0, y), "ALAMBIC", HORIZONTAL_ALIGNMENT_CENTER,
			taille.x, 92, Color(Palette.TEXTE, alpha))
		draw_line(Vector2(taille.x * 0.34, y + 22.0), Vector2(taille.x * 0.66, y + 22.0),
			Color(Palette.OR, alpha * 0.55), 2.0, true)
		draw_string(police, Vector2(0.0, y + 72.0), "Plongez dans les grimoires . . .",
			HORIZONTAL_ALIGNMENT_CENTER, taille.x, 29, Color(Palette.TEXTE_ATTENUE, alpha))
		return
	draw_set_transform(Vector2(_glissement_page, 0.0))
	_dessiner_menu_user(police, taille)
	draw_set_transform(Vector2.ZERO)

func _dessiner_menu_user(police: Font, taille: Vector2) -> void:
	for p in _particules:
		var scintille: float = 0.18 + 0.25 * sin(_anim * 2.0 + p["phase"])
		draw_circle(p["position"], p["rayon"], Color(Palette.ESSENCE, scintille))
	var centre_heros := Vector2(taille.x * 0.5, taille.y * 0.45)
	if PAGES[_page] == "grimoire":
		draw_circle(centre_heros + Vector2(0.0, 178.0), 136.0, Color(Palette.MOUSSE_MAGIQUE, 0.16))
		draw_arc(centre_heros + Vector2(0.0, 166.0), 132.0, 0.0, TAU, 48, Color(Palette.OR, 0.42), 4.0, true)
		Dessin.halo(self, centre_heros, 245.0, Color(Palette.ESSENCE, 0.50), 6)
		_dessiner_heros_menu(centre_heros)
	var titres := ["ÉQUIPEMENT", "GRIMOIRES", "MAÎTRISE", "ARSENAL"]
	var cadre_profil := Rect2(28.0, Ecran.marge_haute() + 22.0, taille.x - 56.0, 190.0)
	draw_rect(cadre_profil, Color(0.025, 0.020, 0.045, 0.72))
	draw_rect(cadre_profil, Color(Palette.BORD_PAGE, 0.24), false, 2.0)
	draw_rect(Rect2(cadre_profil.position, Vector2(6.0, cadre_profil.size.y)),
		Color(Palette.OR, 0.58))
	draw_string(police, Vector2(54.0, Ecran.marge_haute() + 86.0), titres[_page],
		HORIZONTAL_ALIGNMENT_LEFT, taille.x - 190.0, 46, Palette.TEXTE)
	var xp_pourcent := roundi(100.0 * float(ReglagesJoueur.experience_compte) \
		/ float(maxi(1, ReglagesJoueur.experience_compte_requise())))
	draw_string(police, Vector2(54.0, Ecran.marge_haute() + 132.0), "%s  •  NIVEAU %d  •  XP %d %%" % [
		ReglagesJoueur.titre_compte(), ReglagesJoueur.niveau_compte_effectif(), xp_pourcent],
		HORIZONTAL_ALIGNMENT_LEFT, taille.x - 190.0, 25, Palette.TEXTE_ATTENUE)
	var barre_xp := Rect2(54.0, Ecran.marge_haute() + 154.0, 430.0, 16.0)
	draw_rect(barre_xp, Color(0.04, 0.04, 0.07, 0.86))
	var remplissage_xp := barre_xp.grow(-3.0)
	remplissage_xp.size.x *= float(xp_pourcent) / 100.0
	draw_rect(remplissage_xp, Palette.OR.lerp(Palette.ESSENCE, 0.35))
	draw_rect(barre_xp, Color(Palette.BORD_PAGE, 0.62), false, 2.0)
	var centre_monnaie := Vector2(taille.x - 220.0, Ecran.marge_haute() + 96.0)
	draw_colored_polygon(Dessin.goutte(centre_monnaie, 20.0, PI, 1.2), Palette.ESSENCE)
	draw_string(police, centre_monnaie + Vector2(28.0, 10.0), ReglagesJoueur.gouttes_affichees(),
		HORIZONTAL_ALIGNMENT_LEFT, 72.0, 27, Palette.TEXTE)
	match PAGES[_page]:
		"stuff": _dessiner_page_stuff(police, taille)
		"grimoire": _dessiner_page_grimoire(police, taille)
	for index in PAGES.size():
		var x := taille.x * 0.5 + (float(index) - float(PAGES.size() - 1) / 2.0) * 28.0
		draw_circle(Vector2(x, taille.y - Ecran.marge_basse() - 340.0), 6.0 if index == _page else 4.0,
			Palette.OR if index == _page else Color(Palette.TEXTE_ATTENUE, 0.45))

func _dessiner_heros_menu(centre: Vector2) -> void:
	var flottement := sin(_anim * 2.2) * 7.0
	draw_set_transform(centre + Vector2(0.0, flottement), 0.0, Vector2.ONE * 3.2)
	Retro16.dessiner_heros(self, _anim, false, Vector2.RIGHT, Palette.OR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _dessiner_page_stuff(police: Font, taille: Vector2) -> void:
	var noms := ["ANNEAU GAUCHE", "ANNEAU DROIT", "COLLIER"]
	var glyphes := ["cristal", "cristal", "goutte"]
	var slots := ["anneau_gauche", "anneau_droit", "collier"]
	for i in 3:
		var rect := Rect2(84.0 + float(i) * ((taille.x - 168.0) / 3.0), taille.y * 0.34,
			(taille.x - 196.0) / 3.0, 330.0)
		_dessiner_carte_menu(rect, [Palette.OR, Palette.ESSENCE, Palette.MOUSSE_MAGIQUE][i])
		var centre := rect.get_center() + Vector2(0.0, -38.0)
		Dessin.halo(self, centre, 84.0, Color([Palette.OR, Palette.ESSENCE, Palette.MOUSSE_MAGIQUE][i], 0.45), 4)
		Dessin.glyphe(self, glyphes[i], centre, 42.0, [Palette.OR, Palette.ESSENCE, Palette.MOUSSE_MAGIQUE][i])
		draw_string(police, rect.position + Vector2(0.0, 240.0), noms[i], HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x, 27, Palette.TEXTE)
		var slot: String = slots[i]
		var equipe := str(ReglagesJoueur.equipements.get(slot, ""))
		var libelle := str(CatalogueObjets.OBJETS.get(equipe, {}).get("nom", "VIDE"))
		draw_string(police, rect.position + Vector2(0.0, 286.0), libelle, HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x, 19, Palette.TEXTE_ATTENUE)
	if not ReglagesJoueur.dernier_objet_obtenu.is_empty() and CatalogueObjets.OBJETS.has(ReglagesJoueur.dernier_objet_obtenu):
		var dernier: Dictionary = CatalogueObjets.OBJETS[ReglagesJoueur.dernier_objet_obtenu]
		draw_string(police, Vector2(60.0, taille.y * 0.34 + 390.0), "DERNIER OBJET  •  %s  •  PIERRES %d" % [dernier["nom"], ReglagesJoueur.pierres_forge],
			HORIZONTAL_ALIGNMENT_CENTER, taille.x - 120.0, 24, dernier["teinte"])

func _dessiner_page_grimoire(police: Font, taille: Vector2) -> void:
	var chapitre := Chapitres.par_index(ReglagesJoueur.chapitre_choisi)
	var progression := ReglagesJoueur.meilleure_du_chapitre(ReglagesJoueur.chapitre_choisi)
	var rect := Rect2(132.0, taille.y * 0.66, taille.x - 264.0, 138.0)
	_dessiner_carte_menu(rect, chapitre["teinte"])
	draw_string(police, rect.position + Vector2(20.0, 48.0), chapitre["nom"], HORIZONTAL_ALIGNMENT_CENTER,
		rect.size.x - 40.0, 28, Palette.TEXTE)
	draw_string(police, rect.position + Vector2(20.0, 98.0), "PROGRESSION  •  %d / %d" % [progression, chapitre["salles"]],
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 40.0, 23, Palette.TEXTE_ATTENUE)

func _dessiner_carte_menu(rect: Rect2, teinte: Color) -> void:
	draw_rect(rect, Color(0.11, 0.09, 0.17, 0.88))
	draw_rect(rect, Color(teinte, 0.62), false, 3.0)
	draw_rect(Rect2(rect.position, Vector2(8.0, rect.size.y)), Color(teinte, 0.74))

extends Control

const CHEMIN_SPRITES_HEROS := "res://assets/characters/sheets/hero_alchemist_sheet.png"
const ARBRE := preload("res://ui/arbre_competences.tscn")
const MENU_SORTS := preload("res://ui/sorts.tscn")
const SELECTION_GRIMOIRE := preload("res://ui/selection_grimoire.tscn")
const REGLAGES := preload("res://ui/reglages.tscn")
const ONGLET_MENU := preload("res://ui/onglet_menu.gd")
const DUREE_INTRO := 1.55
const PAGES := ["boutique", "stuff", "grimoire", "arbre", "sorts"]

# Titre, bouton, meilleur resultat. Aucun sprite : le grimoire est dessine.

var _anim := 0.0
var _temps_intro := 0.0
var _intro_active := false
var _particules: Array[Dictionary] = []
var _texture_heros: Texture2D
var _interface: Control
var _bouton_arbre: Button
var _bouton_dev: Button
var _bouton_grimoire: Button
var _bouton_action: Button
var _onglets: Array[Button] = []
var _page := 2
var _panneau_menu: Control
var _superposition: Control
var _doigt_navigation := -1
var _depart_navigation := Vector2.ZERO

static var _intro_deja_vue := false

func _ready() -> void:
	# Sur Android, Retour est une commande de navigation, pas un ordre de tuer
	# l'application au milieu d'un écran.
	if OS.get_name() == "Android":
		get_tree().set_auto_accept_quit(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Sons.musique_menu()
	if ResourceLoader.exists(CHEMIN_SPRITES_HEROS):
		_texture_heros = load(CHEMIN_SPRITES_HEROS)
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
	_changer_page(2, false)

func _changer_page(index: int, ouvrir_contenu := true) -> void:
	if _panneau_menu != null and is_instance_valid(_panneau_menu):
		_panneau_menu.queue_free()
		_panneau_menu = null
	var nouvelle_page := clampi(index, 0, PAGES.size() - 1)
	if nouvelle_page != _page:
		Sons.jouer("choix", -17.0, 1.08)
	_page = nouvelle_page
	for i in _onglets.size():
		_onglets[i].set("actif", i == _page)
	match PAGES[_page]:
		"grimoire":
			_bouton_action.text = "CHOISIR UN GRIMOIRE"
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

func _construire() -> void:
	_interface = MarginContainer.new()
	_interface.set_anchors_preset(Control.PRESET_FULL_RECT)
	_interface.add_theme_constant_override("margin_left", 90)
	_interface.add_theme_constant_override("margin_right", 90)
	_interface.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 70)
	add_child(_interface)

	var colonne := VBoxContainer.new()
	colonne.alignment = BoxContainer.ALIGNMENT_END
	colonne.add_theme_constant_override("separation", 16)
	_interface.add_child(colonne)

	var outils := HBoxContainer.new()
	outils.add_theme_constant_override("separation", 10)
	colonne.add_child(outils)
	_bouton_arbre = Button.new()
	_bouton_arbre.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	_bouton_arbre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bouton_arbre.add_theme_font_size_override("font_size", 30)
	StyleInterface.styliser_bouton(_bouton_arbre, Palette.ESSENCE)
	_bouton_arbre.pressed.connect(_ouvrir_arbre)
	outils.add_child(_bouton_arbre)
	var bouton_sorts := Button.new()
	bouton_sorts.text = "SORTS\n1 • 2 • 1"
	bouton_sorts.custom_minimum_size = Vector2(210, Ecran.CIBLE_TACTILE)
	bouton_sorts.add_theme_font_size_override("font_size", 23)
	StyleInterface.styliser_bouton(bouton_sorts, Palette.OR)
	bouton_sorts.pressed.connect(_ouvrir_sorts)
	outils.add_child(bouton_sorts)
	_bouton_dev = Button.new()
	_bouton_dev.custom_minimum_size = Vector2(180, Ecran.CIBLE_TACTILE)
	_bouton_dev.add_theme_font_size_override("font_size", 23)
	_bouton_dev.pressed.connect(_basculer_dev)
	outils.add_child(_bouton_dev)
	var bouton_reglages := Button.new()
	bouton_reglages.text = "RÉGLAGES"
	bouton_reglages.custom_minimum_size = Vector2(190, Ecran.CIBLE_TACTILE)
	bouton_reglages.add_theme_font_size_override("font_size", 23)
	StyleInterface.styliser_bouton(bouton_reglages, Palette.TEXTE_ATTENUE, true)
	bouton_reglages.pressed.connect(_ouvrir_reglages)
	outils.add_child(bouton_reglages)
	_rafraichir_bouton_arbre()

	_bouton_grimoire = Button.new()
	_bouton_grimoire.text = "CHOISIR UN GRIMOIRE\n10 livres • 30 pages chacun"
	_bouton_grimoire.custom_minimum_size = Vector2(0, 136)
	_bouton_grimoire.add_theme_font_size_override("font_size", 32)
	StyleInterface.styliser_bouton(_bouton_grimoire, Palette.OR)
	_bouton_grimoire.pressed.connect(_ouvrir_bibliotheque)
	colonne.add_child(_bouton_grimoire)

func _rafraichir_bouton_arbre() -> void:
	_bouton_arbre.text = "%s NIVEAU %d\nARBRE ✦ %s" % [ReglagesJoueur.titre_heros(),
		ReglagesJoueur.niveau_heros_effectif(), ReglagesJoueur.gouttes_affichees()]
	_bouton_dev.text = "DEV\n%s" % ("ON" if ReglagesJoueur.mode_dev else "OFF")
	StyleInterface.styliser_bouton(_bouton_dev, Palette.DANGER if ReglagesJoueur.mode_dev else Palette.TEXTE_ATTENUE, true)

func _basculer_dev() -> void:
	ReglagesJoueur.definir_mode_dev(not ReglagesJoueur.mode_dev)
	Sons.jouer("choix", -12.0)
	get_tree().reload_current_scene()

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
		_changer_page(2, false))

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
		_changer_page(2, false))

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
		_superposition.queue_free()
		_superposition = null
	elif _panneau_menu != null and is_instance_valid(_panneau_menu):
		_changer_page(2, false)
	elif _page != 2:
		_changer_page(2, false)
	else:
		# Au centre, Retour laisse Android gérer la mise en arrière-plan via son
		# geste système ; aucune confirmation minuscule ni fermeture accidentelle.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _chapitres_ouverts() -> int:
	var total := 0
	for index in Chapitres.nombre():
		if ReglagesJoueur.chapitre_debloque(index):
			total += 1
	return total

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
	draw_rect(Rect2(Vector2.ZERO, taille), Palette.FOND)
	if _intro_active:
		var alpha := clampf(_temps_intro * 4.0, 0.0, 1.0) * clampf((DUREE_INTRO - _temps_intro) * 5.0, 0.0, 1.0)
		var y := taille.y * 0.46
		draw_string(police, Vector2(0.0, y), "ALAMBIC", HORIZONTAL_ALIGNMENT_CENTER,
			taille.x, 92, Color(Palette.TEXTE, alpha))
		draw_string(police, Vector2(0.0, y + 72.0), "Plongez dans les grimoires . . .",
			HORIZONTAL_ALIGNMENT_CENTER, taille.x, 29, Color(Palette.TEXTE_ATTENUE, alpha))
		return
	_dessiner_menu_user(police, taille)
	return

	# Poussiere d'encre en suspension : le menu respire sans coûter une image.
	for p in _particules:
		var scintille: float = 0.25 + 0.25 * sin(_anim * 2.0 + p["phase"])
		draw_circle(p["position"], p["rayon"], Color(Palette.PARCHEMIN_VEINE, scintille))

	var centre := Vector2(taille.x / 2.0, taille.y * 0.27)
	Dessin.halo(self, centre, 300.0, Color(Palette.ESSENCE, 0.35), 6)

	# Le grimoire ouvert, vu de face : deux pages et une reliure.
	var largeur := 380.0
	var hauteur := 260.0
	var page_g := PackedVector2Array([
		centre + Vector2(-largeur, -hauteur * 0.75),
		centre + Vector2(-14.0, -hauteur * 0.55),
		centre + Vector2(-14.0, hauteur * 0.75),
		centre + Vector2(-largeur, hauteur * 0.55)])
	var page_d := PackedVector2Array([
		centre + Vector2(largeur, -hauteur * 0.75),
		centre + Vector2(14.0, -hauteur * 0.55),
		centre + Vector2(14.0, hauteur * 0.75),
		centre + Vector2(largeur, hauteur * 0.55)])
	for page in [page_g, page_d]:
		draw_colored_polygon(page, Palette.PARCHEMIN_SOMBRE)
		Dessin.contour(self, page, Palette.BORD_PAGE, 3.0)
	draw_rect(Rect2(centre.x - 16.0, centre.y - hauteur * 0.62, 32.0, hauteur * 1.32), Color(0.14, 0.11, 0.19))

	# Lignes d'ecriture suggerees, et une goutte qui tombe sur la page droite.
	for cote: float in [-1.0, 1.0]:
		for i in 7:
			var t := float(i) / 6.0
			var y := centre.y + lerpf(-hauteur * 0.42, hauteur * 0.5, t)
			var x1 := centre.x + cote * 40.0
			var x2 := centre.x + cote * (largeur - 50.0)
			draw_line(Vector2(x1, y), Vector2(x2, y), Color(Palette.PARCHEMIN_VEINE, 0.55), 3.0)
	# Le personnage est la promesse visuelle du jeu des le premier ecran.
	var taille_heros := 360.0 + sin(_anim * 2.0) * 5.0
	if _texture_heros != null:
		var cellule := Vector2(_texture_heros.get_width() / 4.0, _texture_heros.get_height() / 2.0)
		var source := Rect2(Vector2(0.0, cellule.y), cellule)
		draw_texture_rect_region(_texture_heros,
			Rect2(centre + Vector2(-taille_heros * 0.45, -taille_heros * 0.92), Vector2(taille_heros * 0.9, taille_heros * 1.8)), source)
	var chute := fmod(_anim * 0.5, 1.0)
	var goutte := centre + Vector2(largeur * 0.45, lerpf(-hauteur, hauteur * 0.3, chute))
	draw_colored_polygon(Dessin.goutte(goutte, 12.0, PI / 2.0, 1.4), Color(Palette.ESSENCE, 1.0 - chute * 0.3))
	Dessin.halo(self, goutte, 40.0, Color(Palette.ESSENCE, 0.6), 3)

	var titre_y := taille.y * 0.57
	draw_string(police, Vector2(0, titre_y), "ALAMBIC", HORIZONTAL_ALIGNMENT_CENTER, taille.x, 96, Palette.TEXTE)
	draw_string(police, Vector2(0, titre_y + 54.0), "descente dans un grimoire vivant",
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 30, Palette.TEXTE_ATTENUE)
	var filet := PackedVector2Array()
	for i in 61:
		var t := float(i) / 60.0
		filet.append(Vector2(lerpf(140.0, taille.x - 140.0, t), titre_y + 86.0 + sin(t * 6.0 + _anim) * 4.0))
	draw_polyline(filet, Color(Palette.OR, 0.4), 2.0, true)

	if ReglagesJoueur.meilleure_salle > 0:
		draw_string(police, Vector2(0, titre_y + 148.0),
			"%d chapitre(s) ouvert(s) sur %d" % [_chapitres_ouverts(), Chapitres.nombre()],
			HORIZONTAL_ALIGNMENT_CENTER, taille.x, 30, Color(Palette.OR, 0.85))

	# Trois lignes de regles : sur telephone, personne ne lit un didacticiel,
	# mais tout le monde lit trois lignes avant d'appuyer.
	var regles := [
		"Le pouce se pose n'importe où en bas de l'écran.",
		"On tire tout seul, dès qu'on s'arrête.",
		"Aux alambics, deux réactifs se perdent pour une essence plus forte.",
	]
	for i in regles.size():
		draw_string(police, Vector2(0, titre_y + 212.0 + float(i) * 42.0), regles[i],
			HORIZONTAL_ALIGNMENT_CENTER, taille.x, 26, Color(Palette.TEXTE_ATTENUE, 0.95))

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
	var titres := ["BOUTIQUE", "ÉQUIPEMENT", "GRIMOIRES", "MAÎTRISE", "ARSENAL"]
	draw_string(police, Vector2(54.0, Ecran.marge_haute() + 86.0), titres[_page],
		HORIZONTAL_ALIGNMENT_LEFT, taille.x - 190.0, 46, Palette.TEXTE)
	var xp_pourcent := 100 if ReglagesJoueur.est_prestigieux() else roundi(
		100.0 * float(ReglagesJoueur.experience_heros) / float(maxi(1, ReglagesJoueur.experience_heros_requise())))
	draw_string(police, Vector2(54.0, Ecran.marge_haute() + 132.0), "%s  •  NIVEAU %d  •  XP %d %%" % [
		ReglagesJoueur.titre_heros(), ReglagesJoueur.niveau_heros_effectif(), xp_pourcent],
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
		"boutique": _dessiner_page_boutique(police, taille)
		"stuff": _dessiner_page_stuff(police, taille)
		"grimoire": _dessiner_page_grimoire(police, taille)
	for index in PAGES.size():
		var x := taille.x * 0.5 + (float(index) - 2.0) * 28.0
		draw_circle(Vector2(x, taille.y - Ecran.marge_basse() - 340.0), 6.0 if index == _page else 4.0,
			Palette.OR if index == _page else Color(Palette.TEXTE_ATTENUE, 0.45))

func _dessiner_heros_menu(centre: Vector2) -> void:
	if _texture_heros == null:
		draw_colored_polygon(Dessin.goutte(centre, 88.0, PI, 1.2), Palette.HEROS_ROBE)
		return
	var cadre := int(_anim * 4.0) % 4
	var cellule := Vector2(_texture_heros.get_width() / 4.0, _texture_heros.get_height() / 2.0)
	var source := Rect2(Vector2(float(cadre) * cellule.x, 0.0), cellule)
	var flottement := sin(_anim * 2.2) * 7.0
	var destination := Rect2(centre + Vector2(-108.0, -220.0 + flottement), Vector2(216.0, 470.0))
	draw_texture_rect_region(_texture_heros, destination, source)

func _dessiner_page_boutique(police: Font, taille: Vector2) -> void:
	var rect := Rect2(92.0, taille.y * 0.31, taille.x - 184.0, 430.0)
	_dessiner_carte_menu(rect, Palette.OR)
	draw_colored_polygon(Dessin.etoile(rect.get_center() + Vector2(0.0, -62.0), 64.0, 28.0, 6, -PI / 2.0),
		Color(Palette.OR, 0.34))
	Dessin.contour(self, Dessin.etoile(rect.get_center() + Vector2(0.0, -62.0), 64.0, 28.0, 6, -PI / 2.0), Palette.OR, 4.0)
	draw_string(police, rect.position + Vector2(0.0, 278.0), "L’ÉCHOPPE ARRIVE BIENTÔT",
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 34, Palette.TEXTE)
	draw_multiline_string(police, rect.position + Vector2(70.0, 332.0),
		"Aucune monnaie fictive tant que ses récompenses ne sont pas définies.",
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 140.0, 24, 2, Palette.TEXTE_ATTENUE)

func _dessiner_page_stuff(police: Font, taille: Vector2) -> void:
	var noms := ["ARME", "ROBE", "TALISMAN"]
	var glyphes := ["lance", "goutte", "cristal"]
	for i in 3:
		var rect := Rect2(84.0 + float(i) * ((taille.x - 168.0) / 3.0), taille.y * 0.34,
			(taille.x - 196.0) / 3.0, 330.0)
		_dessiner_carte_menu(rect, [Palette.OR, Palette.ESSENCE, Palette.MOUSSE_MAGIQUE][i])
		var centre := rect.get_center() + Vector2(0.0, -38.0)
		Dessin.halo(self, centre, 84.0, Color([Palette.OR, Palette.ESSENCE, Palette.MOUSSE_MAGIQUE][i], 0.45), 4)
		Dessin.glyphe(self, glyphes[i], centre, 42.0, [Palette.OR, Palette.ESSENCE, Palette.MOUSSE_MAGIQUE][i])
		draw_string(police, rect.position + Vector2(0.0, 240.0), noms[i], HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x, 27, Palette.TEXTE)
		var slot: String = ["arme", "robe", "talisman"][i]
		var nombre := 0
		for id in ReglagesJoueur.objets:
			if CatalogueObjets.OBJETS.has(id) and CatalogueObjets.OBJETS[id]["slot"] == slot:
				nombre += 1
		draw_string(police, rect.position + Vector2(0.0, 286.0), "%d OBJET%s" % [nombre, "S" if nombre != 1 else ""], HORIZONTAL_ALIGNMENT_CENTER,
			rect.size.x, 19, Palette.TEXTE_ATTENUE)
	if not ReglagesJoueur.dernier_objet_obtenu.is_empty() and CatalogueObjets.OBJETS.has(ReglagesJoueur.dernier_objet_obtenu):
		var dernier: Dictionary = CatalogueObjets.OBJETS[ReglagesJoueur.dernier_objet_obtenu]
		draw_string(police, Vector2(60.0, taille.y * 0.34 + 390.0), "DERNIER LOOT  •  %s  •  %s" % [dernier["nom"], CatalogueObjets.bonus_effectif_texte(ReglagesJoueur.dernier_objet_obtenu)],
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

func _dessiner_page_stats(police: Font, taille: Vector2) -> void:
	var rangs := ReglagesJoueur.rangs_competences_effectifs()
	var pv := Reglages.HEROS_PV + ReglagesJoueur.bonus_niveau_pv() + ArbreCompetences.bonus_pv(rangs)
	var degats := Reglages.TIR_DEGATS * ReglagesJoueur.multiplicateur_niveau_degats() * ArbreCompetences.multiplicateur_degats(rangs)
	var vitesse := Reglages.HEROS_VITESSE * ReglagesJoueur.multiplicateur_niveau_vitesse() * ArbreCompetences.multiplicateur_vitesse(rangs)
	var donnees := [["PV", roundi(pv), Palette.DANGER], ["PUISSANCE", roundi(degats), Palette.OR],
		["VITESSE", roundi(vitesse), Palette.ESSENCE]]
	for i in donnees.size():
		var rect := Rect2(58.0 + float(i) * ((taille.x - 116.0) / 3.0), taille.y * 0.67,
			(taille.x - 140.0) / 3.0, 118.0)
		_dessiner_carte_menu(rect, donnees[i][2])
		draw_string(police, rect.position + Vector2(18.0, 38.0), donnees[i][0], HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 36.0, 20, Palette.TEXTE_ATTENUE)
		draw_string(police, rect.position + Vector2(18.0, 88.0), str(donnees[i][1]), HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 36.0, 35, Palette.TEXTE)

func _dessiner_page_sorts(police: Font, taille: Vector2) -> void:
	var actif := str(Sorts.ACTIFS.get(ReglagesJoueur.sort_actif_effectif(), {}).get("nom", "Aucun sort actif"))
	var ultime := str(Sorts.ULTIMES.get(ReglagesJoueur.ultime_effectif(), {}).get("nom", "Aucun ultime"))
	var rect := Rect2(80.0, taille.y * 0.67, taille.x - 160.0, 170.0)
	_dessiner_carte_menu(rect, Palette.ESSENCE)
	draw_string(police, rect.position + Vector2(28.0, 46.0), "ACTIF  •  " + actif,
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56.0, 27, Palette.TEXTE)
	draw_string(police, rect.position + Vector2(28.0, 94.0), "ULTIME  •  " + ultime,
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56.0, 27, Palette.TEXTE)
	draw_string(police, rect.position + Vector2(28.0, 140.0), "PASSIFS  •  %d / 2" % ReglagesJoueur.passifs_equipes.size(),
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 56.0, 25, Palette.TEXTE_ATTENUE)

func _dessiner_page_arbre(police: Font, taille: Vector2) -> void:
	var acquis := ReglagesJoueur.rangs_competences.size()
	var rect := Rect2(112.0, taille.y * 0.68, taille.x - 224.0, 150.0)
	_dessiner_carte_menu(rect, Palette.MOUSSE_MAGIQUE)
	draw_string(police, rect.position + Vector2(0.0, 58.0), "%d / %d MAÎTRISES" % [acquis, ArbreCompetences.NOEUDS.size()],
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 34, Palette.TEXTE)
	draw_string(police, rect.position + Vector2(0.0, 108.0), "GOUTTES  %s" % ReglagesJoueur.gouttes_affichees(),
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 27, Palette.ESSENCE)

func _dessiner_page_histoire(police: Font, taille: Vector2) -> void:
	var chapitre := Chapitres.par_index(ReglagesJoueur.chapitre_choisi)
	var progression := ReglagesJoueur.meilleure_du_chapitre(ReglagesJoueur.chapitre_choisi)
	var rect := Rect2(74.0, taille.y * 0.65, taille.x - 148.0, 210.0)
	_dessiner_carte_menu(rect, chapitre["teinte"])
	draw_string(police, rect.position + Vector2(26.0, 54.0), chapitre["nom"], HORIZONTAL_ALIGNMENT_LEFT,
		rect.size.x - 52.0, 31, Palette.TEXTE)
	draw_multiline_string(police, rect.position + Vector2(26.0, 98.0), chapitre["sous_titre"],
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 52.0, 24, 2, Palette.TEXTE_ATTENUE)
	draw_string(police, rect.position + Vector2(26.0, 174.0), "PAGE %d / %d" % [progression, chapitre["salles"]],
		HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 52.0, 28, Palette.OR)

func _dessiner_page_pantheon(police: Font, taille: Vector2) -> void:
	var rect := Rect2(118.0, taille.y * 0.67, taille.x - 236.0, 170.0)
	_dessiner_carte_menu(rect, Palette.OR)
	draw_string(police, rect.position + Vector2(0.0, 58.0), "%d VICTOIRES" % ReglagesJoueur.victoires,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 34, Palette.TEXTE)
	draw_string(police, rect.position + Vector2(0.0, 110.0), "%d GRIMOIRES OUVERTS" % _chapitres_ouverts(),
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 26, Palette.TEXTE_ATTENUE)

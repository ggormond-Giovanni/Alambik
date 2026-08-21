extends Control

const ARBRE := preload("res://ui/arbre_competences.tscn")
const MENU_SORTS := preload("res://ui/sorts.tscn")
const SELECTION_GRIMOIRE := preload("res://ui/selection_grimoire.tscn")
const REGLAGES := preload("res://ui/reglages.tscn")
const EQUIPEMENT := preload("res://ui/equipement.tscn")
const TRANSITION := preload("res://ui/transition_grimoire.tscn")
const HEROS_MENU := preload("res://assets/visual/heros_menu_premium.png")
const PAGES := ["equipement", "aventure", "maitrises", "sorts"]

var _anim := 0.0
var _conteneur_pages: Control
var _page_actuelle: Control
var _navigation: Control
var _superposition: Control
var _onglets: Array[Button] = []
var _page := 1
var _doigt_swipe := -1
var _depart_swipe := Vector2.ZERO
var _lancement := false

func _ready() -> void:
	if OS.get_name() == "Android":
		get_tree().set_auto_accept_quit(false)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Sons.musique_menu()
	_construire_structure()
	_afficher_page(1, false)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--page-menu="):
			var index := PAGES.find(argument.trim_prefix("--page-menu="))
			if index >= 0:
				_afficher_page(index, false)
	if "--ouvrir-reglages" in OS.get_cmdline_user_args():
		call_deferred("_ouvrir_reglages")
	Capture.programmer(self)

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

	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	marge.offset_left = 18.0
	marge.offset_right = -18.0
	marge.offset_top = -174.0 - Ecran.marge_basse()
	marge.offset_bottom = -12.0 - Ecran.marge_basse()
	marge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_navigation.add_child(marge)

	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, true))
	marge.add_child(panneau)

	var barre := HBoxContainer.new()
	barre.add_theme_constant_override("separation", 8)
	panneau.add_child(barre)
	var donnees := [
		["ÉQUIPEMENT", 2], ["AVENTURE", 0], ["MAÎTRISES", 3], ["SORTS", 4],
	]
	for index in donnees.size():
		var bouton := Button.new()
		bouton.text = str(donnees[index][0])
		bouton.custom_minimum_size = Vector2(0.0, 112.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.mouse_filter = Control.MOUSE_FILTER_STOP
		bouton.pressed.connect(func() -> void: _afficher_page(index))
		barre.add_child(bouton)
		_onglets.append(bouton)
	_rafraichir_navigation()

func _rafraichir_navigation() -> void:
	for index in _onglets.size():
		var actif := index == _page
		InterfaceMobile.styliser_bouton(_onglets[index], Palette.OR if actif else Palette.ESSENCE, actif)
		_onglets[index].add_theme_font_size_override("font_size", 20 if not actif else 22)

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
	var nouvelle := _creer_page(index)
	_page_actuelle = nouvelle
	_conteneur_pages.add_child(nouvelle)
	move_child(_navigation, get_child_count() - 1)
	_rafraichir_navigation()
	queue_redraw()
	if ancienne == null:
		StyleInterface.animer_entree(nouvelle, 18.0)
		return
	Sons.jouer("choix", -17.0, 1.05)
	if not anime:
		ancienne.queue_free()
		return
	var direction := 1.0 if index > ancienne_page else -1.0
	var distance := 34.0 if ReglagesJoueur.effets_reduits else 150.0
	nouvelle.position.x = distance * direction
	nouvelle.modulate.a = 0.0
	var sortie := ancienne.create_tween().set_parallel(true)
	sortie.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	sortie.tween_property(ancienne, "position:x", -distance * direction, 0.20)
	sortie.tween_property(ancienne, "modulate:a", 0.0, 0.15)
	var entree := nouvelle.create_tween().set_parallel(true)
	entree.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entree.tween_property(nouvelle, "position:x", 0.0, 0.30)
	entree.tween_property(nouvelle, "modulate:a", 1.0, 0.22)
	await sortie.finished
	if is_instance_valid(ancienne):
		ancienne.queue_free()

func _creer_aventure() -> Control:
	var page := Control.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)

	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	InterfaceMobile.appliquer_marges(marge, 184.0, true)
	page.add_child(marge)

	var defilement := ScrollContainer.new()
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marge.add_child(defilement)

	var colonne := VBoxContainer.new()
	colonne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonne.add_theme_constant_override("separation", 18)
	defilement.add_child(colonne)

	colonne.add_child(_creer_entete_aventure())

	var vitrine := PanelContainer.new()
	vitrine.custom_minimum_size.y = 450.0
	vitrine.add_theme_stylebox_override("panel", InterfaceMobile.panneau_leger(Palette.ESSENCE))
	colonne.add_child(vitrine)
	var heros := TextureRect.new()
	heros.texture = HEROS_MENU
	heros.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heros.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heros.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vitrine.add_child(heros)

	var actions := GridContainer.new()
	actions.columns = 2
	actions.add_theme_constant_override("h_separation", 14)
	actions.add_theme_constant_override("v_separation", 14)
	colonne.add_child(actions)
	_ajouter_action(actions, "CAMPAGNE", "Choisir un chapitre", Palette.OR, _ouvrir_campagne)
	_ajouter_action(actions, "MINE", "Horde et ressources", Palette.ESSENCE,
		func() -> void: _lancer_mode("mine", {"nom": "Mine"}))
	_ajouter_action(actions, "ÉPREUVE", "Défi alchimique", Retro16.VIOLET,
		func() -> void: _lancer_mode("epreuve_sorts", {"nom": "Défi alchimique"}))
	_ajouter_action(actions, "LIVRE VIVANT", "Chapitres connus", Retro16.VERT, _ouvrir_livre)

	colonne.add_child(_creer_carte_chapitre())
	return page

func _creer_entete_aventure() -> Control:
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, true))
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 16)
	panneau.add_child(ligne)

	var profil := VBoxContainer.new()
	profil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var titre := InterfaceMobile.styliser_label(Label.new(), 34, Palette.TEXTE)
	titre.text = ReglagesJoueur.titre_compte()
	profil.add_child(titre)
	var niveau := InterfaceMobile.styliser_label(Label.new(), 22, Palette.OR)
	niveau.text = "NIVEAU %d" % ReglagesJoueur.niveau_compte_effectif()
	profil.add_child(niveau)
	ligne.add_child(profil)

	var essence := InterfaceMobile.styliser_label(Label.new(), 25, Palette.ESSENCE, true)
	essence.text = "%s\nGOUTTES" % ReglagesJoueur.gouttes_affichees()
	essence.custom_minimum_size.x = 150.0
	ligne.add_child(essence)

	var reglages := Button.new()
	reglages.text = "RÉGLAGES"
	reglages.custom_minimum_size = Vector2(160.0, 92.0)
	InterfaceMobile.styliser_bouton(reglages, Palette.ESSENCE, false)
	reglages.pressed.connect(_ouvrir_reglages)
	ligne.add_child(reglages)
	return panneau

func _ajouter_action(parent: GridContainer, titre: String, sous_titre: String,
		accent: Color, action: Callable) -> void:
	var bouton := Button.new()
	bouton.text = "%s\n%s" % [titre, sous_titre]
	bouton.custom_minimum_size = Vector2(0.0, 124.0)
	bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bouton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	InterfaceMobile.styliser_bouton(bouton, accent, false)
	bouton.add_theme_font_size_override("font_size", 23)
	bouton.pressed.connect(action)
	parent.add_child(bouton)

func _creer_carte_chapitre() -> Control:
	var chapitre := Chapitres.par_index(ReglagesJoueur.chapitre_choisi)
	var monde: Dictionary = Chapitres.MONDES[int(chapitre["monde"])]
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Color(chapitre["teinte"]), true))
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 10)
	panneau.add_child(colonne)

	var surtitre := InterfaceMobile.styliser_label(Label.new(), 20, Palette.OR, true)
	surtitre.text = "PROCHAINE DESCENTE"
	colonne.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 30, Palette.TEXTE, true)
	titre.text = "MONDE %s — %s  ·  CHAPITRE %d" % [monde["numero"],
		str(monde["nom"]).to_upper(), int(chapitre["chapitre_monde"])]
	titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(titre)
	var meilleur := ReglagesJoueur.meilleure_du_chapitre(ReglagesJoueur.chapitre_choisi)
	var progression := InterfaceMobile.styliser_label(Label.new(), 22, Palette.TEXTE_ATTENUE, true)
	progression.text = "ÉTAGE MAX %d / %d" % [meilleur, int(chapitre["salles"])]
	colonne.add_child(progression)

	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 12)
	colonne.add_child(boutons)
	var changer := Button.new()
	changer.text = "CHANGER"
	changer.custom_minimum_size.y = 102.0
	changer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	InterfaceMobile.styliser_bouton(changer, Palette.ESSENCE, false)
	changer.pressed.connect(_ouvrir_campagne)
	boutons.add_child(changer)
	var jouer := Button.new()
	jouer.text = "JOUER"
	jouer.custom_minimum_size.y = 102.0
	jouer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	InterfaceMobile.styliser_bouton(jouer, Palette.OR, true)
	jouer.pressed.connect(_jouer_immediatement)
	boutons.add_child(jouer)
	return panneau

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
	move_child(transition, get_child_count() - 1)
	transition.terminee.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/run.tscn"))

func _ouvrir_campagne() -> void:
	var selection := SELECTION_GRIMOIRE.instantiate()
	selection.selection_seulement = true
	_ouvrir_superposition(selection)

func _ouvrir_livre() -> void:
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
	if _superposition != null or _lancement:
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
			if is_instance_valid(cible):
				cible.queue_free()
			if _superposition == cible:
				_superposition = null)
	elif _page != 1:
		_afficher_page(1)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	InterfaceMobile.dessiner_fond(self, get_viewport_rect().size, _page == 1,
		Palette.OR if _page == 1 else Palette.ESSENCE, _anim)

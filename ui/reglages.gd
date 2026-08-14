extends Control

signal ferme

const FOND := preload("res://assets/visual/reglages_premium.png")
const HAUT_FIXE := 1450.0
const BAS_FIXE := 470.0
const ONGLETS := ["audio", "visuel", "accessibilite", "developpement"]
const RECTS_ONGLETS := [
	Rect2(42, 395, 278, 190), Rect2(42, 610, 278, 190),
	Rect2(42, 825, 278, 190), Rect2(42, 1040, 278, 190),
]
const Y_LIGNES := [455.0, 635.0, 815.0, 995.0, 1175.0]

var _onglet := "audio"
var _contenu: Control
var _bouton_reset: Button
var _confirmation_reset := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_zones_fixes()
	var onglet_initial := "audio"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--onglet-reglages="):
			var demande := argument.trim_prefix("--onglet-reglages=")
			if demande in ONGLETS:
				onglet_initial = demande
	_afficher_onglet(onglet_initial)
	resized.connect(_replacer_zones)
	_replacer_zones()
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire_zones_fixes() -> void:
	_zone(Rect2(922, 30, 120, 125), _fermer)
	for index in ONGLETS.size():
		_zone(RECTS_ONGLETS[index], func() -> void: _afficher_onglet(ONGLETS[index]))
	_bouton_reset = _zone(Rect2(145, 1510, 790, 145), _sur_reset)
	_zone(Rect2(220, 1685, 640, 185), _fermer)

func _zone(reference: Rect2, action: Callable) -> Button:
	var bouton := StyleInterface.zone_tactile(action)
	bouton.set_meta("reference", reference)
	add_child(bouton)
	return bouton

func _replacer_zones() -> void:
	var sx := size.x / 1080.0
	for enfant in get_children():
		if enfant is Button and enfant.has_meta("reference"):
			var r: Rect2 = enfant.get_meta("reference")
			var adapte := FondAdaptatif.rect(size, FOND, r, HAUT_FIXE, BAS_FIXE)
			enfant.position = adapte.position
			enfant.size = adapte.size
	if _contenu != null:
		_contenu.scale = Vector2.ONE * sx

func _fermer() -> void:
	Sons.jouer("choix", -14.0)
	StyleInterface.sortir_puis(self, func() -> void: ferme.emit())

func _afficher_onglet(id: String) -> void:
	if id == _onglet and _contenu != null:
		return
	_onglet = id
	if _contenu != null:
		_contenu.queue_free()
	_contenu = Control.new()
	_contenu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_contenu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenu.scale = Vector2.ONE * (size.x / 1080.0)
	add_child(_contenu)
	move_child(_contenu, get_child_count() - 1)
	match id:
		"audio": _construire_audio()
		"visuel": _construire_visuel()
		"accessibilite": _construire_accessibilite()
		"developpement": _construire_developpement()
	StyleInterface.animer_entree(_contenu, 14.0)
	Sons.jouer("choix", -18.0)
	queue_redraw()

func _construire_audio() -> void:
	_ajouter_volume(0, "VOLUME DE LA MUSIQUE", ReglagesJoueur.volume_musique,
		func(v: float) -> void: ReglagesJoueur.definir_reglages_audio(v, ReglagesJoueur.volume_effets))
	_ajouter_piste(1)
	_ajouter_volume(2, "VOLUME DES EFFETS", ReglagesJoueur.volume_effets,
		func(v: float) -> void: ReglagesJoueur.definir_reglages_audio(ReglagesJoueur.volume_musique, v))
	_ajouter_information(3, "MIXAGE DU JEU", "Musique d'ambiance, combat et boss partagent le même volume.", Palette.OR)
	_ajouter_information(4, "APPLICATION IMMÉDIATE", "Chaque changement est entendu et sauvegardé sans relancer le jeu.", Palette.ESSENCE)

func _construire_visuel() -> void:
	_ajouter_option(0, "SECOUSSES D’ÉCRAN", ReglagesJoueur.secousses_ecran,
		func(v: bool) -> void: ReglagesJoueur.definir_accessibilite(v, ReglagesJoueur.effets_reduits))
	_ajouter_option(1, "EFFETS VISUELS COMPLETS", not ReglagesJoueur.effets_reduits,
		func(v: bool) -> void: ReglagesJoueur.definir_accessibilite(ReglagesJoueur.secousses_ecran, not v))
	_ajouter_information(2, "PIXEL ART NET", "Contours précis conçus pour rester lisibles en combat.", Palette.OR)
	_ajouter_information(3, "IMPACTS ET PARTICULES", "Le mode complet renforce halos, trails, flashes et déformations.", Palette.ESSENCE)
	_ajouter_information(4, "TRANSITIONS", "Les pages conservent glissements, fondus et sceaux animés.", Palette.OR)

func _construire_accessibilite() -> void:
	_ajouter_option(0, "ANIMATIONS ET FLASHES RÉDUITS", ReglagesJoueur.effets_reduits,
		func(v: bool) -> void: ReglagesJoueur.definir_accessibilite(ReglagesJoueur.secousses_ecran, v))
	_ajouter_raccourci_sort(1)
	_ajouter_information(2, "ICÔNES DE COMBAT", "Le Sort et l'Ultime gardent toujours leur icône sur le côté droit.", Palette.OR)
	_ajouter_information(3, "JOYSTICK FLOTTANT", "Il apparaît sous le pouce dans la moitié basse de l'écran.", Palette.ESSENCE)
	_ajouter_information(4, "GRANDES ZONES TACTILES", "Les actions essentielles restent confortables sur téléphone.", Palette.OR)

func _ajouter_raccourci_sort(index: int) -> void:
	var y: float = Y_LIGNES[index]
	var etiquette := _etiquette("RACCOURCI DU SORT ACTIF", Vector2(405, y - 20), Vector2(560, 44), 31)
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var selecteur := OptionButton.new()
	selecteur.position = Vector2(405, y + 18)
	selecteur.size = Vector2(560, 72)
	selecteur.mouse_filter = Control.MOUSE_FILTER_STOP
	StyleInterface.styliser_selecteur(selecteur, Palette.ESSENCE)
	selecteur.add_theme_font_size_override("font_size", 29)
	for i in RaccourciTactile.MODES.size():
		var mode: String = RaccourciTactile.MODES[i]
		selecteur.add_item(RaccourciTactile.nom_mode(mode))
		selecteur.set_item_metadata(i, mode)
		if mode == ReglagesJoueur.raccourci_sort:
			selecteur.selected = i
	selecteur.item_selected.connect(func(i: int) -> void:
		ReglagesJoueur.definir_raccourci_sort(str(selecteur.get_item_metadata(i))))
	_contenu.add_child(selecteur)

func _construire_developpement() -> void:
	_ajouter_option(0, "MODE DEV — TOUT DÉBLOQUER", ReglagesJoueur.mode_dev,
		func(v: bool) -> void: ReglagesJoueur.definir_mode_dev(v))
	_ajouter_information(1, "CONTENU DÉVERROUILLÉ", "Révèle les chapitres, objets, sorts et maîtrises pour les essais.", Palette.ESSENCE)
	_ajouter_information(2, "OUTIL DE TEST", "Permet de contrôler rapidement les écrans et les systèmes avancés.", Palette.OR)
	_ajouter_information(3, "SAUVEGARDE LOCALE", "Les réglages restent enregistrés sur cet appareil.", Palette.ESSENCE)
	_ajouter_information(4, "ZONE DANGEREUSE", "La réinitialisation complète demande toujours une seconde confirmation.", Palette.DANGER)

func _ajouter_volume(index: int, titre: String, valeur: float, changement: Callable) -> void:
	var y: float = Y_LIGNES[index]
	var etiquette := _etiquette(titre, Vector2(405, y - 20), Vector2(430, 44), 31)
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var valeur_label := _etiquette("%d %%" % roundi(valeur * 100.0), Vector2(835, y - 20), Vector2(130, 44), 31)
	var curseur := HSlider.new()
	curseur.position = Vector2(405, y + 18)
	curseur.size = Vector2(560, 60)
	curseur.min_value = 0.0
	curseur.max_value = 1.0
	curseur.step = 0.05
	curseur.value = valeur
	curseur.mouse_filter = Control.MOUSE_FILTER_STOP
	StyleInterface.styliser_curseur(curseur, Palette.ESSENCE)
	curseur.value_changed.connect(func(v: float) -> void:
		valeur_label.text = "%d %%" % roundi(v * 100.0)
		changement.call(v))
	_contenu.add_child(curseur)

func _ajouter_piste(index: int) -> void:
	var y: float = Y_LIGNES[index]
	var etiquette := _etiquette("MUSIQUE DU COMBAT", Vector2(405, y - 20), Vector2(560, 44), 31)
	etiquette.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var selecteur := OptionButton.new()
	selecteur.position = Vector2(405, y + 18)
	selecteur.size = Vector2(560, 72)
	selecteur.mouse_filter = Control.MOUSE_FILTER_STOP
	StyleInterface.styliser_selecteur(selecteur, Palette.OR)
	selecteur.add_theme_font_size_override("font_size", 31)
	var pistes := Sons.pistes_disponibles()
	for i in pistes.size():
		var piste: Dictionary = pistes[i]
		selecteur.add_item(str(piste["nom"]))
		selecteur.set_item_metadata(i, str(piste["id"]))
		if str(piste["id"]) == ReglagesJoueur.piste_musique:
			selecteur.selected = i
	selecteur.item_selected.connect(func(i: int) -> void:
		ReglagesJoueur.definir_piste_musique(str(selecteur.get_item_metadata(i))))
	_contenu.add_child(selecteur)

func _ajouter_option(index: int, titre: String, valeur: bool, changement: Callable) -> void:
	var y: float = Y_LIGNES[index]
	var bouton := CheckButton.new()
	bouton.position = Vector2(395, y - 58)
	bouton.size = Vector2(575, 128)
	bouton.text = "%s\n%s" % [titre, "ACTIVÉ" if valeur else "DÉSACTIVÉ"]
	bouton.button_pressed = valeur
	bouton.mouse_filter = Control.MOUSE_FILTER_STOP
	bouton.add_theme_font_size_override("font_size", 31)
	bouton.add_theme_color_override("font_color", Palette.TEXTE)
	bouton.add_theme_color_override("font_pressed_color", Color.WHITE)
	bouton.add_theme_color_override("font_hover_color", Color.WHITE)
	var vide := StyleBoxEmpty.new()
	for etat in ["normal", "hover", "pressed", "focus"]:
		bouton.add_theme_stylebox_override(etat, vide)
	bouton.toggled.connect(func(v: bool) -> void:
		bouton.text = "%s\n%s" % [titre, "ACTIVÉ" if v else "DÉSACTIVÉ"]
		changement.call(v))
	_contenu.add_child(bouton)

func _ajouter_information(index: int, titre: String, texte: String, accent: Color) -> void:
	var y: float = Y_LIGNES[index]
	var titre_label := _etiquette(titre, Vector2(405, y - 28), Vector2(530, 40), 30)
	titre_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	titre_label.add_theme_color_override("font_color", accent.lightened(0.18))
	var label := _etiquette(texte, Vector2(405, y + 14), Vector2(530, 62), 25)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)

func _etiquette(texte: String, position: Vector2, taille: Vector2, police: int) -> Label:
	var label := Label.new()
	label.text = texte
	label.position = position
	label.size = taille
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", police)
	label.add_theme_color_override("font_color", Palette.TEXTE)
	_contenu.add_child(label)
	return label

func _sur_reset() -> void:
	if not _confirmation_reset:
		_confirmation_reset = true
		_ajouter_alerte_reset("TOUCHER À NOUVEAU POUR CONFIRMER")
		_attendre_confirmation_reset()
		return
	_confirmation_reset = false
	ReglagesJoueur.reinitialiser_progression()
	_bouton_reset.disabled = true
	_ajouter_alerte_reset("PROGRESSION RÉINITIALISÉE")
	Sons.jouer("choix", -10.0, 0.75)

func _ajouter_alerte_reset(texte: String) -> void:
	if _contenu == null:
		return
	for enfant in _contenu.get_children():
		if enfant.name == "AlerteReset":
			enfant.queue_free()
	var label := _etiquette(texte, Vector2(260, 1452), Vector2(560, 46), 20)
	label.name = "AlerteReset"
	label.add_theme_color_override("font_color", Palette.DANGER.lightened(0.25))

func _attendre_confirmation_reset() -> void:
	await get_tree().create_timer(4.0, true).timeout
	if not is_inside_tree() or not _confirmation_reset:
		return
	_confirmation_reset = false
	if _contenu != null:
		for enfant in _contenu.get_children():
			if enfant.name == "AlerteReset":
				enfant.queue_free()

func _draw() -> void:
	FondAdaptatif.dessiner_premium(self, FOND, size, HAUT_FIXE, BAS_FIXE)
	var sx := size.x / 1080.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * sx)
	var index := ONGLETS.find(_onglet)
	for onglet_index in ONGLETS.size():
		var r: Rect2 = RECTS_ONGLETS[onglet_index].grow(-9.0)
		if onglet_index == index:
			draw_rect(r, Color(Palette.ESSENCE, 0.20))
			draw_rect(r.grow(-3.0), Color(Palette.ESSENCE, 0.72), false, 4.0)
		else:
			draw_rect(r, Color(0.004, 0.010, 0.024, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

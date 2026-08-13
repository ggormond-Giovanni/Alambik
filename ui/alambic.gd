extends Control

# L'Alambic genere un Element et l'attache a un Augment existant. La fusion
# ajoute une transformation : elle ne retire ni ne remplace jamais l'original.

signal termine

var _liste: VBoxContainer
var _cartes: Array[CarteReactif] = []
var _selection := ""
var _element := ""
var _bouton_fusionner: Button
var _apercu: Label
var _anim := 0.0
var _fusion_en_cours := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_element = Jeu.tirer_element_alambic()
	_construire()
	StyleInterface.animer_entree(self)
	if Jeu.mode_auto:
		_jouer_automatiquement()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 44)
	marge.add_theme_constant_override("margin_right", 44)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 430)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 30)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 16)
	marge.add_child(colonne)

	var defilement := ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(defilement)

	_liste = VBoxContainer.new()
	_liste.add_theme_constant_override("separation", 14)
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defilement.add_child(_liste)

	_apercu = Label.new()
	_apercu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apercu.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apercu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apercu.add_theme_font_size_override("font_size", 24)
	_apercu.custom_minimum_size = Vector2(0, 150)
	colonne.add_child(_apercu)

	_bouton_fusionner = Button.new()
	_bouton_fusionner.text = "INFUSER L'AUGMENT"
	_bouton_fusionner.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	_bouton_fusionner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bouton_fusionner.add_theme_font_size_override("font_size", 30)
	_bouton_fusionner.pressed.connect(_sur_fusionner)
	StyleInterface.styliser_bouton(_bouton_fusionner, _teinte_element())
	colonne.add_child(_bouton_fusionner)
	_construire_cartes()

func _construire_cartes() -> void:
	var deja_vus: Array[String] = []
	for id in Jeu.inventaire:
		if id in deja_vus or id not in CatalogueReactifs.ids() or Jeu.augment_deja_fusionne(id):
			continue
		deja_vus.append(id)
		var reactif := CatalogueReactifs.par_id(id)
		var carte := CarteReactif.new()
		carte.configurer(reactif)
		carte.custom_minimum_size = Vector2(0, 150)
		carte.selectionnee = id == _selection
		carte.choisie.connect(_sur_choix)
		_liste.add_child(carte)
		_cartes.append(carte)
	_rafraichir()
	call_deferred("_animer_cartes")

func _animer_cartes() -> void:
	if is_instance_valid(_liste):
		StyleInterface.animer_liste(_liste, 0.045)

func _sur_choix(id: String) -> void:
	if _fusion_en_cours:
		return
	_selection = "" if _selection == id else id
	_rafraichir()

func _rafraichir() -> void:
	for carte in _cartes:
		if is_instance_valid(carte):
			carte.selectionnee = carte.reactif.id == _selection
			carte.queue_redraw()
	_bouton_fusionner.disabled = _selection.is_empty() or _element.is_empty()
	var donnees := CatalogueElements.par_id(_element)
	if donnees.is_empty():
		_apercu.text = "L'Alambic reste silencieux."
	elif _cartes.is_empty():
		_apercu.text = "%s\n\nAucun Augment non fusionné n'est disponible." % donnees["nom"]
	elif _selection.is_empty():
		_apercu.text = "%s\n\nChoisissez l'Augment à transformer." % donnees["nom"]
	else:
		var augment := CatalogueReactifs.par_id(_selection)
		var fusion := CatalogueElements.creer_fusion(_element, _selection)
		_apercu.text = "%s + %s\n%s" % [augment.nom, donnees["nom"], fusion.description]
	_apercu.add_theme_color_override("font_color", _teinte_element())

func _sur_fusionner() -> void:
	if _fusion_en_cours or _selection.is_empty():
		return
	_fusion_en_cours = true
	if not Jeu.ajouter_fusion_elementaire(_element, _selection):
		_fusion_en_cours = false
		return
	Sons.jouer("fusion", -8.0)
	var fusion := CatalogueElements.creer_fusion(_element, _selection)
	_apercu.text = "%s !\n%s" % [fusion.nom, fusion.description]
	await get_tree().create_timer(0.85).timeout
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _jouer_automatiquement() -> void:
	await get_tree().create_timer(0.2).timeout
	if _cartes.is_empty():
		StyleInterface.sortir_puis(self, func() -> void: termine.emit())
		return
	_selection = _cartes[0].reactif.id
	_rafraichir()
	_sur_fusionner()

func _teinte_element() -> Color:
	var donnees := CatalogueElements.par_id(_element)
	return donnees.get("teinte", Palette.ESSENCE)

func _draw() -> void:
	var police := ThemeDB.fallback_font
	var teinte := _teinte_element()
	StyleInterface.dessiner_fond(self, size, teinte, _anim, 0.98)
	Dessin.halo(self, Vector2(size.x / 2.0, 220.0), 420.0, Color(teinte, 0.24), 7)
	var haut := Ecran.marge_haute() + 80.0
	draw_string(police, Vector2(52.0, haut - 36.0), "ALAMBIC ÉLÉMENTAIRE", HORIZONTAL_ALIGNMENT_LEFT,
		size.x - 104.0, 22, teinte)
	var nom_element := str(CatalogueElements.par_id(_element).get("nom", "Élément inconnu"))
	draw_string(police, Vector2(52.0, haut + 18.0), nom_element, HORIZONTAL_ALIGNMENT_LEFT,
		size.x - 104.0, 52, Palette.TEXTE)
	draw_string(police, Vector2(52.0, haut + 58.0), "Un Augment entre. Il ressort transformé — et reste actif.  •  PV +%d %%" % roundi(Reglages.SOIN_ALAMBIC * 100.0),
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 104.0, 24, Palette.TEXTE_ATTENUE)
	_dessiner_alambic(Vector2(size.x / 2.0, haut + 210.0), teinte)

func _dessiner_alambic(centre: Vector2, teinte: Color) -> void:
	var ballon := centre + Vector2(0, 40.0)
	Dessin.halo(self, ballon, 170.0, Color(teinte, 0.62), 5)
	var verre := Color(0.72, 0.80, 0.92, 0.22)
	draw_circle(ballon, 92.0, verre)
	draw_arc(ballon, 92.0, 0.0, TAU, 40, Color(0.85, 0.92, 1.0, 0.6), 3.5, true)
	var liquide := PackedVector2Array()
	var haut_liquide := ballon.y - 34.0
	for i in 33:
		var t := float(i) / 32.0
		liquide.append(Vector2(lerpf(ballon.x - 86.0, ballon.x + 86.0, t),
			haut_liquide + sin(t * 9.0 + _anim * 3.0) * 5.0))
	for i in range(32, -1, -1):
		var t := float(i) / 32.0
		liquide.append(Vector2(lerpf(ballon.x - 86.0, ballon.x + 86.0, t), ballon.y + 88.0))
	draw_colored_polygon(liquide, Color(teinte, 0.78))
	draw_rect(Rect2(centre.x - 22.0, centre.y - 92.0, 44.0, 96.0), verre)
	draw_rect(Rect2(centre.x - 30.0, centre.y - 104.0, 60.0, 18.0), Color(0.85, 0.92, 1.0, 0.45))
	draw_line(Vector2(centre.x + 20.0, centre.y - 56.0), Vector2(centre.x + 132.0, centre.y - 8.0),
		Color(0.85, 0.92, 1.0, 0.5), 7.0, true)
	for i in 6:
		var phase := fmod(_anim * 0.6 + float(i) * 0.17, 1.0)
		var p := Vector2(ballon.x + sin(float(i) * 2.4 + _anim) * 46.0,
			ballon.y + 78.0 - 150.0 * phase)
		draw_circle(p, 5.0 + 4.0 * (1.0 - phase), Color(1, 1, 1, 0.35 * (1.0 - phase)))

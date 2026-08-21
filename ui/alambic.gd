extends Control

# L'Alambic genere un Element et l'attache a une Amélioration existante. Le
# décor, les cartes et les contrôles sont trois couches indépendantes.
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
	Capture.programmer(self)
	if Jeu.mode_auto:
		_jouer_automatiquement()

func _construire() -> void:
	var teinte := _teinte_element()
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	InterfaceMobile.appliquer_marges(marge, 0.0, true)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)

	var entete := PanelContainer.new()
	entete.add_theme_stylebox_override("panel", InterfaceMobile.panneau(teinte, true))
	colonne.add_child(entete)
	var entete_colonne := VBoxContainer.new()
	entete_colonne.add_theme_constant_override("separation", 6)
	entete.add_child(entete_colonne)
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 19, Palette.OR, true)
	surtitre.text = "TRANSFORMATION ÉLÉMENTAIRE"
	entete_colonne.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 36, Palette.TEXTE, true)
	titre.text = "ALAMBIC"
	entete_colonne.add_child(titre)
	var element := InterfaceMobile.styliser_label(Label.new(), 28, teinte, true)
	element.text = str(CatalogueElements.par_id(_element).get("nom", "ÉLÉMENT INCONNU")).to_upper()
	entete_colonne.add_child(element)

	var illustration := Control.new()
	illustration.custom_minimum_size.y = 310.0
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illustration.draw.connect(func() -> void: _dessiner_alambic(illustration, illustration.size * Vector2(0.5, 0.46), teinte))
	colonne.add_child(illustration)

	var instruction := InterfaceMobile.styliser_label(Label.new(), 21, Palette.TEXTE_ATTENUE, true)
	instruction.text = "Choisissez une Amélioration à infuser  ·  Soin +%d %%" % roundi(Reglages.SOIN_ALAMBIC * 100.0)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.custom_minimum_size.y = 48.0
	colonne.add_child(instruction)

	var defilement := ScrollContainer.new()
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(defilement)
	_liste = VBoxContainer.new()
	_liste.add_theme_constant_override("separation", 12)
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defilement.add_child(_liste)

	var apercu_panneau := PanelContainer.new()
	apercu_panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau_leger(teinte))
	colonne.add_child(apercu_panneau)
	_apercu = InterfaceMobile.styliser_label(Label.new(), 23, teinte, true)
	_apercu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apercu.custom_minimum_size.y = 108.0
	apercu_panneau.add_child(_apercu)

	_bouton_fusionner = Button.new()
	_bouton_fusionner.text = "INFUSER L'AMÉLIORATION"
	_bouton_fusionner.custom_minimum_size.y = 106.0
	InterfaceMobile.styliser_bouton(_bouton_fusionner, teinte, true)
	_bouton_fusionner.pressed.connect(_sur_fusionner)
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
		carte.custom_minimum_size = Vector2(0.0, 152.0)
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
		_apercu.text = "%s\nAucune Amélioration non fusionnée n'est disponible." % donnees["nom"]
	elif _selection.is_empty():
		_apercu.text = "%s\nChoisissez l'Amélioration à transformer." % donnees["nom"]
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
	_bouton_fusionner.disabled = true
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

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	InterfaceMobile.dessiner_fond(self, size, false, _teinte_element(), _anim)

func _dessiner_alambic(canvas: Control, centre: Vector2, teinte: Color) -> void:
	var ballon := centre + Vector2(0.0, 38.0)
	Dessin.halo(canvas, ballon, 126.0, Color(teinte, 0.50), 5)
	canvas.draw_circle(ballon, 76.0, Color(0.72, 0.82, 0.96, 0.18))
	canvas.draw_arc(ballon, 76.0, 0.0, TAU, 36, Color(0.88, 0.94, 1.0, 0.68), 3.0, true)
	canvas.draw_circle(ballon + Vector2(0.0, 24.0), 60.0, Color(teinte, 0.70))
	canvas.draw_rect(Rect2(centre.x - 18.0, centre.y - 76.0, 36.0, 82.0), Color(0.80, 0.90, 1.0, 0.26))
	canvas.draw_rect(Rect2(centre.x - 25.0, centre.y - 86.0, 50.0, 14.0), Color(0.90, 0.95, 1.0, 0.52))
	canvas.draw_line(Vector2(centre.x + 16.0, centre.y - 45.0), Vector2(centre.x + 104.0, centre.y - 8.0),
		Color(0.88, 0.94, 1.0, 0.55), 6.0, true)
	for index in 5:
		var phase := fmod(_anim * 0.55 + float(index) * 0.19, 1.0)
		var p := Vector2(ballon.x + sin(float(index) * 2.2 + _anim) * 38.0,
			ballon.y + 56.0 - 118.0 * phase)
		canvas.draw_circle(p, 4.0 + 3.0 * (1.0 - phase), Color(1.0, 1.0, 1.0, 0.30 * (1.0 - phase)))

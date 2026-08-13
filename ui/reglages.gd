extends Control

signal ferme

var _bouton_reset: Button
var _confirmation_reset := false
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	StyleInterface.animer_entree(self, 12.0)
	Capture.programmer(self)

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 70)
	marge.add_theme_constant_override("margin_right", 70)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 230)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 90)
	add_child(marge)
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", StyleInterface.panneau(Color(0.035, 0.030, 0.060, 0.99), Color(Palette.ESSENCE, 0.5), 30, 9))
	marge.add_child(panneau)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 18)
	panneau.add_child(colonne)
	var titre := Label.new()
	titre.text = "RÉGLAGES"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Palette.TEXTE)
	colonne.add_child(titre)
	_ajouter_volume(colonne, "MUSIQUE", ReglagesJoueur.volume_musique, func(v: float) -> void:
		ReglagesJoueur.definir_reglages_audio(v, ReglagesJoueur.volume_effets))
	_ajouter_choix_musique(colonne)
	_ajouter_volume(colonne, "EFFETS SONORES", ReglagesJoueur.volume_effets, func(v: float) -> void:
		ReglagesJoueur.definir_reglages_audio(ReglagesJoueur.volume_musique, v))
	_ajouter_option(colonne, "SECOUSSES D’ÉCRAN", ReglagesJoueur.secousses_ecran, func(v: bool) -> void:
		ReglagesJoueur.definir_accessibilite(v, ReglagesJoueur.effets_reduits))
	_ajouter_option(colonne, "EFFETS VISUELS RÉDUITS", ReglagesJoueur.effets_reduits, func(v: bool) -> void:
		ReglagesJoueur.definir_accessibilite(ReglagesJoueur.secousses_ecran, v))
	_ajouter_option(colonne, "MODE DEV — TOUT DÉBLOQUER", ReglagesJoueur.mode_dev, func(v: bool) -> void:
		ReglagesJoueur.definir_mode_dev(v))
	_bouton_reset = Button.new()
	_bouton_reset.text = "RÉINITIALISER LA PROGRESSION"
	_bouton_reset.custom_minimum_size = Vector2(0, 76)
	_bouton_reset.add_theme_font_size_override("font_size", 22)
	StyleInterface.styliser_bouton(_bouton_reset, Palette.DANGER, true)
	_bouton_reset.pressed.connect(_sur_reset)
	colonne.add_child(_bouton_reset)
	var aide := Label.new()
	aide.text = "Les changements sont sauvegardés automatiquement."
	aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aide.add_theme_font_size_override("font_size", 22)
	aide.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	colonne.add_child(aide)
	var retour := Button.new()
	retour.text = "RETOUR"
	retour.custom_minimum_size = Vector2(0, 112)
	retour.add_theme_font_size_override("font_size", 32)
	StyleInterface.styliser_bouton(retour, Palette.ESSENCE)
	retour.pressed.connect(func() -> void:
		Sons.jouer("choix", -14.0)
		StyleInterface.sortir_puis(self, func() -> void: ferme.emit()))
	colonne.add_child(retour)

func _ajouter_volume(parent: VBoxContainer, titre: String, valeur: float, changement: Callable) -> void:
	var ligne := VBoxContainer.new()
	ligne.add_theme_constant_override("separation", 6)
	parent.add_child(ligne)
	var etiquette := Label.new()
	etiquette.text = "%s  %d%%" % [titre, roundi(valeur * 100.0)]
	etiquette.add_theme_font_size_override("font_size", 27)
	etiquette.add_theme_color_override("font_color", Palette.TEXTE)
	ligne.add_child(etiquette)
	var curseur := HSlider.new()
	curseur.min_value = 0.0
	curseur.max_value = 1.0
	curseur.step = 0.05
	curseur.value = valeur
	curseur.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	StyleInterface.styliser_curseur(curseur, Palette.ESSENCE)
	curseur.value_changed.connect(func(v: float) -> void:
		etiquette.text = "%s  %d%%" % [titre, roundi(v * 100.0)]
		changement.call(v))
	ligne.add_child(curseur)

func _ajouter_choix_musique(parent: VBoxContainer) -> void:
	var ligne := VBoxContainer.new()
	ligne.add_theme_constant_override("separation", 6)
	parent.add_child(ligne)
	var etiquette := Label.new()
	etiquette.text = "MUSIQUE DU COMBAT"
	etiquette.add_theme_font_size_override("font_size", 27)
	etiquette.add_theme_color_override("font_color", Palette.TEXTE)
	ligne.add_child(etiquette)
	var selecteur := OptionButton.new()
	selecteur.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	StyleInterface.styliser_selecteur(selecteur, Palette.OR)
	var pistes := Sons.pistes_disponibles()
	for index in pistes.size():
		var piste: Dictionary = pistes[index]
		selecteur.add_item(str(piste["nom"]))
		selecteur.set_item_metadata(index, str(piste["id"]))
		if str(piste["id"]) == ReglagesJoueur.piste_musique:
			selecteur.selected = index
	selecteur.item_selected.connect(func(index: int) -> void:
		ReglagesJoueur.definir_piste_musique(str(selecteur.get_item_metadata(index))))
	ligne.add_child(selecteur)

func _ajouter_option(parent: VBoxContainer, titre: String, valeur: bool, changement: Callable) -> void:
	var bouton := CheckButton.new()
	bouton.text = "%s  •  %s" % [titre, "ACTIVÉ" if valeur else "DÉSACTIVÉ"]
	bouton.button_pressed = valeur
	bouton.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	StyleInterface.styliser_option(bouton, Palette.ESSENCE)
	bouton.toggled.connect(func(v: bool) -> void:
		bouton.text = "%s  •  %s" % [titre, "ACTIVÉ" if v else "DÉSACTIVÉ"]
		changement.call(v))
	parent.add_child(bouton)

func _sur_reset() -> void:
	if not _confirmation_reset:
		_confirmation_reset = true
		_bouton_reset.text = "CONFIRMER — EFFACER TOUTE LA PROGRESSION"
		_attendre_confirmation_reset()
		return
	_confirmation_reset = false
	ReglagesJoueur.reinitialiser_progression()
	_bouton_reset.text = "PROGRESSION RÉINITIALISÉE"
	_bouton_reset.disabled = true
	Sons.jouer("choix", -10.0, 0.75)

func _attendre_confirmation_reset() -> void:
	await get_tree().create_timer(4.0, true).timeout
	if not is_inside_tree() or not _confirmation_reset:
		return
	_confirmation_reset = false
	_bouton_reset.text = "RÉINITIALISER LA PROGRESSION"

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	StyleInterface.dessiner_fond(self, size, Palette.ESSENCE, _anim, 0.98)

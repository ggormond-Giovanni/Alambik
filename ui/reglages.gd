extends Control

signal ferme

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	StyleInterface.animer_entree(self, 12.0)

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
	colonne.add_theme_constant_override("separation", 24)
	panneau.add_child(colonne)
	var titre := Label.new()
	titre.text = "RÉGLAGES"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Palette.TEXTE)
	colonne.add_child(titre)
	_ajouter_volume(colonne, "MUSIQUE", ReglagesJoueur.volume_musique, func(v: float) -> void:
		ReglagesJoueur.definir_reglages_audio(v, ReglagesJoueur.volume_effets))
	_ajouter_volume(colonne, "EFFETS SONORES", ReglagesJoueur.volume_effets, func(v: float) -> void:
		ReglagesJoueur.definir_reglages_audio(ReglagesJoueur.volume_musique, v))
	_ajouter_option(colonne, "SECOUSSES D’ÉCRAN", ReglagesJoueur.secousses_ecran, func(v: bool) -> void:
		ReglagesJoueur.definir_accessibilite(v, ReglagesJoueur.effets_reduits))
	_ajouter_option(colonne, "EFFETS VISUELS RÉDUITS", ReglagesJoueur.effets_reduits, func(v: bool) -> void:
		ReglagesJoueur.definir_accessibilite(ReglagesJoueur.secousses_ecran, v))
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
		ferme.emit())
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
	curseur.focus_mode = Control.FOCUS_NONE
	curseur.value_changed.connect(func(v: float) -> void:
		etiquette.text = "%s  %d%%" % [titre, roundi(v * 100.0)]
		changement.call(v))
	ligne.add_child(curseur)

func _ajouter_option(parent: VBoxContainer, titre: String, valeur: bool, changement: Callable) -> void:
	var bouton := CheckButton.new()
	bouton.text = titre
	bouton.button_pressed = valeur
	bouton.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	bouton.focus_mode = Control.FOCUS_NONE
	bouton.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	bouton.add_theme_font_size_override("font_size", 27)
	bouton.toggled.connect(func(v: bool) -> void: changement.call(v))
	parent.add_child(bouton)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.008, 0.008, 0.018, 0.94))

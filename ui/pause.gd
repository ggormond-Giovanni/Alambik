extends Control

signal termine

const REGLAGES := preload("res://ui/reglages.tscn")
const PANNEAU := preload("res://assets/visual/pause_premium.png")

var _zones: Dictionary = {}
var _inventaire: Control
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_zones()
	StyleInterface.animer_entree(self, 20.0)
	Capture.programmer(self)

func _construire_zones() -> void:
	_ajouter_zone("fermer", Rect2(770, 194, 112, 130), _reprendre)
	_ajouter_zone("reprendre", Rect2(250, 610, 585, 185), _reprendre)
	_ajouter_zone("ameliorations", Rect2(250, 817, 585, 177), _ouvrir_ameliorations)
	_ajouter_zone("reglages", Rect2(250, 1018, 585, 177), _ouvrir_reglages)
	_ajouter_zone("quitter", Rect2(250, 1218, 585, 182), _quitter_run)
	resized.connect(_replacer_zones)
	_replacer_zones()

func _ajouter_zone(id: String, reference: Rect2, action: Callable) -> void:
	var bouton := StyleInterface.zone_tactile(action)
	bouton.set_meta("reference", reference)
	add_child(bouton)
	_zones[id] = bouton

func _replacer_zones() -> void:
	var sx := size.x / 1080.0
	var hauteur := 1920.0 * sx
	var decalage_y := (size.y - hauteur) * 0.5
	for id in _zones:
		var bouton: Button = _zones[id]
		var r: Rect2 = bouton.get_meta("reference")
		bouton.position = Vector2(r.position.x * sx, decalage_y + r.position.y * sx)
		bouton.size = r.size * sx

func _reprendre() -> void:
	Sons.jouer("choix", -12.0)
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _ouvrir_reglages() -> void:
	Sons.jouer("choix", -12.0)
	var panneau := REGLAGES.instantiate()
	panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(panneau)
	panneau.ferme.connect(func() -> void: panneau.queue_free())

func _ouvrir_ameliorations() -> void:
	if _inventaire != null:
		return
	Sons.jouer("choix", -12.0)
	_inventaire = _VueAmeliorations.new()
	_inventaire.ferme.connect(func() -> void:
		_inventaire.queue_free()
		_inventaire = null)
	add_child(_inventaire)
	StyleInterface.animer_entree(_inventaire, 18.0)

func _quitter_run() -> void:
	Sons.jouer("choix", -10.0)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	# Voile seulement : le vrai combat reste visible derriere le calque extrait.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.004, 0.008, 0.018, 0.66))
	var sx := size.x / 1080.0
	var decalage_y := (size.y - 1920.0 * sx) * 0.5
	draw_texture_rect(PANNEAU, Rect2(0.0, decalage_y, size.x, 1920.0 * sx), false)
	var police := Polices.CORPS
	draw_string(police, Vector2(286.0 * sx, decalage_y + 516.0 * sx), Jeu.nom_run(),
		HORIZONTAL_ALIGNMENT_CENTER, 508.0 * sx, 29, Palette.TEXTE)
	draw_string(police, Vector2(286.0 * sx, decalage_y + 558.0 * sx), "Salle %d / %d" % [Jeu.salle_courante, Jeu.salles_du_chapitre()],
		HORIZONTAL_ALIGNMENT_CENTER, 508.0 * sx, 25, Palette.TEXTE_ATTENUE)
	draw_string(police, Vector2(230.0 * sx, decalage_y + 1625.0 * sx), "Niveau %d" % Jeu.niveau_run,
		HORIZONTAL_ALIGNMENT_CENTER, 220.0 * sx, 22, Palette.TEXTE)
	draw_string(police, Vector2(430.0 * sx, decalage_y + 1625.0 * sx), "%d Améliorations" % Jeu.inventaire.size(),
		HORIZONTAL_ALIGNMENT_CENTER, 250.0 * sx, 21, Palette.TEXTE)
	draw_string(police, Vector2(660.0 * sx, decalage_y + 1625.0 * sx), "%s Essence" % ReglagesJoueur.gouttes_affichees(),
		HORIZONTAL_ALIGNMENT_CENTER, 240.0 * sx, 21, Palette.TEXTE)

class _VueAmeliorations:
	extends Control
	signal ferme
	const FOND := preload("res://assets/visual/fond_interface_scriptorium.png")

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var marge := MarginContainer.new()
		marge.set_anchors_preset(Control.PRESET_FULL_RECT)
		marge.add_theme_constant_override("margin_left", 70)
		marge.add_theme_constant_override("margin_right", 70)
		marge.add_theme_constant_override("margin_top", 180)
		marge.add_theme_constant_override("margin_bottom", 160)
		add_child(marge)
		var panneau := PanelContainer.new()
		panneau.add_theme_stylebox_override("panel", StyleInterface.panneau(Color(0.008, 0.016, 0.038, 0.94), Color(Palette.OR, 0.84), 5, 12))
		marge.add_child(panneau)
		var colonne := VBoxContainer.new()
		colonne.add_theme_constant_override("separation", 18)
		panneau.add_child(colonne)
		var titre := Label.new()
		titre.text = "AMÉLIORATIONS DE LA RUN"
		titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		titre.add_theme_font_size_override("font_size", 38)
		titre.add_theme_color_override("font_color", Palette.TEXTE)
		colonne.add_child(titre)
		var defilement := ScrollContainer.new()
		defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
		colonne.add_child(defilement)
		var liste := VBoxContainer.new()
		liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		liste.add_theme_constant_override("separation", 12)
		defilement.add_child(liste)
		if Jeu.inventaire.is_empty():
			var vide := Label.new()
			vide.text = "Aucune amélioration pour le moment."
			vide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vide.add_theme_font_size_override("font_size", 27)
			liste.add_child(vide)
		else:
			for entree in Jeu.inventaire_groupe():
				var r := Jeu.reactif(str(entree[0]))
				if r == null: continue
				var carte := CarteReactif.new()
				carte.configurer(r)
				carte.custom_minimum_size.y = 172
				carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
				liste.add_child(carte)
		var fermer := Button.new()
		fermer.text = "RETOUR"
		fermer.custom_minimum_size.y = 112
		fermer.add_theme_font_size_override("font_size", 30)
		StyleInterface.styliser_bouton(fermer, Palette.OR, true)
		fermer.pressed.connect(func() -> void: ferme.emit())
		colonne.add_child(fermer)

	func _draw() -> void:
		FondAdaptatif.dessiner(self, FOND, size, 500.0, 420.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.002, 0.006, 0.015, 0.44))
		var cadre := Rect2(52.0, 156.0, size.x - 104.0, size.y - 284.0)
		draw_rect(cadre, Color(0.006, 0.012, 0.030, 0.42))
		draw_rect(cadre, Color(Palette.OR, 0.74), false, 3.0)
		draw_rect(cadre.grow(-10.0), Color(Palette.ESSENCE, 0.26), false, 2.0)

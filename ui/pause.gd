extends Control

signal termine

const REGLAGES := preload("res://ui/reglages.tscn")

var _inventaire: Control
var _anim := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_interface()
	StyleInterface.animer_entree(self, 20.0)
	Capture.programmer(self)

func _construire_interface() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 82)
	marge.add_theme_constant_override("margin_right", 82)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute() + 190.0))
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse() + 190.0))
	add_child(marge)

	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, true))
	marge.add_child(panneau)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 16)
	panneau.add_child(colonne)

	var surtitre := InterfaceMobile.styliser_label(Label.new(), 20, Palette.OR, true)
	surtitre.text = "LE GRIMOIRE EST SUSPENDU"
	colonne.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 44, Palette.TEXTE, true)
	titre.text = "PAUSE"
	colonne.add_child(titre)
	var run := InterfaceMobile.styliser_label(Label.new(), 25, Palette.TEXTE_ATTENUE, true)
	run.text = "%s\nSalle %d / %d  ·  Niveau %d  ·  %d Améliorations" % [
		Jeu.nom_run(), Jeu.salle_courante, Jeu.salles_du_chapitre(),
		Jeu.niveau_run, Jeu.inventaire.size()]
	run.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	run.custom_minimum_size.y = 86.0
	colonne.add_child(run)

	var separation := HSeparator.new()
	colonne.add_child(separation)
	_ajouter_bouton(colonne, "REPRENDRE", Palette.OR, true, _reprendre)
	_ajouter_bouton(colonne, "AMÉLIORATIONS DE LA RUN", Palette.ESSENCE, false, _ouvrir_ameliorations)
	_ajouter_bouton(colonne, "RÉGLAGES", Retro16.VIOLET, false, _ouvrir_reglages)
	_ajouter_bouton(colonne, "QUITTER LA RUN", Palette.DANGER, false, _quitter_run)

	var essence := InterfaceMobile.styliser_label(Label.new(), 20, Palette.ESSENCE, true)
	essence.text = "%s GOUTTES D'ESSENCE" % ReglagesJoueur.gouttes_affichees()
	colonne.add_child(essence)

func _ajouter_bouton(parent: VBoxContainer, texte: String, accent: Color,
		principal: bool, action: Callable) -> void:
	var bouton := Button.new()
	bouton.text = texte
	bouton.custom_minimum_size.y = 108.0
	InterfaceMobile.styliser_bouton(bouton, accent, principal)
	bouton.pressed.connect(action)
	parent.add_child(bouton)

func _reprendre() -> void:
	Sons.jouer("choix", -12.0)
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _ouvrir_reglages() -> void:
	Sons.jouer("choix", -12.0)
	var panneau := REGLAGES.instantiate()
	panneau.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(panneau)
	move_child(panneau, get_child_count() - 1)
	panneau.ferme.connect(func() -> void: panneau.queue_free())

func _ouvrir_ameliorations() -> void:
	if _inventaire != null:
		return
	Sons.jouer("choix", -12.0)
	_inventaire = VueAmeliorations.new()
	_inventaire.ferme.connect(func() -> void:
		if is_instance_valid(_inventaire):
			_inventaire.queue_free()
		_inventaire = null)
	add_child(_inventaire)
	move_child(_inventaire, get_child_count() - 1)
	StyleInterface.animer_entree(_inventaire, 18.0)

func _quitter_run() -> void:
	Sons.jouer("choix", -10.0)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _inventaire != null and is_instance_valid(_inventaire):
			_inventaire.ferme.emit()
		else:
			_reprendre()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	# Le combat reste visible derrière : le fond de pause est un voile et non une
	# capture peinte à une résolution fixe.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.004, 0.010, 0.030, 0.72))
	for index in 10:
		var p := Vector2(fmod(float(index * 173 + 80), maxf(1.0, size.x)),
			fmod(float(index * 211 + 120), maxf(1.0, size.y)))
		draw_circle(p, 2.0 + float(index % 2), Color(Palette.OR, 0.08 + 0.04 * sin(_anim * 1.5 + index)))

class VueAmeliorations:
	extends Control
	signal ferme

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var marge := MarginContainer.new()
		marge.set_anchors_preset(Control.PRESET_FULL_RECT)
		InterfaceMobile.appliquer_marges(marge, 0.0, true)
		add_child(marge)
		var panneau := PanelContainer.new()
		panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, true))
		marge.add_child(panneau)
		var colonne := VBoxContainer.new()
		colonne.add_theme_constant_override("separation", 16)
		panneau.add_child(colonne)
		var titre := InterfaceMobile.styliser_label(Label.new(), 36, Palette.TEXTE, true)
		titre.text = "AMÉLIORATIONS DE LA RUN"
		colonne.add_child(titre)
		var defilement := ScrollContainer.new()
		defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
		colonne.add_child(defilement)
		var liste := VBoxContainer.new()
		liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		liste.add_theme_constant_override("separation", 12)
		defilement.add_child(liste)
		if Jeu.inventaire.is_empty():
			var vide := InterfaceMobile.styliser_label(Label.new(), 25, Palette.TEXTE_ATTENUE, true)
			vide.text = "Aucune amélioration pour le moment."
			liste.add_child(vide)
		else:
			for entree in Jeu.inventaire_groupe():
				var reactif := Jeu.reactif(str(entree[0]))
				if reactif == null:
					continue
				var carte := CarteReactif.new()
				carte.configurer(reactif)
				carte.custom_minimum_size.y = 172.0
				carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
				liste.add_child(carte)
		var fermer := Button.new()
		fermer.text = "RETOUR"
		fermer.custom_minimum_size.y = 104.0
		InterfaceMobile.styliser_bouton(fermer, Palette.OR, true)
		fermer.pressed.connect(func() -> void: ferme.emit())
		colonne.add_child(fermer)

	func _notification(quoi: int) -> void:
		if quoi == NOTIFICATION_WM_GO_BACK_REQUEST:
			ferme.emit()

	func _draw() -> void:
		InterfaceMobile.dessiner_fond(self, size, false, Palette.OR, 0.0)

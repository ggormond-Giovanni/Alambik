extends Control

signal ferme

const CARTE_BRANCHE := preload("res://ui/carte_branche.gd")
const COULEURS := {
	"Défense": Color(0.38, 0.82, 0.72),
	"Offense": Color(1.0, 0.42, 0.34),
	"Utilitaire": Color(0.68, 0.58, 1.0),
}
const Y_NOEUDS := [10.0, 260.0, 510.0, 760.0]

var _statut: Label
var _onglets := {}
var _zone: ScrollContainer
var _carte: Control
var _branche := "Défense"
var _message := ""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	_afficher_branche(_branche)
	StyleInterface.animer_entree(self, 12.0)

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 34)
	marge.add_theme_constant_override("margin_right", 34)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 185)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 30)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 12)
	marge.add_child(colonne)
	_statut = Label.new()
	_statut.custom_minimum_size = Vector2(0, 74)
	_statut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_statut.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_statut.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_statut.add_theme_font_size_override("font_size", 22)
	_statut.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	colonne.add_child(_statut)
	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 8)
	colonne.add_child(onglets)
	for branche in ArbreCompetences.BRANCHES:
		var bouton := Button.new()
		bouton.text = branche.to_upper()
		bouton.toggle_mode = true
		bouton.custom_minimum_size = Vector2(0, 92)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.add_theme_font_size_override("font_size", 20)
		StyleInterface.styliser_bouton(bouton, COULEURS[branche], true)
		bouton.pressed.connect(func() -> void: _afficher_branche(branche))
		onglets.add_child(bouton)
		_onglets[branche] = bouton
	_zone = ScrollContainer.new()
	_zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_zone.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(_zone)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	colonne.add_child(actions)
	var reset := Button.new()
	reset.text = "RÉINITIALISER"
	reset.custom_minimum_size = Vector2(0, 96)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.add_theme_font_size_override("font_size", 22)
	StyleInterface.styliser_bouton(reset, Palette.DANGER, true)
	reset.pressed.connect(_reinitialiser)
	actions.add_child(reset)
	var fermer := Button.new()
	fermer.text = "RETOUR AU GRIMOIRE"
	fermer.custom_minimum_size = Vector2(0, 96)
	fermer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fermer.add_theme_font_size_override("font_size", 27)
	StyleInterface.styliser_bouton(fermer, Palette.TEXTE_ATTENUE, true)
	fermer.pressed.connect(func() -> void: ferme.emit())
	actions.add_child(fermer)

func _reinitialiser() -> void:
	var rembourses := ReglagesJoueur.reinitialiser_arbre()
	_afficher_branche(_branche)
	_message = "Réinitialisation gratuite : ✦ %d remboursés." % rembourses
	_rafraichir()

func _afficher_branche(branche: String) -> void:
	_branche = branche
	_message = ""
	for nom in _onglets:
		(_onglets[nom] as Button).set_pressed_no_signal(nom == branche)
	if _carte != null:
		_zone.remove_child(_carte)
		_carte.queue_free()
	_carte = Control.new()
	_carte.set_script(CARTE_BRANCHE)
	_carte.configurer(COULEURS[branche])
	_carte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zone.add_child(_carte)
	var ids: Array = ArbreCompetences.BRANCHES[branche]
	for index in ids.size():
		_creer_noeud(ids[index], index)
	_zone.scroll_vertical = 0
	_rafraichir()

func _creer_noeud(id: String, index: int) -> void:
	var bouton := Button.new()
	bouton.name = id
	bouton.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bouton.anchor_left = 0.055
	bouton.anchor_right = 0.945
	bouton.offset_left = 0.0
	bouton.offset_right = 0.0
	bouton.offset_top = Y_NOEUDS[index]
	bouton.offset_bottom = Y_NOEUDS[index] + 190.0
	bouton.add_theme_font_size_override("font_size", 22)
	StyleInterface.styliser_bouton(bouton, COULEURS[_branche], index > 0)
	bouton.pressed.connect(func() -> void: _sur_noeud(id))
	_carte.add_child(bouton)

func _sur_noeud(id: String) -> void:
	var noeud: Dictionary = ArbreCompetences.NOEUDS[id]
	var rang := ReglagesJoueur.rang_competence(id)
	if rang >= ArbreCompetences.MAX_RANG:
		_message = "%s est déjà au niveau maximum." % noeud["nom"]
	elif not ReglagesJoueur.mode_dev and not ArbreCompetences.prerequis_atteint(id, ReglagesJoueur.rangs_competences):
		var requis: Dictionary = ArbreCompetences.NOEUDS[noeud["requis"]]
		_message = "Terminez d’abord %s (%d/%d)." % [requis["nom"], ReglagesJoueur.rang_competence(noeud["requis"]), ArbreCompetences.MAX_RANG]
	elif not ReglagesJoueur.mode_dev and ReglagesJoueur.points_maitrise < ReglagesJoueur.cout_competence(id):
		_message = "Il manque %d points pour %s." % [ReglagesJoueur.cout_competence(id) - ReglagesJoueur.points_maitrise, noeud["nom"]]
	elif ReglagesJoueur.acheter_competence(id):
		_message = "%s passe au niveau %d !" % [noeud["nom"], rang + 1]
		Sons.jouer("choix", -12.0)
	_rafraichir()

func _rafraichir() -> void:
	var xp := "MAX" if ReglagesJoueur.mode_dev else "%d/%d" % [ReglagesJoueur.experience_heros, ReglagesJoueur.experience_heros_requise()]
	var base := "HÉROS %d  •  XP %s  •  ✦ %s" % [ReglagesJoueur.niveau_heros_effectif(), xp, ReglagesJoueur.points_maitrise_affiches()]
	_statut.text = _message if not _message.is_empty() else base
	_statut.add_theme_color_override("font_color", Palette.OR if not _message.is_empty() else Palette.TEXTE_ATTENUE)
	for id in ArbreCompetences.BRANCHES[_branche]:
		var bouton := _carte.get_node_or_null(id) as Button
		if bouton == null:
			continue
		var noeud: Dictionary = ArbreCompetences.NOEUDS[id]
		var rang := ReglagesJoueur.rang_competence(id)
		var disponible := ReglagesJoueur.mode_dev or ArbreCompetences.prerequis_atteint(id, ReglagesJoueur.rangs_competences)
		var prix := "MAX" if rang >= ArbreCompetences.MAX_RANG else "AMÉLIORER  ✦ %d" % ReglagesJoueur.cout_competence(id)
		if not disponible:
			prix = "VERROUILLÉ — terminez %s" % ArbreCompetences.NOEUDS[noeud["requis"]]["nom"]
		bouton.text = "%s   NIV. %d/%d\n%s\n%s" % [noeud["nom"], rang, ArbreCompetences.MAX_RANG, noeud["description"], prix]
		# Toujours appuyable : le message explique verrou ou manque de points.
		bouton.disabled = false
		bouton.modulate = Color.WHITE if disponible else Color(0.62, 0.62, 0.68)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.010, 0.025, 0.99))
	var police := ThemeDB.fallback_font
	var haut := Ecran.marge_haute() + 102.0
	Dessin.halo(self, Vector2(size.x * 0.5, haut), 235.0, Color(Palette.ESSENCE, 0.24), 6)
	draw_string(police, Vector2(0, haut), "ARBRE DE MAÎTRISE", HORIZONTAL_ALIGNMENT_CENTER, size.x, 43, Palette.TEXTE)

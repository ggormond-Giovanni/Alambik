extends Control

signal ferme

const BRANCHES := ["Offensif", "Défensif", "Utilitaire"]
const COULEURS := {
	"Offensif": Color(1.0, 0.38, 0.22),
	"Défensif": Color(0.30, 0.68, 1.0),
	"Utilitaire": Color(0.42, 0.86, 0.46),
}

var integre_menu := false
var _branche := "Offensif"
var _selection := ""
var _message := ""
var _anim := 0.0
var _onglets: Dictionary = {}
var _grille: GridContainer
var _details: VBoxContainer
var _message_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_interface()
	_afficher_branche(_branche)
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire_interface() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	InterfaceMobile.appliquer_marges(marge, 190.0 if integre_menu else 0.0, true)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)

	var entete := HBoxContainer.new()
	colonne.add_child(entete)
	var titres := VBoxContainer.new()
	titres.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(titres)
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 19, Palette.OR)
	surtitre.text = "PROGRESSION PERMANENTE"
	titres.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 36, Palette.TEXTE)
	titre.text = "MAÎTRISES"
	titres.add_child(titre)
	var ressources := InterfaceMobile.styliser_label(Label.new(), 20, Palette.ESSENCE, true)
	ressources.text = "NIV. %d\n%s GOUTTES" % [ReglagesJoueur.niveau_compte_effectif(), ReglagesJoueur.gouttes_affichees()]
	ressources.custom_minimum_size.x = 160.0
	entete.add_child(ressources)
	if not integre_menu:
		var retour := Button.new()
		retour.text = "RETOUR"
		retour.custom_minimum_size = Vector2(140.0, 82.0)
		InterfaceMobile.styliser_bouton(retour, Palette.OR, false)
		retour.pressed.connect(func() -> void: ferme.emit())
		entete.add_child(retour)

	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 8)
	colonne.add_child(onglets)
	for branche in BRANCHES:
		var bouton := Button.new()
		bouton.text = branche.to_upper()
		bouton.custom_minimum_size = Vector2(0.0, 88.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.pressed.connect(func() -> void: _afficher_branche(branche))
		onglets.add_child(bouton)
		_onglets[branche] = bouton

	var defilement := ScrollContainer.new()
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(defilement)
	var contenu := VBoxContainer.new()
	contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenu.add_theme_constant_override("separation", 12)
	defilement.add_child(contenu)

	var bloc_noeuds := PanelContainer.new()
	bloc_noeuds.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.ESSENCE, false))
	contenu.add_child(bloc_noeuds)
	var noeuds_colonne := VBoxContainer.new()
	noeuds_colonne.add_theme_constant_override("separation", 8)
	bloc_noeuds.add_child(noeuds_colonne)
	var titre_noeuds := InterfaceMobile.styliser_label(Label.new(), 22, Palette.ESSENCE, true)
	titre_noeuds.text = "CHOISIR UNE MAÎTRISE"
	noeuds_colonne.add_child(titre_noeuds)
	_grille = GridContainer.new()
	_grille.columns = 2
	_grille.add_theme_constant_override("h_separation", 8)
	_grille.add_theme_constant_override("v_separation", 8)
	noeuds_colonne.add_child(_grille)

	var bloc_details := PanelContainer.new()
	bloc_details.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, true))
	contenu.add_child(bloc_details)
	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 10)
	bloc_details.add_child(_details)

	var reset := Button.new()
	reset.text = "RÉINITIALISER L'ARBRE ET REMBOURSER LES GOUTTES"
	reset.custom_minimum_size.y = 86.0
	InterfaceMobile.styliser_bouton(reset, Palette.DANGER, false)
	reset.pressed.connect(_reinitialiser)
	contenu.add_child(reset)

	_message_label = InterfaceMobile.styliser_label(Label.new(), 20, Palette.OR, true)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size.y = 44.0
	colonne.add_child(_message_label)

func _afficher_branche(branche: String) -> void:
	_branche = branche
	_message = ""
	var ids: Array = ArbreCompetences.BRANCHES[_branche]
	_selection = str(ids[0]) if not ids.is_empty() else ""
	Sons.jouer("choix", -17.0)
	_rafraichir()

func _selectionner(id: String) -> void:
	_selection = id
	_message = ""
	Sons.jouer("choix", -18.0)
	_rafraichir_details()

func _ameliorer() -> void:
	if _selection.is_empty():
		return
	var noeud: Dictionary = ArbreCompetences.NOEUDS[_selection]
	var rang := ReglagesJoueur.rang_competence(_selection)
	if rang >= ArbreCompetences.rangs(_selection):
		_message = "%s est au rang maximum." % noeud["nom"]
	elif not ReglagesJoueur.mode_dev and not ArbreCompetences.prerequis_atteint(_selection, ReglagesJoueur.rangs_competences):
		var requis: Dictionary = ArbreCompetences.NOEUDS[noeud["requis"]]
		_message = "Terminez d’abord %s." % requis["nom"]
	elif not ReglagesJoueur.mode_dev and ReglagesJoueur.gouttes < ReglagesJoueur.cout_competence(_selection):
		_message = "Il manque %d Gouttes." % (ReglagesJoueur.cout_competence(_selection) - ReglagesJoueur.gouttes)
	elif ReglagesJoueur.acheter_competence(_selection):
		_message = "%s rang %d/%d : bonus permanent actif." % [noeud["nom"],
			ReglagesJoueur.rang_competence(_selection), ArbreCompetences.rangs(_selection)]
		Sons.jouer("fusion", -12.0)
	_rafraichir()

func _reinitialiser() -> void:
	var rembourses := ReglagesJoueur.reinitialiser_arbre()
	_message = "Réinitialisation : %d Gouttes remboursées." % rembourses
	Sons.jouer("choix", -12.0)
	_rafraichir()

func _rafraichir() -> void:
	for branche in BRANCHES:
		var bouton: Button = _onglets[branche]
		var actif := branche == _branche
		InterfaceMobile.styliser_bouton(bouton, COULEURS[branche], actif)
		bouton.add_theme_font_size_override("font_size", 20)
	_rafraichir_grille()
	_rafraichir_details()
	_message_label.text = _message

func _rafraichir_grille() -> void:
	for enfant in _grille.get_children():
		enfant.queue_free()
	var couleur: Color = COULEURS[_branche]
	var ids: Array = ArbreCompetences.BRANCHES[_branche]
	for id_variant in ids:
		var id := str(id_variant)
		var noeud: Dictionary = ArbreCompetences.NOEUDS[id]
		var rang := ReglagesJoueur.rang_competence(id)
		var maximum := ArbreCompetences.rangs(id)
		var disponible := ReglagesJoueur.mode_dev or ArbreCompetences.prerequis_atteint(id, ReglagesJoueur.rangs_competences)
		var cout := ReglagesJoueur.cout_competence(id)
		var etat := "MAX" if rang >= maximum else "%d GOUTTES" % cout if disponible else "VERROUILLÉ"
		var bouton := Button.new()
		bouton.text = "%s\nRANG %d/%d  ·  %s" % [str(noeud["nom"]).to_upper(), rang, maximum, etat]
		bouton.custom_minimum_size = Vector2(0.0, 112.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var selectionne := id == _selection
		InterfaceMobile.styliser_bouton(bouton,
			couleur if disponible else Palette.BORD_PAGE, selectionne)
		bouton.add_theme_font_size_override("font_size", 18)
		bouton.pressed.connect(func() -> void: _selectionner(id))
		_grille.add_child(bouton)

func _rafraichir_details() -> void:
	for enfant in _details.get_children():
		enfant.queue_free()
	if _selection.is_empty():
		return
	var couleur: Color = COULEURS[_branche]
	var noeud: Dictionary = ArbreCompetences.NOEUDS[_selection]
	var rang := ReglagesJoueur.rang_competence(_selection)
	var maximum := ArbreCompetences.rangs(_selection)
	var titre := InterfaceMobile.styliser_label(Label.new(), 28, couleur, true)
	titre.text = "%s  ·  %d/%d" % [str(noeud["nom"]).to_upper(), rang, maximum]
	_details.add_child(titre)
	var description := InterfaceMobile.styliser_label(Label.new(), 22, Palette.TEXTE, true)
	description.text = ArbreCompetences.description_effective(_selection)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 58.0
	_details.add_child(description)
	var actuel := ArbreCompetences.valeur_au_rang(_selection, rang)
	var comparaison := "ACTUEL %s" % actuel if rang >= maximum else \
		"ACTUEL %s   →   RANG %d : %s" % [actuel, rang + 1,
			ArbreCompetences.valeur_au_rang(_selection, rang + 1)]
	var comparaison_label := InterfaceMobile.styliser_label(Label.new(), 21, Palette.OR, true)
	comparaison_label.text = comparaison
	_details.add_child(comparaison_label)
	var disponible := ReglagesJoueur.mode_dev or ArbreCompetences.prerequis_atteint(_selection, ReglagesJoueur.rangs_competences)
	var cout := ReglagesJoueur.cout_competence(_selection)
	var bouton := Button.new()
	bouton.text = "RANG MAXIMUM" if rang >= maximum else "VERROUILLÉ" if not disponible else "AMÉLIORER  ·  %d GOUTTES" % cout
	bouton.disabled = rang >= maximum or not disponible
	bouton.custom_minimum_size.y = 92.0
	InterfaceMobile.styliser_bouton(bouton, couleur, not bouton.disabled)
	bouton.pressed.connect(_ameliorer)
	_details.add_child(bouton)

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	InterfaceMobile.dessiner_fond(self, size, false, COULEURS[_branche], _anim)

extends Control

signal ferme

const CATEGORIES := ["Actif", "Passifs", "Ultime"]
const COULEURS := {
	"Actif": Color(1.0, 0.52, 0.28),
	"Passifs": Color(0.38, 0.82, 0.72),
	"Ultime": Color(0.68, 0.58, 1.0),
}

var _categorie := "Actif"
var _onglets := {}
var _liste: VBoxContainer
var _resume: Label
var _message: Label
var integre_menu := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	_afficher("Actif")
	StyleInterface.animer_entree(self, 12.0)

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 34)
	marge.add_theme_constant_override("margin_right", 34)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 180)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + (170 if integre_menu else 30))
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 12)
	marge.add_child(colonne)
	_resume = Label.new()
	_resume.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resume.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resume.custom_minimum_size = Vector2(0, 72)
	_resume.add_theme_font_size_override("font_size", 22)
	_resume.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	colonne.add_child(_resume)
	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 8)
	colonne.add_child(onglets)
	for categorie in CATEGORIES:
		var bouton := Button.new()
		bouton.text = categorie.to_upper()
		bouton.toggle_mode = true
		bouton.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.add_theme_font_size_override("font_size", 21)
		StyleInterface.styliser_bouton(bouton, COULEURS[categorie], true)
		bouton.pressed.connect(func() -> void: _afficher(categorie))
		onglets.add_child(bouton)
		_onglets[categorie] = bouton
	var defilement := ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(defilement)
	_liste = VBoxContainer.new()
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_liste.add_theme_constant_override("separation", 12)
	defilement.add_child(_liste)
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(0, 58)
	_message.add_theme_font_size_override("font_size", 21)
	_message.add_theme_color_override("font_color", Palette.OR)
	colonne.add_child(_message)
	if not integre_menu:
		var retour := Button.new()
		retour.text = "RETOUR AU GRIMOIRE"
		retour.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
		retour.add_theme_font_size_override("font_size", 29)
		StyleInterface.styliser_bouton(retour, Palette.TEXTE_ATTENUE, true)
		retour.pressed.connect(func() -> void: ferme.emit())
		colonne.add_child(retour)

func _catalogue() -> Dictionary:
	match _categorie:
		"Passifs": return Sorts.PASSIFS
		"Ultime": return Sorts.ULTIMES
	return Sorts.ACTIFS

func _afficher(categorie: String) -> void:
	_categorie = categorie
	for nom in _onglets:
		(_onglets[nom] as Button).set_pressed_no_signal(nom == categorie)
	for enfant in _liste.get_children():
		enfant.queue_free()
	for id in _catalogue():
		_ajouter_choix(id, _catalogue()[id])
	_rafraichir_resume()

func _ajouter_choix(id: String, donnees: Dictionary) -> void:
	var ouvert := ReglagesJoueur.sort_debloque(id)
	var decouvert := ReglagesJoueur.sort_decouvert(id)
	var rang := ReglagesJoueur.rang_sort(id)
	var equipe := id == ReglagesJoueur.sort_actif_equipe or id == ReglagesJoueur.ultime_equipe or id in ReglagesJoueur.passifs_equipes
	var etat := "ÉQUIPÉ • NIVEAU %d/5 • %d %%" % [rang, roundi(ReglagesJoueur.efficacite_sort(id) * 100.0)] if equipe \
		else "NIVEAU %d/5 • %d %% • TOUCHER POUR ÉQUIPER" % [rang, roundi(ReglagesJoueur.efficacite_sort(id) * 100.0)] if ouvert \
		else "NIVEAU 0/5 • À OBTENIR EN DÉFI" if decouvert \
		else "DÉBLOCAGE AU NIVEAU HÉROS %d" % int(donnees["niveau"])
	var bouton := Button.new()
	bouton.text = "%s\n%s\n%s" % [donnees["nom"], donnees["description"], etat]
	bouton.custom_minimum_size = Vector2(0, 150)
	bouton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bouton.add_theme_font_size_override("font_size", 22)
	StyleInterface.styliser_bouton(bouton, COULEURS[_categorie], not ouvert)
	bouton.disabled = not ouvert
	bouton.pressed.connect(func() -> void: _choisir(id))
	_liste.add_child(bouton)

func _choisir(id: String) -> void:
	if _categorie == "Actif":
		ReglagesJoueur.equiper_sort(id, "actif")
		_message.text = "%s équipé dans l’emplacement actif." % Sorts.ACTIFS[id]["nom"]
	elif _categorie == "Ultime":
		ReglagesJoueur.equiper_sort(id, "ultime")
		_message.text = "%s équipé dans l’emplacement ultime." % Sorts.ULTIMES[id]["nom"]
	else:
		var resultat := ReglagesJoueur.basculer_passif(id)
		match resultat:
			"equipe": _message.text = "%s équipé." % Sorts.PASSIFS[id]["nom"]
			"retire": _message.text = "%s retiré." % Sorts.PASSIFS[id]["nom"]
			"plein": _message.text = "Deux passifs sont déjà équipés : retirez-en un."
	Sons.jouer("choix", -12.0)
	_afficher(_categorie)

func _rafraichir_resume() -> void:
	var actif: String = str(Sorts.ACTIFS.get(ReglagesJoueur.sort_actif_effectif(), {}).get("nom", "Aucun"))
	var ultime: String = str(Sorts.ULTIMES.get(ReglagesJoueur.ultime_effectif(), {}).get("nom", "Aucun"))
	_resume.text = "BUILD — ACTIF : %s  •  PASSIFS : %d/2  •  ULTIME : %s" % [actif, ReglagesJoueur.passifs_equipes.size(), ultime]

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.010, 0.025, 0.99))
	var haut := Ecran.marge_haute() + 102.0
	Dessin.halo(self, Vector2(size.x * 0.5, haut), 235.0, Color(Palette.OR, 0.22), 6)
	draw_string(ThemeDB.fallback_font, Vector2(0, haut), "ARSENAL DE SORTS", HORIZONTAL_ALIGNMENT_CENTER, size.x, 43, Palette.TEXTE)

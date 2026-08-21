extends Control

signal ferme

const CATEGORIES := ["Actifs", "Passifs", "Ultimes"]
const COULEURS := {
	"Actifs": Color(1.0, 0.55, 0.24),
	"Passifs": Color(0.38, 0.86, 0.70),
	"Ultimes": Color(0.70, 0.54, 1.0),
}

var integre_menu := false
var _categorie := "Actifs"
var _page := 0
var _message := ""
var _anim := 0.0
var _onglets: Dictionary = {}
var _loadout: HBoxContainer
var _grille: GridContainer
var _message_label: Label
var _pagination: Label
var _precedent: Button
var _suivant: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_interface()
	_afficher("Actifs")
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
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 19, Retro16.VIOLET)
	surtitre.text = "GRIMOIRE DES CAPACITÉS"
	titres.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 36, Palette.TEXTE)
	titre.text = "SORTS"
	titres.add_child(titre)
	if not integre_menu:
		var retour := Button.new()
		retour.text = "RETOUR"
		retour.custom_minimum_size = Vector2(140.0, 82.0)
		InterfaceMobile.styliser_bouton(retour, Palette.OR, false)
		retour.pressed.connect(func() -> void: ferme.emit())
		entete.add_child(retour)

	var bloc_loadout := PanelContainer.new()
	bloc_loadout.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, false))
	colonne.add_child(bloc_loadout)
	var charge := VBoxContainer.new()
	charge.add_theme_constant_override("separation", 8)
	bloc_loadout.add_child(charge)
	var titre_charge := InterfaceMobile.styliser_label(Label.new(), 21, Palette.OR, true)
	titre_charge.text = "ÉQUIPEMENT ACTUEL — toucher pour retirer"
	charge.add_child(titre_charge)
	_loadout = HBoxContainer.new()
	_loadout.add_theme_constant_override("separation", 8)
	charge.add_child(_loadout)

	var onglets := HBoxContainer.new()
	onglets.add_theme_constant_override("separation", 8)
	colonne.add_child(onglets)
	for categorie in CATEGORIES:
		var bouton := Button.new()
		bouton.text = categorie.to_upper()
		bouton.custom_minimum_size = Vector2(0.0, 88.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.pressed.connect(func() -> void: _afficher(categorie))
		onglets.add_child(bouton)
		_onglets[categorie] = bouton

	var defilement := ScrollContainer.new()
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(defilement)
	_grille = GridContainer.new()
	_grille.columns = 2
	_grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grille.add_theme_constant_override("h_separation", 10)
	_grille.add_theme_constant_override("v_separation", 10)
	defilement.add_child(_grille)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	colonne.add_child(nav)
	_precedent = Button.new()
	_precedent.text = "‹"
	_precedent.custom_minimum_size = Vector2(96.0, 76.0)
	InterfaceMobile.styliser_bouton(_precedent, Palette.ESSENCE, false)
	_precedent.pressed.connect(func() -> void: _changer_page(-1))
	nav.add_child(_precedent)
	_pagination = InterfaceMobile.styliser_label(Label.new(), 20, Palette.TEXTE_ATTENUE, true)
	_pagination.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(_pagination)
	_suivant = Button.new()
	_suivant.text = "›"
	_suivant.custom_minimum_size = Vector2(96.0, 76.0)
	InterfaceMobile.styliser_bouton(_suivant, Palette.ESSENCE, false)
	_suivant.pressed.connect(func() -> void: _changer_page(1))
	nav.add_child(_suivant)

	_message_label = InterfaceMobile.styliser_label(Label.new(), 20, Palette.OR, true)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size.y = 44.0
	colonne.add_child(_message_label)

func _catalogue() -> Dictionary:
	match _categorie:
		"Passifs": return Sorts.PASSIFS
		"Ultimes": return Sorts.ULTIMES
	return Sorts.ACTIFS

func _ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _catalogue():
		ids.append(str(id))
	return ids

func _ids_page() -> Array[String]:
	var ids := _ids()
	var debut := _page * 6
	var resultat: Array[String] = []
	for index in range(debut, mini(debut + 6, ids.size())):
		resultat.append(ids[index])
	return resultat

func _afficher(categorie: String) -> void:
	_categorie = categorie
	_page = 0
	_message = ""
	Sons.jouer("choix", -17.0)
	_rafraichir()

func _changer_page(direction: int) -> void:
	var pages := maxi(1, ceili(float(_ids().size()) / 6.0))
	var nouvelle := clampi(_page + direction, 0, pages - 1)
	if nouvelle == _page:
		return
	_page = nouvelle
	_message = ""
	Sons.jouer("choix", -17.0)
	_rafraichir()

func _choisir(id: String) -> void:
	if not ReglagesJoueur.sort_debloque(id):
		_message = "%s s’obtient dans les Épreuves." % str(_catalogue()[id]["nom"])
		_rafraichir()
		return
	if _categorie == "Actifs":
		if id == ReglagesJoueur.sort_actif_equipe:
			ReglagesJoueur.retirer_sort("actif")
			_message = "%s retiré." % str(Sorts.ACTIFS[id]["nom"])
		else:
			ReglagesJoueur.equiper_sort(id, "actif")
			_message = "%s équipé comme Sort actif." % str(Sorts.ACTIFS[id]["nom"])
	elif _categorie == "Ultimes":
		if id == ReglagesJoueur.ultime_equipe:
			ReglagesJoueur.retirer_sort("ultime")
			_message = "%s retiré." % str(Sorts.ULTIMES[id]["nom"])
		else:
			ReglagesJoueur.equiper_sort(id, "ultime")
			_message = "%s équipé comme Ultime." % str(Sorts.ULTIMES[id]["nom"])
	else:
		var resultat := ReglagesJoueur.basculer_passif(id)
		match resultat:
			"equipe": _message = "%s équipé." % str(Sorts.PASSIFS[id]["nom"])
			"retire": _message = "%s retiré." % str(Sorts.PASSIFS[id]["nom"])
			"plein": _message = "Tous les emplacements Passifs sont occupés."
	Sons.jouer("choix", -12.0)
	_rafraichir()

func _retirer_slot(index: int) -> void:
	var id := ""
	if index == 0:
		id = ReglagesJoueur.sort_actif_equipe
		if not id.is_empty():
			ReglagesJoueur.retirer_sort("actif")
	elif index == 3:
		id = ReglagesJoueur.ultime_equipe
		if not id.is_empty():
			ReglagesJoueur.retirer_sort("ultime")
	elif index - 1 < ReglagesJoueur.passifs_equipes.size():
		id = str(ReglagesJoueur.passifs_equipes[index - 1])
		ReglagesJoueur.basculer_passif(id)
	if id.is_empty():
		return
	_message = "%s retiré." % str(Sorts.donnees(id).get("nom", "Sort"))
	Sons.jouer("choix", -12.0)
	_rafraichir()

func _rafraichir() -> void:
	_rafraichir_onglets()
	_rafraichir_loadout()
	_rafraichir_grille()
	_message_label.text = _message

func _rafraichir_onglets() -> void:
	for categorie in CATEGORIES:
		var bouton: Button = _onglets[categorie]
		var actif := categorie == _categorie
		InterfaceMobile.styliser_bouton(bouton, COULEURS[categorie], actif)
		bouton.add_theme_font_size_override("font_size", 21)

func _rafraichir_loadout() -> void:
	for enfant in _loadout.get_children():
		enfant.queue_free()
	var ids := [ReglagesJoueur.sort_actif_equipe,
		str(ReglagesJoueur.passifs_equipes[0]) if ReglagesJoueur.passifs_equipes.size() > 0 else "",
		str(ReglagesJoueur.passifs_equipes[1]) if ReglagesJoueur.passifs_equipes.size() > 1 else "",
		ReglagesJoueur.ultime_equipe]
	var noms := ["ACTIF", "PASSIF 1", "PASSIF 2", "ULTIME"]
	for index in 4:
		var id := str(ids[index])
		var bouton := Button.new()
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.custom_minimum_size = Vector2(0.0, 94.0)
		var verrouille := index == 2 and ReglagesJoueur.nombre_slots_passifs() < 2
		var nom_sort := "VERROUILLÉ" if verrouille else "VIDE"
		if not id.is_empty():
			nom_sort = str(Sorts.donnees(id).get("nom", id))
		bouton.text = "%s\n%s" % [noms[index], nom_sort]
		bouton.disabled = id.is_empty()
		InterfaceMobile.styliser_bouton(bouton,
			COULEURS["Ultimes"] if index == 3 else COULEURS["Passifs"] if index in [1, 2] else COULEURS["Actifs"],
			not id.is_empty())
		bouton.add_theme_font_size_override("font_size", 17)
		bouton.pressed.connect(func() -> void: _retirer_slot(index))
		_loadout.add_child(bouton)

func _rafraichir_grille() -> void:
	for enfant in _grille.get_children():
		enfant.queue_free()
	var couleur: Color = COULEURS[_categorie]
	for id in _ids_page():
		var d: Dictionary = _catalogue()[id]
		var ouvert := ReglagesJoueur.sort_debloque(id)
		var equipe := id == ReglagesJoueur.sort_actif_equipe or id == ReglagesJoueur.ultime_equipe or id in ReglagesJoueur.passifs_equipes
		var rang := ReglagesJoueur.rang_sort(id)
		var bouton := Button.new()
		var etat := "À OBTENIR" if not ouvert else "ÉQUIPÉ" if equipe else "RANG %d/%d" % [rang, Reglages.CAPACITE_RANG_MAX]
		bouton.text = "%s\n%s\n%s" % [str(d["nom"]).to_upper(), str(d["description"]), etat]
		bouton.custom_minimum_size = Vector2(0.0, 190.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		InterfaceMobile.styliser_bouton(bouton, couleur if ouvert else Palette.BORD_PAGE, equipe)
		bouton.add_theme_font_size_override("font_size", 18)
		bouton.pressed.connect(func() -> void: _choisir(id))
		_grille.add_child(bouton)
	var pages := maxi(1, ceili(float(_ids().size()) / 6.0))
	_pagination.text = "PAGE %d / %d" % [_page + 1, pages]
	_precedent.disabled = _page <= 0
	_suivant.disabled = _page >= pages - 1

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	InterfaceMobile.dessiner_fond(self, size, false, COULEURS[_categorie], _anim)

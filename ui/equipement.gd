extends Control

signal ferme

const SLOTS := ["anneau_gauche", "collier", "anneau_droit"]
const NOMS_SLOTS := {
	"anneau_gauche": "ANNEAU GAUCHE",
	"collier": "COLLIER",
	"anneau_droit": "ANNEAU DROIT",
}
const LIBELLES_BONUS := {
	"degats": "Dégâts",
	"pv": "PV max",
	"cadence": "Cadence",
	"vitesse": "Vitesse",
	"collecte": "Gouttes",
}

var integre_menu := false
var _slot_selectionne := "anneau_gauche"
var _objet_selectionne := ""
var _page := 0
var _anim := 0.0
var _slots_barre: HBoxContainer
var _inventaire: GridContainer
var _details: VBoxContainer
var _message: Label
var _pagination: Label
var _precedent: Button
var _suivant: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_interface()
	_selectionner_slot(_slot_selectionne)
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
	entete.add_theme_constant_override("separation", 12)
	colonne.add_child(entete)
	var titres := VBoxContainer.new()
	titres.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(titres)
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 19, Palette.ESSENCE)
	surtitre.text = "ATELIER DE L'ALCHIMISTE"
	titres.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 36, Palette.TEXTE)
	titre.text = "ÉQUIPEMENT"
	titres.add_child(titre)
	var pierres := InterfaceMobile.styliser_label(Label.new(), 22, Palette.OR, true)
	pierres.text = "%d\nPIERRES" % ReglagesJoueur.pierres_forge
	pierres.custom_minimum_size.x = 130.0
	entete.add_child(pierres)
	if not integre_menu:
		var retour := Button.new()
		retour.text = "RETOUR"
		retour.custom_minimum_size = Vector2(140.0, 82.0)
		InterfaceMobile.styliser_bouton(retour, Palette.OR, false)
		retour.pressed.connect(func() -> void: ferme.emit())
		entete.add_child(retour)

	_slots_barre = HBoxContainer.new()
	_slots_barre.add_theme_constant_override("separation", 10)
	colonne.add_child(_slots_barre)

	var stats := PanelContainer.new()
	stats.add_theme_stylebox_override("panel", InterfaceMobile.panneau_leger(Palette.ESSENCE))
	colonne.add_child(stats)
	var stats_label := InterfaceMobile.styliser_label(Label.new(), 21, Palette.TEXTE_ATTENUE, true)
	stats_label.text = _resume_heros()
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.custom_minimum_size.y = 80.0
	stats.add_child(stats_label)

	var zone := HSplitContainer.new()
	zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zone.split_offset = 500
	colonne.add_child(zone)

	var bloc_inventaire := PanelContainer.new()
	bloc_inventaire.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.ESSENCE, false))
	zone.add_child(bloc_inventaire)
	var inventaire_colonne := VBoxContainer.new()
	inventaire_colonne.add_theme_constant_override("separation", 10)
	bloc_inventaire.add_child(inventaire_colonne)
	var titre_inv := InterfaceMobile.styliser_label(Label.new(), 23, Palette.ESSENCE, true)
	titre_inv.text = "INVENTAIRE COMPATIBLE"
	inventaire_colonne.add_child(titre_inv)
	_inventaire = GridContainer.new()
	_inventaire.columns = 2
	_inventaire.add_theme_constant_override("h_separation", 8)
	_inventaire.add_theme_constant_override("v_separation", 8)
	_inventaire.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventaire_colonne.add_child(_inventaire)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	inventaire_colonne.add_child(nav)
	_precedent = Button.new()
	_precedent.text = "‹"
	_precedent.custom_minimum_size = Vector2(90.0, 72.0)
	InterfaceMobile.styliser_bouton(_precedent, Palette.ESSENCE, false)
	_precedent.pressed.connect(func() -> void: _changer_page(-1))
	nav.add_child(_precedent)
	_pagination = InterfaceMobile.styliser_label(Label.new(), 20, Palette.TEXTE_ATTENUE, true)
	_pagination.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(_pagination)
	_suivant = Button.new()
	_suivant.text = "›"
	_suivant.custom_minimum_size = Vector2(90.0, 72.0)
	InterfaceMobile.styliser_bouton(_suivant, Palette.ESSENCE, false)
	_suivant.pressed.connect(func() -> void: _changer_page(1))
	nav.add_child(_suivant)

	var bloc_details := PanelContainer.new()
	bloc_details.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, false))
	zone.add_child(bloc_details)
	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 10)
	bloc_details.add_child(_details)

	_message = InterfaceMobile.styliser_label(Label.new(), 20, Palette.OR, true)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size.y = 48.0
	colonne.add_child(_message)

func _selectionner_slot(slot: String) -> void:
	_slot_selectionne = slot
	_page = 0
	_objet_selectionne = str(ReglagesJoueur.equipements.get(slot, ""))
	if _objet_selectionne.is_empty():
		var disponibles := _objets_compatibles()
		if not disponibles.is_empty():
			_objet_selectionne = disponibles[0]
	_message.text = ""
	_rafraichir()

func _objets_compatibles() -> Array[String]:
	var resultat: Array[String] = []
	for id in ReglagesJoueur.objets_disponibles():
		if CatalogueObjets.compatible(_slot_selectionne, id):
			resultat.append(id)
	resultat.sort_custom(func(a: String, b: String) -> bool:
		return int(CatalogueObjets.OBJETS[a]["chapitre"]) < int(CatalogueObjets.OBJETS[b]["chapitre"]))
	return resultat

func _objets_page() -> Array[String]:
	var tous := _objets_compatibles()
	var debut := _page * 6
	return tous.slice(debut, mini(debut + 6, tous.size()))

func _changer_page(direction: int) -> void:
	var pages := maxi(1, ceili(float(_objets_compatibles().size()) / 6.0))
	var nouvelle := clampi(_page + direction, 0, pages - 1)
	if nouvelle == _page:
		return
	_page = nouvelle
	_objet_selectionne = ""
	var visibles := _objets_page()
	if not visibles.is_empty():
		_objet_selectionne = visibles[0]
	Sons.jouer("choix", -17.0)
	_rafraichir()

func _selectionner_objet(id: String) -> void:
	_objet_selectionne = id
	_message.text = ""
	Sons.jouer("choix", -16.0)
	_rafraichir()

func _equiper() -> void:
	if _objet_selectionne.is_empty():
		return
	if ReglagesJoueur.equiper_objet(_slot_selectionne, _objet_selectionne):
		_message.text = "Objet équipé."
		Sons.jouer("choix", -10.0)
		_rafraichir()

func _retirer() -> void:
	if ReglagesJoueur.retirer_objet(_slot_selectionne):
		_message.text = "Objet retiré."
		Sons.jouer("choix", -12.0)
		_rafraichir()

func _ameliorer() -> void:
	if _objet_selectionne.is_empty():
		return
	if ReglagesJoueur.ameliorer_objet(_objet_selectionne):
		_message.text = "Objet amélioré."
		Sons.jouer("fusion", -10.0)
		_rafraichir()

func _rafraichir() -> void:
	_rafraichir_slots()
	_rafraichir_inventaire()
	_rafraichir_details()

func _rafraichir_slots() -> void:
	for enfant in _slots_barre.get_children():
		enfant.queue_free()
	for slot in SLOTS:
		var id := str(ReglagesJoueur.equipements.get(slot, ""))
		var texte := str(NOMS_SLOTS[slot])
		if id.is_empty():
			texte += "\nVIDE"
		else:
			texte += "\n%s  ·  NIV. %d" % [str(CatalogueObjets.OBJETS[id]["nom"]), ReglagesJoueur.niveau_objet(id)]
		var bouton := Button.new()
		bouton.text = texte
		bouton.custom_minimum_size = Vector2(0.0, 112.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		InterfaceMobile.styliser_bouton(bouton,
			Palette.OR if slot == _slot_selectionne else Palette.ESSENCE,
			slot == _slot_selectionne)
		bouton.add_theme_font_size_override("font_size", 19)
		bouton.pressed.connect(func() -> void: _selectionner_slot(slot))
		_slots_barre.add_child(bouton)

func _rafraichir_inventaire() -> void:
	for enfant in _inventaire.get_children():
		enfant.queue_free()
	var visibles := _objets_page()
	for id in visibles:
		var d: Dictionary = CatalogueObjets.OBJETS[id]
		var niveau := ReglagesJoueur.niveau_objet(id)
		var bouton := Button.new()
		bouton.text = "%s\nNIV. %d" % [str(d["nom"]).to_upper(), niveau]
		bouton.custom_minimum_size = Vector2(0.0, 116.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var selectionne := id == _objet_selectionne
		InterfaceMobile.styliser_bouton(bouton,
			Color(d["teinte"]) if selectionne else Palette.ESSENCE, selectionne)
		bouton.add_theme_font_size_override("font_size", 19)
		bouton.pressed.connect(func() -> void: _selectionner_objet(id))
		_inventaire.add_child(bouton)
	var pages := maxi(1, ceili(float(_objets_compatibles().size()) / 6.0))
	_pagination.text = "PAGE %d / %d" % [_page + 1, pages]
	_precedent.disabled = _page <= 0
	_suivant.disabled = _page >= pages - 1

func _rafraichir_details() -> void:
	for enfant in _details.get_children():
		enfant.queue_free()
	if _objet_selectionne.is_empty() or not CatalogueObjets.OBJETS.has(_objet_selectionne):
		var vide := InterfaceMobile.styliser_label(Label.new(), 23, Palette.TEXTE_ATTENUE, true)
		vide.text = "AUCUN OBJET SÉLECTIONNÉ"
		_details.add_child(vide)
		return
	var d: Dictionary = CatalogueObjets.OBJETS[_objet_selectionne]
	var niveau := ReglagesJoueur.niveau_objet(_objet_selectionne)
	var titre := InterfaceMobile.styliser_label(Label.new(), 27, Color(d["teinte"]), true)
	titre.text = str(d["nom"]).to_upper()
	_details.add_child(titre)
	var meta := InterfaceMobile.styliser_label(Label.new(), 20, Palette.TEXTE_ATTENUE, true)
	meta.text = "NIVEAU %d  ·  MONDE %d" % [niveau, int(d["monde"]) + 1]
	_details.add_child(meta)
	var apport := CatalogueObjets.bonus_objet(_objet_selectionne, niveau)
	var lignes: Array[String] = []
	for champ in LIBELLES_BONUS:
		var valeur := roundi(float(apport.get(champ, 0.0)) * 100.0)
		if valeur != 0:
			lignes.append("%s  %+d %%" % [LIBELLES_BONUS[champ], valeur])
	var bonus := InterfaceMobile.styliser_label(Label.new(), 21, Palette.TEXTE)
	bonus.text = "\n".join(lignes) if not lignes.is_empty() else "Aucun bonus chiffré."
	bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_details.add_child(bonus)

	var equipe := str(ReglagesJoueur.equipements.get(_slot_selectionne, "")) == _objet_selectionne
	var equiper := Button.new()
	equiper.text = "ÉQUIPÉ" if equipe else "ÉQUIPER"
	equiper.disabled = equipe
	equiper.custom_minimum_size.y = 82.0
	InterfaceMobile.styliser_bouton(equiper, Palette.ESSENCE, not equipe)
	equiper.pressed.connect(_equiper)
	_details.add_child(equiper)
	var retirer := Button.new()
	retirer.text = "RETIRER DU SLOT"
	retirer.disabled = str(ReglagesJoueur.equipements.get(_slot_selectionne, "")).is_empty()
	retirer.custom_minimum_size.y = 76.0
	InterfaceMobile.styliser_bouton(retirer, Palette.OR, false)
	retirer.pressed.connect(_retirer)
	_details.add_child(retirer)
	var cout := ReglagesJoueur.cout_forge(_objet_selectionne)
	var ameliorer := Button.new()
	ameliorer.text = "AMÉLIORER  ·  %d PIERRES" % cout
	ameliorer.disabled = niveau >= Reglages.FORGE_NIVEAU_MAX or ReglagesJoueur.pierres_forge < cout
	ameliorer.custom_minimum_size.y = 86.0
	InterfaceMobile.styliser_bouton(ameliorer, Palette.OR, true)
	ameliorer.pressed.connect(_ameliorer)
	_details.add_child(ameliorer)

func _resume_heros() -> String:
	var stats := Stats.depuis_reglages(ReglagesJoueur.rangs_competences_effectifs(),
		ReglagesJoueur.passifs_equipes_effectifs(), ReglagesJoueur.bonus_objets_effectifs(),
		ReglagesJoueur.niveau_compte_effectif())
	var reduction := ArbreCompetences.reduction_degats(ReglagesJoueur.rangs_competences_effectifs())
	return "DÉGÂTS %d   ·   PV %d   ·   CADENCE %.2f/s   ·   RÉDUCTION %d %%" % [
		roundi(stats.degats), roundi(stats.pv_max), stats.cadence, roundi(reduction * 100.0)]

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	InterfaceMobile.dessiner_fond(self, size, false, Palette.ESSENCE, _anim)

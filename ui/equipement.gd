extends Control

signal ferme

const SLOTS := {
	"anneau_gauche": "ANNEAU GAUCHE",
	"anneau_droit": "ANNEAU DROIT",
	"collier": "COLLIER",
}

var _colonne: VBoxContainer
var _pierres: Label
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	StyleInterface.animer_entree(self)
	call_deferred("_animer_slots")
	Capture.programmer(self)

func _animer_slots() -> void:
	if is_instance_valid(_colonne):
		StyleInterface.animer_liste(_colonne, 0.040)

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 54)
	marge.add_theme_constant_override("margin_right", 54)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 205)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 38)
	add_child(marge)
	_colonne = VBoxContainer.new()
	_colonne.add_theme_constant_override("separation", 18)
	marge.add_child(_colonne)
	_pierres = Label.new()
	_pierres.add_theme_font_size_override("font_size", 25)
	_pierres.add_theme_color_override("font_color", Palette.ESSENCE)
	_colonne.add_child(_pierres)
	_reconstruire_slots()
	var retour := Button.new()
	retour.text = "RETOUR"
	retour.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
	retour.add_theme_font_size_override("font_size", 27)
	StyleInterface.styliser_bouton(retour, Palette.TEXTE_ATTENUE, true)
	retour.pressed.connect(func() -> void:
		StyleInterface.sortir_puis(self, func() -> void: ferme.emit()))
	_colonne.add_child(retour)

func _reconstruire_slots() -> void:
	_pierres.text = "PIERRES DE FORGE  •  %d" % ReglagesJoueur.pierres_forge
	for enfant in _colonne.get_children():
		if enfant.has_meta("slot_equipement"):
			enfant.queue_free()
	var insertion := 1
	for slot in SLOTS:
		var panneau := PanelContainer.new()
		panneau.set_meta("slot_equipement", true)
		panneau.add_theme_stylebox_override("panel", StyleInterface.panneau_leger(
			Palette.ESSENCE if slot == "collier" else Palette.OR, 22))
		_colonne.add_child(panneau)
		_colonne.move_child(panneau, insertion)
		insertion += 1
		var contenu := VBoxContainer.new()
		contenu.add_theme_constant_override("separation", 8)
		panneau.add_child(contenu)
		var titre := Label.new()
		titre.text = "%s  •  FORGE NIV. %d" % [SLOTS[slot], int(ReglagesJoueur.forge_niveaux.get(slot, 0))]
		titre.add_theme_font_size_override("font_size", 25)
		contenu.add_child(titre)
		var choix := OptionButton.new()
		choix.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
		StyleInterface.styliser_selecteur(choix, Palette.ESSENCE)
		var ids: Array[String] = []
		for id in ReglagesJoueur.objets_disponibles():
			if CatalogueObjets.compatible(slot, id):
				ids.append(id)
		if ids.is_empty():
			choix.add_item("Aucun objet obtenu")
			choix.disabled = true
		else:
			for id in ids:
				choix.add_item(CatalogueObjets.OBJETS[id]["nom"])
				choix.set_item_metadata(choix.item_count - 1, id)
				if id == ReglagesJoueur.equipements.get(slot, ""):
					choix.select(choix.item_count - 1)
			choix.item_selected.connect(func(index: int) -> void:
				ReglagesJoueur.equiper_objet(slot, str(choix.get_item_metadata(index)))
				_reconstruire_slots())
		contenu.add_child(choix)
		var forge := Button.new()
		forge.text = "AMÉLIORER LE SLOT  •  %d PIERRES" % ReglagesJoueur.cout_forge(slot)
		forge.custom_minimum_size = Vector2(0, Ecran.CIBLE_TACTILE)
		forge.add_theme_font_size_override("font_size", 22)
		forge.disabled = ReglagesJoueur.pierres_forge < ReglagesJoueur.cout_forge(slot)
		StyleInterface.styliser_bouton(forge, Palette.ESSENCE, true)
		forge.pressed.connect(func() -> void:
			if ReglagesJoueur.ameliorer_forge(slot):
				Sons.jouer("choix", -10.0)
				_reconstruire_slots())
		contenu.add_child(forge)
	StyleInterface.animer_rafraichissement(_pierres)

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	StyleInterface.dessiner_fond(self, size, Palette.OR, _anim)
	var haut := Ecran.marge_haute() + 82.0
	StyleInterface.dessiner_entete(self, size, "FORGE ET RELIQUES", "Équipement",
		"Trois emplacements, améliorés définitivement", Palette.OR, haut, true)

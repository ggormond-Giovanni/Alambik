extends Control

signal termine

var etage_recompense := 1
var _recompense := {}
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_recompense = Recompenses.tirer_epreuve(Jeu.rng, ReglagesJoueur.rangs_sorts)
	if _recompense["type"] == "gouttes":
		ReglagesJoueur.ajouter_gouttes(int(_recompense["quantite"]))
	else:
		ReglagesJoueur.debloquer_sort(str(_recompense["id"]))
	_construire()
	StyleInterface.animer_entree(self)
	Capture.programmer(self)
	if Jeu.mode_auto:
		await get_tree().create_timer(0.15).timeout
		_quitter()

func _construire() -> void:
	var accent := Palette.ESSENCE if _recompense["type"] == "gouttes" else Palette.OR
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	InterfaceMobile.appliquer_marges(marge, 0.0, true)
	add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 18)
	colonne.alignment = BoxContainer.ALIGNMENT_CENTER
	marge.add_child(colonne)

	var entete := PanelContainer.new()
	entete.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, true))
	colonne.add_child(entete)
	var titres := VBoxContainer.new()
	entete.add_child(titres)
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 20, Palette.OR, true)
	surtitre.text = "VICTOIRE %d / 5" % etage_recompense
	titres.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 36, Palette.TEXTE, true)
	titre.text = "RÉCOMPENSE DU MINIBOSS"
	titres.add_child(titre)

	var carte := PanelContainer.new()
	carte.custom_minimum_size.y = 410.0
	carte.add_theme_stylebox_override("panel", InterfaceMobile.panneau(accent, true))
	colonne.add_child(carte)
	var contenu := VBoxContainer.new()
	contenu.alignment = BoxContainer.ALIGNMENT_CENTER
	contenu.add_theme_constant_override("separation", 16)
	carte.add_child(contenu)
	var glyphe := InterfaceMobile.styliser_label(Label.new(), 74, accent, true)
	glyphe.text = "✦"
	contenu.add_child(glyphe)
	if _recompense["type"] == "gouttes":
		var nom := InterfaceMobile.styliser_label(Label.new(), 38, Palette.ESSENCE, true)
		nom.text = "+%d GOUTTES D'ESSENCE" % int(_recompense["quantite"])
		contenu.add_child(nom)
		var desc := InterfaceMobile.styliser_label(Label.new(), 23, Palette.TEXTE_ATTENUE, true)
		desc.text = "La récompense a été ajoutée à votre réserve."
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contenu.add_child(desc)
	else:
		var id := str(_recompense["id"])
		var donnees := Sorts.donnees(id)
		var nom := InterfaceMobile.styliser_label(Label.new(), 38, Palette.OR, true)
		nom.text = str(donnees["nom"]).to_upper()
		contenu.add_child(nom)
		var desc := InterfaceMobile.styliser_label(Label.new(), 23, Palette.TEXTE_ATTENUE, true)
		desc.text = str(donnees["description"])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size.y = 72.0
		contenu.add_child(desc)
		var meta := InterfaceMobile.styliser_label(Label.new(), 22, Palette.ESSENCE, true)
		meta.text = "%s  ·  RANG %d / %d  ·  %d %%" % [str(_recompense["type"]).to_upper(),
			ReglagesJoueur.rang_sort(id), Reglages.CAPACITE_RANG_MAX,
			roundi(ReglagesJoueur.efficacite_sort(id) * 100.0)]
		contenu.add_child(meta)

	var continuer := Button.new()
	continuer.text = "CONTINUER LE DÉFI" if etage_recompense < Jeu.salles_du_chapitre() else "TERMINER LE DÉFI"
	continuer.custom_minimum_size.y = 108.0
	InterfaceMobile.styliser_bouton(continuer, accent, true)
	continuer.pressed.connect(_quitter)
	colonne.add_child(continuer)

func _quitter() -> void:
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	var accent := Palette.ESSENCE if _recompense.get("type", "") == "gouttes" else Palette.OR
	InterfaceMobile.dessiner_fond(self, size, false, accent, _anim)

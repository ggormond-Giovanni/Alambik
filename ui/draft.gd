extends Control

signal termine

const COULEURS := [Color("aa55ff"), Color("78dd45"), Color("ffac28")]

var _choisi := false
var _propositions: Array[String] = []
var _cartes: VBoxContainer
var _bouton_reroll: Button
var _anim := 0.0
var etage_recompense := 1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_interface()
	_nouveau_tirage()
	StyleInterface.animer_entree(self, 18.0)
	Capture.programmer(self)
	if Jeu.mode_auto:
		_choisir_automatiquement()

func _construire_interface() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	InterfaceMobile.appliquer_marges(marge, 0.0, true)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	marge.add_child(colonne)

	var entete := PanelContainer.new()
	entete.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, true))
	colonne.add_child(entete)
	var titres := VBoxContainer.new()
	entete.add_child(titres)
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 19, Palette.OR, true)
	surtitre.text = "NIVEAU %d — RÉCOMPENSE" % etage_recompense
	titres.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 36, Palette.TEXTE, true)
	titre.text = "CHOISISSEZ UNE AMÉLIORATION"
	titres.add_child(titre)
	var aide := InterfaceMobile.styliser_label(Label.new(), 20, Palette.TEXTE_ATTENUE, true)
	aide.text = "Une seule carte rejoint la run."
	titres.add_child(aide)

	var defilement := ScrollContainer.new()
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(defilement)
	_cartes = VBoxContainer.new()
	_cartes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cartes.add_theme_constant_override("separation", 12)
	defilement.add_child(_cartes)

	_bouton_reroll = Button.new()
	_bouton_reroll.custom_minimum_size.y = 96.0
	InterfaceMobile.styliser_bouton(_bouton_reroll, Retro16.VIOLET, false)
	_bouton_reroll.pressed.connect(_sur_reroll)
	colonne.add_child(_bouton_reroll)

func _nouveau_tirage() -> void:
	_propositions = DraftLogique.proposer(Jeu.inventaire, Jeu.rng)
	if _propositions.is_empty():
		_fermer_sans_choix()
		return
	_rafraichir_cartes()
	_rafraichir_reroll()

func _rafraichir_cartes() -> void:
	for enfant in _cartes.get_children():
		enfant.queue_free()
	for index in mini(3, _propositions.size()):
		var id := _propositions[index]
		var reactif := CatalogueReactifs.par_id(id)
		if reactif == null:
			continue
		var couleur: Color = COULEURS[index]
		var bouton := Button.new()
		bouton.text = "%s\n%s\n%s" % [reactif.nom.to_upper(), _nom_famille(reactif.famille), reactif.description]
		bouton.custom_minimum_size = Vector2(0.0, 218.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		InterfaceMobile.styliser_bouton(bouton, couleur, index == 1)
		bouton.add_theme_font_size_override("font_size", 22)
		bouton.pressed.connect(func() -> void: _sur_choix(id))
		_cartes.add_child(bouton)
	if not ReglagesJoueur.effets_reduits:
		call_deferred("_animer_cartes")

func _animer_cartes() -> void:
	if is_instance_valid(_cartes):
		StyleInterface.animer_liste(_cartes, 0.06)

func _sur_reroll() -> void:
	if _choisi or Jeu.rerolls_restants <= 0:
		return
	_bouton_reroll.disabled = true
	Sons.jouer("choix", -13.0)
	Jeu.rerolls_restants -= 1
	_nouveau_tirage()

func _rafraichir_reroll() -> void:
	if _bouton_reroll == null:
		return
	_bouton_reroll.disabled = Jeu.rerolls_restants <= 0
	_bouton_reroll.text = "NOUVEAU TIRAGE  ·  %d RESTANT%s" % [
		Jeu.rerolls_restants, "" if Jeu.rerolls_restants == 1 else "S"]
	InterfaceMobile.styliser_bouton(_bouton_reroll,
		Retro16.VIOLET if Jeu.rerolls_restants > 0 else Palette.BORD_PAGE, false)

func _sur_choix(id: String) -> void:
	if _choisi:
		return
	_choisi = true
	Jeu.ajouter_reactif(id)
	Sons.jouer("choix", -10.0)
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _fermer_sans_choix() -> void:
	if _choisi:
		return
	_choisi = true
	StyleInterface.sortir_puis(self, func() -> void: termine.emit())

func _choisir_automatiquement() -> void:
	await get_tree().create_timer(0.12).timeout
	if not _choisi and not _propositions.is_empty():
		_sur_choix(_propositions[0])

func _nom_famille(famille: String) -> String:
	match famille:
		CatalogueReactifs.PROJECTILE: return "PROJECTILE"
		CatalogueReactifs.HEROS: return "SURVIE"
	return "PHÉNOMÈNE"

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	InterfaceMobile.dessiner_fond(self, size, false, Retro16.VIOLET, _anim)

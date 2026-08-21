extends Control

signal ferme
signal selection_changee

const TRANSITION := preload("res://ui/transition_grimoire.tscn")

var selection_seulement := false
var _monde := 0
var _chapitre_monde := 0
var _message := ""
var _lancement := false
var _anim := 0.0
var _titre_monde: Label
var _chapitres: VBoxContainer
var _details: VBoxContainer
var _message_label: Label
var _bouton_selectionner: Button
var _precedent: Button
var _suivant: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_monde = clampi(ReglagesJoueur.chapitre_choisi / 3, 0, Chapitres.MONDES.size() - 1)
	_chapitre_monde = posmod(ReglagesJoueur.chapitre_choisi, 3)
	_construire_interface()
	_rafraichir()
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire_interface() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	InterfaceMobile.appliquer_marges(marge, 0.0, true)
	add_child(marge)
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.OR, true))
	marge.add_child(panneau)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 14)
	panneau.add_child(colonne)

	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 10)
	colonne.add_child(entete)
	_precedent = Button.new()
	_precedent.text = "‹"
	_precedent.custom_minimum_size = Vector2(92.0, 88.0)
	InterfaceMobile.styliser_bouton(_precedent, Palette.ESSENCE, false)
	_precedent.pressed.connect(func() -> void: _changer_monde(-1))
	entete.add_child(_precedent)
	var titres := VBoxContainer.new()
	titres.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(titres)
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 19, Palette.OR, true)
	surtitre.text = "CAMPAGNE DU GRIMOIRE"
	titres.add_child(surtitre)
	_titre_monde = InterfaceMobile.styliser_label(Label.new(), 31, Palette.TEXTE, true)
	titres.add_child(_titre_monde)
	_suivant = Button.new()
	_suivant.text = "›"
	_suivant.custom_minimum_size = Vector2(92.0, 88.0)
	InterfaceMobile.styliser_bouton(_suivant, Palette.ESSENCE, false)
	_suivant.pressed.connect(func() -> void: _changer_monde(1))
	entete.add_child(_suivant)

	var defilement := ScrollContainer.new()
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(defilement)
	var contenu := VBoxContainer.new()
	contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenu.add_theme_constant_override("separation", 12)
	defilement.add_child(contenu)
	_chapitres = VBoxContainer.new()
	_chapitres.add_theme_constant_override("separation", 10)
	contenu.add_child(_chapitres)
	var bloc_details := PanelContainer.new()
	bloc_details.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.ESSENCE, false))
	contenu.add_child(bloc_details)
	_details = VBoxContainer.new()
	_details.add_theme_constant_override("separation", 10)
	bloc_details.add_child(_details)

	_message_label = InterfaceMobile.styliser_label(Label.new(), 20, Palette.DANGER.lightened(0.22), true)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.custom_minimum_size.y = 44.0
	colonne.add_child(_message_label)
	_bouton_selectionner = Button.new()
	_bouton_selectionner.custom_minimum_size.y = 104.0
	_bouton_selectionner.text = "CHOISIR CE CHAPITRE" if selection_seulement else "ENTRER DANS LE GRIMOIRE"
	InterfaceMobile.styliser_bouton(_bouton_selectionner, Palette.OR, true)
	_bouton_selectionner.pressed.connect(_selectionner)
	colonne.add_child(_bouton_selectionner)
	var fermer := Button.new()
	fermer.text = "RETOUR"
	fermer.custom_minimum_size.y = 82.0
	InterfaceMobile.styliser_bouton(fermer, Palette.ESSENCE, false)
	fermer.pressed.connect(_fermer)
	colonne.add_child(fermer)

func _index_selectionne() -> int:
	return _monde * 3 + _chapitre_monde

func _changer_monde(direction: int) -> void:
	var nouveau := clampi(_monde + direction, 0, Chapitres.MONDES.size() - 1)
	if nouveau == _monde:
		return
	_monde = nouveau
	_message = ""
	Sons.jouer("choix", -16.0, 1.0 + float(direction) * 0.04)
	_rafraichir()

func _choisir_chapitre(index: int) -> void:
	_chapitre_monde = clampi(index, 0, 2)
	var chapitre := _index_selectionne()
	_message = "" if ReglagesJoueur.chapitre_debloque(chapitre) else "Ce chapitre est encore verrouillé."
	Sons.jouer("choix", -16.0)
	_rafraichir()

func _selectionner() -> void:
	var index := _index_selectionne()
	if not ReglagesJoueur.chapitre_debloque(index):
		_message = "Terminez le chapitre précédent pour ouvrir celui-ci."
		_rafraichir()
		return
	ReglagesJoueur.choisir_mode_run("grimoire")
	ReglagesJoueur.choisir_chapitre(index)
	Sons.jouer("choix", -10.0)
	if selection_seulement:
		selection_changee.emit()
		StyleInterface.sortir_puis(self, func() -> void: ferme.emit())
		return
	_lancer_chapitre(index)

func _lancer_chapitre(index: int) -> void:
	if _lancement:
		return
	_lancement = true
	Sons.demarrer_musique_combat()
	var transition := TRANSITION.instantiate()
	transition.configurer(Chapitres.par_index(index))
	add_child(transition)
	move_child(transition, get_child_count() - 1)
	transition.terminee.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/run.tscn"))

func _fermer() -> void:
	if _lancement:
		return
	Sons.jouer("choix", -14.0)
	StyleInterface.sortir_puis(self, func() -> void: ferme.emit())

func _rafraichir() -> void:
	var monde: Dictionary = Chapitres.MONDES[_monde]
	_titre_monde.text = "MONDE %s — %s" % [monde["numero"], str(monde["nom"]).to_upper()]
	_precedent.disabled = _monde <= 0
	_suivant.disabled = _monde >= Chapitres.MONDES.size() - 1
	_rafraichir_chapitres(monde)
	_rafraichir_details(monde)
	_message_label.text = _message
	_bouton_selectionner.disabled = not ReglagesJoueur.chapitre_debloque(_index_selectionne())
	InterfaceMobile.styliser_bouton(_bouton_selectionner, Color(monde["teinte"]), not _bouton_selectionner.disabled)
	queue_redraw()

func _rafraichir_chapitres(monde: Dictionary) -> void:
	for enfant in _chapitres.get_children():
		enfant.queue_free()
	for local in 3:
		var index_global := _monde * 3 + local
		var chapitre := Chapitres.par_index(index_global)
		var ouvert := ReglagesJoueur.chapitre_debloque(index_global)
		var progression := ReglagesJoueur.meilleure_du_chapitre(index_global)
		var bouton := Button.new()
		var etat := "%d / %d SALLES" % [progression, Reglages.SALLES_PAR_RUN] if ouvert else "VERROUILLÉ"
		bouton.text = "CHAPITRE %d — %s\n%s" % [local + 1, str(chapitre["sous_titre"]), etat]
		bouton.custom_minimum_size.y = 118.0
		var selectionne := local == _chapitre_monde
		InterfaceMobile.styliser_bouton(bouton,
			Color(monde["teinte"]) if ouvert else Palette.BORD_PAGE, selectionne)
		bouton.add_theme_font_size_override("font_size", 20)
		bouton.pressed.connect(func() -> void: _choisir_chapitre(local))
		_chapitres.add_child(bouton)

func _rafraichir_details(monde: Dictionary) -> void:
	for enfant in _details.get_children():
		enfant.queue_free()
	var index := _index_selectionne()
	var chapitre := Chapitres.par_index(index)
	var boss: Dictionary = CatalogueEnnemis.par_id(str(chapitre["boss"]))
	var titre := InterfaceMobile.styliser_label(Label.new(), 28, Color(monde["teinte"]), true)
	titre.text = "CHAPITRE %d" % (_chapitre_monde + 1)
	_details.add_child(titre)
	var sous_titre := InterfaceMobile.styliser_label(Label.new(), 22, Palette.TEXTE, true)
	sous_titre.text = str(chapitre["sous_titre"])
	sous_titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.add_child(sous_titre)
	var gardien := InterfaceMobile.styliser_label(Label.new(), 20, Palette.OR, true)
	gardien.text = "GARDIEN : %s" % str(boss.get("nom", "Inconnu")).to_upper()
	_details.add_child(gardien)
	var infos := InterfaceMobile.styliser_label(Label.new(), 20, Palette.TEXTE_ATTENUE, true)
	infos.text = "Progression %d/%d   ·   3 Alambics   ·   4 Gardiens" % [
		ReglagesJoueur.meilleure_du_chapitre(index), Reglages.SALLES_PAR_RUN]
	_details.add_child(infos)

func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_WM_GO_BACK_REQUEST:
		_fermer()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	var monde: Dictionary = Chapitres.MONDES[_monde]
	InterfaceMobile.dessiner_fond(self, size, false, Color(monde["teinte"]), _anim)

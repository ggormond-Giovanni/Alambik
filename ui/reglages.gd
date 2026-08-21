extends Control

signal ferme

const ONGLETS := ["audio", "visuel", "accessibilite", "developpement"]
const NOMS_ONGLETS := {
	"audio": "AUDIO",
	"visuel": "VISUEL",
	"accessibilite": "ACCESSIBILITÉ",
	"developpement": "DÉVELOPPEMENT",
}

var _anim := 0.0
var _onglet := "audio"
var _contenu: VBoxContainer
var _boutons_onglets: Dictionary = {}
var _bouton_reset: Button
var _confirmation_reset := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_interface()
	var onglet_initial := "audio"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--onglet-reglages="):
			var demande := argument.trim_prefix("--onglet-reglages=")
			if demande in ONGLETS:
				onglet_initial = demande
	_afficher_onglet(onglet_initial)
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire_interface() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	InterfaceMobile.appliquer_marges(marge, 0.0, true)
	add_child(marge)

	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau(Palette.ESSENCE, true))
	marge.add_child(panneau)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 18)
	panneau.add_child(colonne)

	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 14)
	colonne.add_child(entete)
	var bloc_titre := VBoxContainer.new()
	bloc_titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(bloc_titre)
	var surtitre := InterfaceMobile.styliser_label(Label.new(), 19, Palette.ESSENCE)
	surtitre.text = "OPTIONS DU GRIMOIRE"
	bloc_titre.add_child(surtitre)
	var titre := InterfaceMobile.styliser_label(Label.new(), 38, Palette.TEXTE)
	titre.text = "RÉGLAGES"
	bloc_titre.add_child(titre)
	var fermer := Button.new()
	fermer.text = "FERMER"
	fermer.custom_minimum_size = Vector2(160.0, 92.0)
	InterfaceMobile.styliser_bouton(fermer, Palette.OR, false)
	fermer.pressed.connect(_fermer)
	entete.add_child(fermer)

	var onglets := GridContainer.new()
	onglets.columns = 2
	onglets.add_theme_constant_override("h_separation", 10)
	onglets.add_theme_constant_override("v_separation", 10)
	colonne.add_child(onglets)
	for id in ONGLETS:
		var bouton := Button.new()
		bouton.text = str(NOMS_ONGLETS[id])
		bouton.custom_minimum_size = Vector2(0.0, 86.0)
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.pressed.connect(func() -> void: _afficher_onglet(id))
		onglets.add_child(bouton)
		_boutons_onglets[id] = bouton

	var separateur := HSeparator.new()
	colonne.add_child(separateur)

	var defilement := ScrollContainer.new()
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colonne.add_child(defilement)
	_contenu = VBoxContainer.new()
	_contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenu.add_theme_constant_override("separation", 12)
	defilement.add_child(_contenu)

	_bouton_reset = Button.new()
	_bouton_reset.text = "RÉINITIALISER LA PROGRESSION"
	_bouton_reset.custom_minimum_size.y = 94.0
	InterfaceMobile.styliser_bouton(_bouton_reset, Palette.DANGER, false)
	_bouton_reset.pressed.connect(_sur_reset)
	colonne.add_child(_bouton_reset)

func _fermer() -> void:
	Sons.jouer("choix", -14.0)
	StyleInterface.sortir_puis(self, func() -> void: ferme.emit())

func _afficher_onglet(id: String) -> void:
	if not id in ONGLETS:
		return
	_onglet = id
	_vide_contenu()
	for cle in _boutons_onglets:
		var actif := str(cle) == id
		InterfaceMobile.styliser_bouton(_boutons_onglets[cle],
			Palette.OR if actif else Palette.ESSENCE, actif)
	match id:
		"audio": _construire_audio()
		"visuel": _construire_visuel()
		"accessibilite": _construire_accessibilite()
		"developpement": _construire_developpement()
	Sons.jouer("choix", -18.0)

func _vide_contenu() -> void:
	for enfant in _contenu.get_children():
		_contenu.remove_child(enfant)
		enfant.queue_free()

func _construire_audio() -> void:
	_ajouter_volume("VOLUME DE LA MUSIQUE", ReglagesJoueur.volume_musique,
		func(v: float) -> void:
			ReglagesJoueur.definir_reglages_audio(v, ReglagesJoueur.volume_effets))
	_ajouter_selecteur_musique()
	_ajouter_volume("VOLUME DES EFFETS", ReglagesJoueur.volume_effets,
		func(v: float) -> void:
			ReglagesJoueur.definir_reglages_audio(ReglagesJoueur.volume_musique, v))
	_ajouter_information("APPLICATION IMMÉDIATE",
		"Les changements sont entendus et sauvegardés sans relancer le jeu.", Palette.ESSENCE)

func _construire_visuel() -> void:
	_ajouter_option("SECOUSSES D’ÉCRAN", ReglagesJoueur.secousses_ecran,
		func(v: bool) -> void:
			ReglagesJoueur.definir_accessibilite(v, ReglagesJoueur.effets_reduits))
	_ajouter_option("EFFETS VISUELS COMPLETS", not ReglagesJoueur.effets_reduits,
		func(v: bool) -> void:
			ReglagesJoueur.definir_accessibilite(ReglagesJoueur.secousses_ecran, not v))
	_ajouter_information("PIXEL ART NET",
		"Les sprites restent en nearest-neighbour et les effets ne doivent pas flouter les hitboxes.", Palette.OR)
	_ajouter_information("INTERFACE ADAPTATIVE",
		"Les panneaux et contrôles suivent désormais la zone sûre du téléphone au lieu d'être gravés dans une image.", Palette.ESSENCE)

func _construire_accessibilite() -> void:
	_ajouter_option("ANIMATIONS ET FLASHES RÉDUITS", ReglagesJoueur.effets_reduits,
		func(v: bool) -> void:
			ReglagesJoueur.definir_accessibilite(ReglagesJoueur.secousses_ecran, v))
	_ajouter_raccourci_sort()
	_ajouter_information("JOYSTICK FLOTTANT",
		"Il apparaît sous le pouce dans la moitié basse de l'écran.", Palette.ESSENCE)
	_ajouter_information("SAFE AREA",
		"Les commandes essentielles évitent l'encoche et la barre de navigation Android.", Palette.OR)

func _construire_developpement() -> void:
	_ajouter_option("MODE DEV — TOUT DÉBLOQUER", ReglagesJoueur.mode_dev,
		func(v: bool) -> void: ReglagesJoueur.definir_mode_dev(v))
	_ajouter_information("CONTENU DÉVERROUILLÉ",
		"Révèle chapitres, objets, sorts et maîtrises pour les essais.", Palette.ESSENCE)
	_ajouter_information("SAUVEGARDE LOCALE",
		"Les réglages restent enregistrés sur cet appareil.", Palette.OR)
	_ajouter_information("ZONE DANGEREUSE",
		"La réinitialisation complète demande toujours une seconde confirmation.", Palette.DANGER)

func _creer_carte(accent := Palette.ESSENCE) -> VBoxContainer:
	var panneau := PanelContainer.new()
	panneau.add_theme_stylebox_override("panel", InterfaceMobile.panneau_leger(accent))
	_contenu.add_child(panneau)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 8)
	panneau.add_child(colonne)
	return colonne

func _ajouter_volume(titre: String, valeur: float, changement: Callable) -> void:
	var carte := _creer_carte(Palette.ESSENCE)
	var ligne := HBoxContainer.new()
	carte.add_child(ligne)
	var etiquette := InterfaceMobile.styliser_label(Label.new(), 25, Palette.TEXTE)
	etiquette.text = titre
	etiquette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(etiquette)
	var valeur_label := InterfaceMobile.styliser_label(Label.new(), 24, Palette.ESSENCE, true)
	valeur_label.text = "%d %%" % roundi(valeur * 100.0)
	valeur_label.custom_minimum_size.x = 110.0
	ligne.add_child(valeur_label)
	var curseur := HSlider.new()
	curseur.custom_minimum_size.y = 58.0
	curseur.min_value = 0.0
	curseur.max_value = 1.0
	curseur.step = 0.05
	curseur.value = valeur
	StyleInterface.styliser_curseur(curseur, Palette.ESSENCE)
	curseur.value_changed.connect(func(v: float) -> void:
		valeur_label.text = "%d %%" % roundi(v * 100.0)
		changement.call(v))
	carte.add_child(curseur)

func _ajouter_selecteur_musique() -> void:
	var carte := _creer_carte(Palette.OR)
	var titre := InterfaceMobile.styliser_label(Label.new(), 25, Palette.TEXTE)
	titre.text = "MUSIQUE DU COMBAT"
	carte.add_child(titre)
	var selecteur := OptionButton.new()
	selecteur.custom_minimum_size.y = 76.0
	StyleInterface.styliser_selecteur(selecteur, Palette.OR)
	var pistes := Sons.pistes_disponibles()
	for index in pistes.size():
		var piste: Dictionary = pistes[index]
		selecteur.add_item(str(piste["nom"]))
		selecteur.set_item_metadata(index, str(piste["id"]))
		if str(piste["id"]) == ReglagesJoueur.piste_musique:
			selecteur.selected = index
	selecteur.item_selected.connect(func(index: int) -> void:
		ReglagesJoueur.definir_piste_musique(str(selecteur.get_item_metadata(index))))
	carte.add_child(selecteur)

func _ajouter_option(titre: String, valeur: bool, changement: Callable) -> void:
	var carte := _creer_carte(Palette.ESSENCE if valeur else Palette.BORD_PAGE)
	var bouton := Button.new()
	bouton.toggle_mode = true
	bouton.button_pressed = valeur
	bouton.custom_minimum_size.y = 92.0
	bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	InterfaceMobile.styliser_bouton(bouton, Palette.ESSENCE, valeur)
	_actualiser_option(bouton, titre, valeur)
	bouton.toggled.connect(func(v: bool) -> void:
		_actualiser_option(bouton, titre, v)
		InterfaceMobile.styliser_bouton(bouton, Palette.ESSENCE, v)
		changement.call(v))
	carte.add_child(bouton)

func _actualiser_option(bouton: Button, titre: String, valeur: bool) -> void:
	bouton.text = "%s    ·    %s" % [titre, "ACTIVÉ" if valeur else "DÉSACTIVÉ"]

func _ajouter_raccourci_sort() -> void:
	var carte := _creer_carte(Palette.ESSENCE)
	var titre := InterfaceMobile.styliser_label(Label.new(), 25, Palette.TEXTE)
	titre.text = "RACCOURCI DU SORT ACTIF"
	carte.add_child(titre)
	var selecteur := OptionButton.new()
	selecteur.custom_minimum_size.y = 76.0
	StyleInterface.styliser_selecteur(selecteur, Palette.ESSENCE)
	for index in RaccourciTactile.MODES.size():
		var mode: String = RaccourciTactile.MODES[index]
		selecteur.add_item(RaccourciTactile.nom_mode(mode))
		selecteur.set_item_metadata(index, mode)
		if mode == ReglagesJoueur.raccourci_sort:
			selecteur.selected = index
	selecteur.item_selected.connect(func(index: int) -> void:
		ReglagesJoueur.definir_raccourci_sort(str(selecteur.get_item_metadata(index))))
	carte.add_child(selecteur)

func _ajouter_information(titre: String, texte: String, accent: Color) -> void:
	var carte := _creer_carte(accent)
	var titre_label := InterfaceMobile.styliser_label(Label.new(), 24, accent.lightened(0.16))
	titre_label.text = titre
	carte.add_child(titre_label)
	var texte_label := InterfaceMobile.styliser_label(Label.new(), 21, Palette.TEXTE_ATTENUE)
	texte_label.text = texte
	texte_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texte_label.custom_minimum_size.y = 54.0
	carte.add_child(texte_label)

func _sur_reset() -> void:
	if not _confirmation_reset:
		_confirmation_reset = true
		_bouton_reset.text = "TOUCHER À NOUVEAU POUR CONFIRMER"
		InterfaceMobile.styliser_bouton(_bouton_reset, Palette.DANGER, true)
		_attendre_confirmation_reset()
		return
	_confirmation_reset = false
	ReglagesJoueur.reinitialiser_progression()
	_bouton_reset.disabled = true
	_bouton_reset.text = "PROGRESSION RÉINITIALISÉE"
	Sons.jouer("choix", -10.0, 0.75)

func _attendre_confirmation_reset() -> void:
	await get_tree().create_timer(4.0, true).timeout
	if not is_inside_tree() or not _confirmation_reset:
		return
	_confirmation_reset = false
	_bouton_reset.text = "RÉINITIALISER LA PROGRESSION"
	InterfaceMobile.styliser_bouton(_bouton_reset, Palette.DANGER, false)

func _notification(quoi: int) -> void:
	if quoi == NOTIFICATION_WM_GO_BACK_REQUEST:
		_fermer()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	InterfaceMobile.dessiner_fond(self, size, false, Palette.ESSENCE, _anim)

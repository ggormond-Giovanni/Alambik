extends Control

signal ferme
signal selection_changee

const FOND := preload("res://assets/visual/campagne_premium.png")
const HAUT_FIXE := 1580.0
const BAS_FIXE := 340.0
const TRANSITION := preload("res://ui/transition_grimoire.tscn")
const RECTS_CHAPITRES := [Rect2(45, 1082, 310, 150), Rect2(385, 1082, 310, 150), Rect2(725, 1082, 310, 150)]

var selection_seulement := false
var _monde := 0
var _chapitre_monde := 0
var _message := ""
var _lancement := false
var _zones_chapitres: Array[Button] = []
var _bouton_selectionner: Button
var _balayage := BalayagePages.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_monde = clampi(ReglagesJoueur.chapitre_choisi / 3, 0, Chapitres.MONDES.size() - 1)
	_chapitre_monde = posmod(ReglagesJoueur.chapitre_choisi, 3)
	_construire_zones()
	resized.connect(_replacer_zones)
	_replacer_zones()
	_rafraichir()
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire_zones() -> void:
	_zone(Rect2(922, 30, 120, 125), _fermer)
	_zone(Rect2(165, 225, 115, 130), func() -> void: _changer_monde(-1))
	_zone(Rect2(800, 225, 115, 130), func() -> void: _changer_monde(1))
	for index in 3:
		_zones_chapitres.append(_zone(RECTS_CHAPITRES[index], func() -> void: _choisir_chapitre(index)))
	_bouton_selectionner = _zone(Rect2(145, 1600, 790, 175), _selectionner)
	_zone(Rect2(315, 1795, 450, 105), _fermer)

func _zone(reference: Rect2, action: Callable) -> Button:
	var bouton := StyleInterface.zone_tactile()
	bouton.set_meta("reference", reference)
	# Un balayage relache son doigt sur une case : sans ce garde-fou il
	# choisirait aussi le chapitre ou le geste s'arrete.
	bouton.pressed.connect(func() -> void:
		if not _balayage.a_balaye():
			action.call())
	add_child(bouton)
	return bouton

func _input(evenement: InputEvent) -> void:
	if not is_visible_in_tree() or _lancement:
		return
	if evenement is InputEventScreenTouch:
		if evenement.pressed:
			_balayage.appuyer(evenement.position)
		else:
			_balayage.relacher()
	elif evenement is InputEventScreenDrag:
		var sens := _balayage.deplacer(evenement.position, size.x)
		if sens != 0:
			_changer_monde(sens)

func _replacer_zones() -> void:
	for enfant in get_children():
		if enfant is Button and enfant.has_meta("reference"):
			var r: Rect2 = enfant.get_meta("reference")
			var adapte := FondAdaptatif.rect(size, FOND, r, HAUT_FIXE, BAS_FIXE)
			enfant.position = adapte.position
			enfant.size = adapte.size

func _index_selectionne() -> int:
	return _monde * 3 + _chapitre_monde

func _changer_monde(direction: int) -> void:
	var nouveau := clampi(_monde + direction, 0, Chapitres.MONDES.size() - 1)
	if nouveau == _monde:
		return
	_monde = nouveau
	_message = ""
	# Conserver le numero de chapitre rend la comparaison entre mondes naturelle.
	# Si celui-ci est verrouille, la fiche le dit sans modifier le choix en cachette.
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
	transition.terminee.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/run.tscn"))

func _fermer() -> void:
	if _lancement:
		return
	Sons.jouer("choix", -14.0)
	StyleInterface.sortir_puis(self, func() -> void: ferme.emit())

func _rafraichir() -> void:
	var index := _index_selectionne()
	_bouton_selectionner.disabled = not ReglagesJoueur.chapitre_debloque(index)
	queue_redraw()

func _draw() -> void:
	FondAdaptatif.dessiner_premium(self, FOND, size, HAUT_FIXE, BAS_FIXE)
	var sx := size.x / 1080.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * sx)
	var police := Polices.CORPS
	var monde: Dictionary = Chapitres.MONDES[_monde]
	var chapitre := Chapitres.par_index(_index_selectionne())
	_draw_centre(police, Vector2(290, 306), 500, "MONDE %s — %s" % [monde["numero"], str(monde["nom"]).to_upper()], 29, Palette.TEXTE)
	if _monde == 0:
		draw_rect(Rect2(165, 225, 115, 130).grow(-12.0), Color(0, 0, 0, 0.42))
	if _monde == Chapitres.MONDES.size() - 1:
		draw_rect(Rect2(800, 225, 115, 130).grow(-12.0), Color(0, 0, 0, 0.42))
	for local in 3:
		var index_global := _monde * 3 + local
		var r: Rect2 = RECTS_CHAPITRES[local]
		var ouvert := ReglagesJoueur.chapitre_debloque(index_global)
		if local == _chapitre_monde:
			draw_rect(r.grow(-9.0), Color(monde["teinte"], 0.16))
		if not ouvert:
			draw_rect(r.grow(-9.0), Color(0, 0, 0, 0.50))
			_draw_centre(police, Vector2(r.position.x, r.position.y + 126), r.size.x, "VERROUILLÉ", 18, Palette.TEXTE_ATTENUE)
		else:
			var progression := ReglagesJoueur.meilleure_du_chapitre(index_global)
			_draw_centre(police, Vector2(r.position.x, r.position.y + 126), r.size.x, "%d / %d SALLES" % [progression, Reglages.SALLES_PAR_RUN], 18, Palette.TEXTE_ATTENUE)
	_dessiner_details(police, chapitre, monde)
	if _bouton_selectionner.disabled:
		var bloque := FondAdaptatif.rect(size, FOND, Rect2(145, 1600, 790, 175),
			HAUT_FIXE, BAS_FIXE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(bloque.grow(-13.0 * sx), Color(0, 0, 0, 0.55))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * sx)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _dessiner_details(police: Font, chapitre: Dictionary, monde: Dictionary) -> void:
	var index := _index_selectionne()
	var ouvert := ReglagesJoueur.chapitre_debloque(index)
	_draw_centre(police, Vector2(72, 1310), 410, "CHAPITRE %d" % (_chapitre_monde + 1), 28, Color(monde["teinte"]))
	draw_multiline_string(police, Vector2(82, 1365), str(chapitre["sous_titre"]), HORIZONTAL_ALIGNMENT_CENTER, 390, 22, 3, Palette.TEXTE)
	var boss: Dictionary = CatalogueEnnemis.par_id(str(chapitre["boss"]))
	_draw_centre(police, Vector2(72, 1495), 410, "GARDIEN : %s" % str(boss.get("nom", "Inconnu")).to_upper(), 19, Palette.TEXTE_ATTENUE)
	var valeurs := [
		[1, "%d / %d" % [ReglagesJoueur.meilleure_du_chapitre(index), Reglages.SALLES_PAR_RUN], "PROGRESSION"],
		[5, "3", "ALAMBICS"],
		[6, "4", "GARDIENS"],
	]
	for i in 3:
		var centre := Vector2(615 + i * 130, 1380)
		Retro16.dessiner_icone_interface(self, valeurs[i][0], Rect2(centre - Vector2(42, 42), Vector2(84, 84)), Color.WHITE if ouvert else Color(0.4, 0.4, 0.45))
		_draw_centre(police, Vector2(centre.x - 58, 1460), 116, str(valeurs[i][1]) if ouvert else "—", 21, Palette.TEXTE)
		_draw_centre(police, Vector2(centre.x - 60, 1495), 120, str(valeurs[i][2]), 15, Palette.TEXTE_ATTENUE)
	if not _message.is_empty():
		_draw_centre(police, Vector2(100, 1570), 880, _message, 20, Palette.DANGER.lightened(0.25))

func _draw_centre(police: Font, position: Vector2, largeur: float, texte: String,
		taille_police: int, couleur: Color) -> void:
	draw_string(police, position, texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille_police, couleur)

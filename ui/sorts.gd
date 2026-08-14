extends Control

signal ferme

const FOND := preload("res://assets/visual/sorts_premium.png")
const HAUT_FIXE := 1740.0
const BAS_FIXE := 180.0
const CATEGORIES := ["Actifs", "Passifs", "Ultimes"]
const COULEURS := {
	"Actifs": Color(1.0, 0.55, 0.24),
	"Passifs": Color(0.38, 0.86, 0.70),
	"Ultimes": Color(0.70, 0.54, 1.0),
}
const RECTS_CATEGORIES := [Rect2(55, 405, 320, 100), Rect2(380, 405, 320, 100), Rect2(705, 405, 320, 100)]
const RECTS_CARTES := [
	Rect2(38, 525, 490, 300), Rect2(552, 525, 490, 300),
	Rect2(38, 850, 490, 300), Rect2(552, 850, 490, 300),
	Rect2(38, 1175, 490, 300), Rect2(552, 1175, 490, 300),
]
const CENTRES_EQUIPES := [Vector2(205, 245), Vector2(430, 245), Vector2(655, 245), Vector2(880, 245)]

var integre_menu := false
var _categorie := "Actifs"
var _page := 0
var _balayage := BalayagePages.new()
var _message := ""
var _onglets: Array[Button] = []
var _cartes: Array[Button] = []
var _slots_equipes: Array[Button] = []
var _precedent: Button
var _suivant: Button
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_zones()
	_afficher("Actifs")
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire_zones() -> void:
	for index in CATEGORIES.size():
		_onglets.append(_zone(RECTS_CATEGORIES[index], func() -> void: _afficher(CATEGORIES[index])))
	for index in 6:
		_cartes.append(_zone(RECTS_CARTES[index], func() -> void: _choisir_index(index)))
	for index in 4:
		var centre: Vector2 = CENTRES_EQUIPES[index]
		_slots_equipes.append(_zone(Rect2(centre - Vector2(95, 100), Vector2(190, 220)),
			func() -> void: _retirer_slot(index)))
	_precedent = _zone(Rect2(55, 1490, 125, 155), func() -> void: _changer_page(-1))
	_suivant = _zone(Rect2(900, 1490, 125, 155), func() -> void: _changer_page(1))
	resized.connect(_replacer_zones)
	_replacer_zones()

func _zone(reference: Rect2, action: Callable) -> Button:
	var bouton := StyleInterface.zone_tactile()
	bouton.set_meta("reference", reference)
	# Un balayage relache son doigt sur une carte : sans ce garde-fou il
	# equiperait la capacite ou le geste s'arrete.
	bouton.pressed.connect(func() -> void:
		if not _balayage.a_balaye():
			action.call())
	add_child(bouton)
	return bouton

func _input(evenement: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if evenement is InputEventScreenTouch:
		if evenement.pressed:
			_balayage.appuyer(evenement.position)
		else:
			_balayage.relacher()
	elif evenement is InputEventScreenDrag:
		var sens := _balayage.deplacer(evenement.position, size.x)
		if sens != 0:
			_changer_page(sens)

func _replacer_zones() -> void:
	for enfant in get_children():
		if enfant is Button and enfant.has_meta("reference"):
			var r: Rect2 = enfant.get_meta("reference")
			var adapte := FondAdaptatif.rect(size, FOND, r, HAUT_FIXE, BAS_FIXE)
			enfant.position = adapte.position
			enfant.size = adapte.size

func _catalogue() -> Dictionary:
	match _categorie:
		"Passifs": return Sorts.PASSIFS
		"Ultimes": return Sorts.ULTIMES
	return Sorts.ACTIFS

func _ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _catalogue(): ids.append(id)
	return ids

func _ids_page() -> Array[String]:
	var ids := _ids()
	var debut := _page * 6
	var resultat: Array[String] = []
	for index in range(debut, mini(debut + 6, ids.size())):
		resultat.append(ids[index])
	return resultat

func _afficher(categorie: String) -> void:
	if categorie == _categorie and _page == 0:
		return
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

func _choisir_index(index: int) -> void:
	var ids := _ids_page()
	if index >= ids.size():
		return
	var id := ids[index]
	if not ReglagesJoueur.sort_debloque(id):
		_message = "%s s’obtient dans les Épreuves." % str(_catalogue()[id]["nom"])
		queue_redraw()
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
		if not id.is_empty(): ReglagesJoueur.retirer_sort("actif")
	elif index == 3:
		id = ReglagesJoueur.ultime_equipe
		if not id.is_empty(): ReglagesJoueur.retirer_sort("ultime")
	elif index - 1 < ReglagesJoueur.passifs_equipes.size():
		id = str(ReglagesJoueur.passifs_equipes[index - 1])
		ReglagesJoueur.basculer_passif(id)
	if id.is_empty():
		return
	_message = "%s retiré." % str(Sorts.donnees(id).get("nom", "Sort"))
	Sons.jouer("choix", -12.0)
	_rafraichir()

func _rafraichir() -> void:
	var pages := maxi(1, ceili(float(_ids().size()) / 6.0))
	_precedent.disabled = _page <= 0
	_suivant.disabled = _page >= pages - 1
	queue_redraw()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	FondAdaptatif.dessiner_premium(self, FOND, size, HAUT_FIXE, BAS_FIXE)
	var sx := size.x / 1080.0
	var sy := sx
	var police := Polices.CORPS
	var couleur: Color = COULEURS[_categorie]
	for index in CATEGORIES.size():
		if CATEGORIES[index] == _categorie:
			var r: Rect2 = RECTS_CATEGORIES[index]
			draw_rect(Rect2(r.position * Vector2(sx, sy), r.size * Vector2(sx, sy)).grow(-9), Color(couleur, 0.16))
	_dessiner_loadout(police, sx, sy)
	var ids := _ids_page()
	for index in 6:
		if index >= ids.size(): continue
		_dessiner_carte(index, ids[index], police, sx, sy, couleur)
	var pages := maxi(1, ceili(float(_ids().size()) / 6.0))
	var resume := "PAGE %d / %d" % [_page + 1, pages]
	if not _message.is_empty(): resume = _message
	_draw_centre(police, Vector2(180 * sx, 1585 * sy), 720 * sx, resume, 26,
		Palette.OR if not _message.is_empty() else Palette.TEXTE_ATTENUE)
	if pages > 1:
		draw_string(police, Vector2(88 * sx, 1595 * sy), "‹", HORIZONTAL_ALIGNMENT_CENTER, 70 * sx, 38, Palette.OR)
		draw_string(police, Vector2(922 * sx, 1595 * sy), "›", HORIZONTAL_ALIGNMENT_CENTER, 70 * sx, 38, Palette.OR)

func _dessiner_loadout(police: Font, sx: float, sy: float) -> void:
	var ids := [ReglagesJoueur.sort_actif_effectif(),
		str(ReglagesJoueur.passifs_equipes[0]) if ReglagesJoueur.passifs_equipes.size() > 0 else "",
		str(ReglagesJoueur.passifs_equipes[1]) if ReglagesJoueur.passifs_equipes.size() > 1 else "",
		ReglagesJoueur.ultime_effectif()]
	for index in 4:
		var centre: Vector2 = CENTRES_EQUIPES[index] * Vector2(sx, sy)
		var id := str(ids[index])
		if id.is_empty():
			var texte := "VERROUILLÉ" if index == 2 and ReglagesJoueur.nombre_slots_passifs() < 2 else "VIDE"
			_draw_centre(police, Vector2(centre.x - 85 * sx, centre.y + 82 * sy), 170 * sx, texte, 23, Palette.TEXTE_ATTENUE)
			continue
		Retro16.dessiner_icone_interface(self, _icone_sort(id),
			Rect2(centre - Vector2(58, 58) * sx, Vector2(116, 116) * sx))
		_draw_centre(police, Vector2(centre.x - 90 * sx, centre.y + 82 * sy), 180 * sx,
			str(Sorts.donnees(id).get("nom", "")), 21, Palette.TEXTE)
		_draw_centre(police, Vector2(centre.x - 90 * sx, centre.y + 112 * sy), 180 * sx,
			"TOUCHER POUR RETIRER", 13, Palette.TEXTE_ATTENUE)

func _dessiner_carte(index: int, id: String, police: Font, sx: float, sy: float,
		couleur: Color) -> void:
	var r: Rect2 = RECTS_CARTES[index]
	var d: Dictionary = _catalogue()[id]
	var ouvert := ReglagesJoueur.sort_debloque(id)
	var equipe := id == ReglagesJoueur.sort_actif_equipe or id == ReglagesJoueur.ultime_equipe or id in ReglagesJoueur.passifs_equipes
	var centre_icone := Vector2((r.position.x + 125) * sx, (r.position.y + 135) * sy)
	Retro16.dessiner_icone_interface(self, _icone_sort(id),
		Rect2(centre_icone - Vector2(72, 72) * sx, Vector2(144, 144) * sx),
		Color.WHITE if ouvert else Color(0.42, 0.42, 0.48))
	if equipe:
		draw_circle(Vector2((r.position.x + 52) * sx, (r.position.y + 44) * sy), 18 * sx,
			Color(couleur, 0.85))
		_draw_centre(police, Vector2((r.position.x + 36) * sx, (r.position.y + 51) * sy), 32 * sx, "✓", 18, Color.WHITE)
	var x := (r.position.x + 230) * sx
	var largeur := 225 * sx
	var nom_affiche := str(d["nom"]).to_upper()
	var taille_nom := 18 if nom_affiche.length() > 18 else 19 if nom_affiche.length() > 15 else 21
	_draw_centre(police, Vector2(x, (r.position.y + 78) * sy), largeur, nom_affiche, taille_nom,
		Palette.TEXTE if ouvert else Palette.TEXTE_ATTENUE)
	draw_multiline_string(police, Vector2(x + 8 * sx, (r.position.y + 132) * sy), str(d["description"]),
		HORIZONTAL_ALIGNMENT_CENTER, largeur - 16 * sx, 25, 3, Palette.TEXTE_ATTENUE)
	var rang := ReglagesJoueur.rang_sort(id)
	var etat := "ÉQUIPÉ • RETIRER" if equipe else \
		"RANG %d/%d" % [rang, Reglages.CAPACITE_RANG_MAX] if ouvert else "À OBTENIR"
	_draw_centre(police, Vector2(x, (r.position.y + 260) * sy), largeur, etat, 23, couleur if ouvert else Palette.TEXTE_ATTENUE)
	if not ouvert:
		draw_rect(Rect2(r.position * Vector2(sx, sy), r.size * Vector2(sx, sy)).grow(-10), Color(0, 0, 0, 0.38))

func _icone_sort(id: String) -> int:
	var clefs: Array[String] = []
	for catalogue in [Sorts.ACTIFS, Sorts.PASSIFS, Sorts.ULTIMES]:
		for cle in catalogue:
			if cle not in clefs: clefs.append(cle)
	return posmod(clefs.find(id) + 8, 15)

func _draw_centre(police: Font, position: Vector2, largeur: float, texte: String,
		taille_police: int, couleur: Color) -> void:
	draw_string(police, position, texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille_police, couleur)

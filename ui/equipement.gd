extends Control

signal ferme

const FOND := preload("res://assets/visual/equipement_premium.png")
const HAUT_FIXE := 1740.0
const BAS_FIXE := 180.0
const SLOTS := ["anneau_gauche", "collier", "anneau_droit"]
const NOMS_SLOTS := {
	"anneau_gauche": "ANNEAU GAUCHE", "collier": "COLLIER",
	"anneau_droit": "ANNEAU DROIT",
}
const RECTS_SLOTS := [
	Rect2(96, 294, 220, 290), Rect2(430, 270, 220, 270), Rect2(764, 294, 220, 290),
]
const CENTRES_INVENTAIRE := [
	Vector2(270, 1260), Vector2(540, 1260), Vector2(810, 1260),
	Vector2(270, 1490), Vector2(540, 1490), Vector2(810, 1490),
]
const RECTS_ACTIONS := [
	Rect2(82, 1590, 285, 140), Rect2(397, 1590, 285, 140), Rect2(713, 1590, 285, 140),
]

var integre_menu := false
var _slot_selectionne := "anneau_gauche"
var _objet_selectionne := ""
var _page := 0
var _balayage := BalayagePages.new()
var _boutons_slots: Array[Button] = []
var _boutons_objets: Array[Button] = []
var _actions: Array[Button] = []
var _precedent: Button
var _suivant: Button
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_zones()
	_selectionner_slot(_slot_selectionne)
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire_zones() -> void:
	for index in SLOTS.size():
		var bouton := _zone(RECTS_SLOTS[index], func() -> void: _selectionner_slot(SLOTS[index]))
		_boutons_slots.append(bouton)
	for index in 6:
		var r := Rect2(CENTRES_INVENTAIRE[index] - Vector2(112, 98), Vector2(224, 196))
		var bouton := _zone(r, func() -> void: _selectionner_objet(index))
		_boutons_objets.append(bouton)
	_actions.append(_zone(RECTS_ACTIONS[0], _equiper))
	_actions.append(_zone(RECTS_ACTIONS[1], _retirer))
	_actions.append(_zone(RECTS_ACTIONS[2], _ameliorer))
	_precedent = _zone(Rect2(26, 1120, 124, 175), func() -> void: _changer_page(-1))
	_suivant = _zone(Rect2(930, 1120, 124, 175), func() -> void: _changer_page(1))
	resized.connect(_replacer_zones)
	_replacer_zones()

func _zone(reference: Rect2, action: Callable) -> Button:
	var bouton := StyleInterface.zone_tactile()
	bouton.set_meta("reference", reference)
	# Un balayage relache son doigt sur une case : sans ce garde-fou il
	# selectionnerait un objet, voire depenserait des Pierres sur « AMÉLIORER ».
	bouton.pressed.connect(func() -> void:
		if not _balayage.a_balaye():
			action.call())
	add_child(bouton)
	return bouton

func _replacer_zones() -> void:
	for enfant in get_children():
		if enfant is Button and enfant.has_meta("reference"):
			var r: Rect2 = enfant.get_meta("reference")
			var adapte := FondAdaptatif.rect(size, FOND, r, HAUT_FIXE, BAS_FIXE)
			enfant.position = adapte.position
			enfant.size = adapte.size

func _selectionner_slot(slot: String) -> void:
	_slot_selectionne = slot
	_page = 0
	_objet_selectionne = str(ReglagesJoueur.equipements.get(slot, ""))
	if _objet_selectionne.is_empty():
		var disponibles := _objets_compatibles()
		if not disponibles.is_empty():
			_objet_selectionne = disponibles[0]
	_rafraichir()

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

func _selectionner_objet(index: int) -> void:
	var visibles := _objets_page()
	if index >= visibles.size():
		return
	_objet_selectionne = visibles[index]
	Sons.jouer("choix", -16.0)
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
	if not visibles.is_empty(): _objet_selectionne = visibles[0]
	Sons.jouer("choix", -17.0)
	_rafraichir()

func _equiper() -> void:
	if _objet_selectionne.is_empty():
		return
	if ReglagesJoueur.equiper_objet(_slot_selectionne, _objet_selectionne):
		Sons.jouer("choix", -10.0)
		_rafraichir()

func _retirer() -> void:
	if ReglagesJoueur.retirer_objet(_slot_selectionne):
		Sons.jouer("choix", -12.0)
		_rafraichir()

func _ameliorer() -> void:
	if _objet_selectionne.is_empty():
		return
	if ReglagesJoueur.ameliorer_objet(_objet_selectionne):
		Sons.jouer("fusion", -10.0)
		_rafraichir()

func _rafraichir() -> void:
	var compatibles := _objets_compatibles()
	var pages := maxi(1, ceili(float(compatibles.size()) / 6.0))
	_page = clampi(_page, 0, pages - 1)
	_precedent.disabled = _page <= 0
	_suivant.disabled = _page >= pages - 1
	_actions[0].disabled = _objet_selectionne.is_empty() or str(ReglagesJoueur.equipements.get(_slot_selectionne, "")) == _objet_selectionne
	_actions[1].disabled = str(ReglagesJoueur.equipements.get(_slot_selectionne, "")).is_empty()
	_actions[2].disabled = _objet_selectionne.is_empty() \
		or ReglagesJoueur.niveau_objet(_objet_selectionne) >= Reglages.FORGE_NIVEAU_MAX \
		or ReglagesJoueur.pierres_forge < ReglagesJoueur.cout_forge(_objet_selectionne)
	queue_redraw()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	FondAdaptatif.dessiner_premium(self, FOND, size, HAUT_FIXE, BAS_FIXE)
	var sx := size.x / 1080.0
	var sy := sx
	var police := Polices.CORPS
	# Heros vivant sur le socle central.
	draw_set_transform(Vector2(540.0 * sx, 755.0 * sy + sin(_anim * 1.8) * 2.0), 0.0, Vector2.ONE * 1.65 * sx)
	Retro16.dessiner_heros(self, _anim * 0.55, false, Vector2.RIGHT, Palette.OR)
	draw_set_transform(Vector2.ZERO)

	for index in SLOTS.size():
		var slot: String = str(SLOTS[index])
		var r: Rect2 = RECTS_SLOTS[index]
		var selectionne: bool = slot == _slot_selectionne
		if selectionne:
			draw_rect(Rect2(r.position * Vector2(sx, sy), r.size * Vector2(sx, sy)).grow(-7.0), Color(Palette.ESSENCE, 0.16))
		var id := str(ReglagesJoueur.equipements.get(slot, ""))
		var centre := Vector2(r.get_center().x * sx, (r.get_center().y - 10.0) * sy)
		if id.is_empty():
			_draw_centre(police, Vector2((r.position.x + 12) * sx, (r.end.y - 48) * sy), (r.size.x - 24) * sx, "VIDE", 21, Palette.TEXTE_ATTENUE)
		else:
			_dessiner_icone_objet(id, Rect2(centre - Vector2(62, 62) * sx, Vector2(124, 124) * sx))
			_draw_centre(police, Vector2((r.position.x + 8) * sx, (r.end.y - 50) * sy), (r.size.x - 16) * sx,
				"NIV. %d" % ReglagesJoueur.niveau_objet(id), 20, Palette.TEXTE)

	draw_string(police, Vector2(78 * sx, 876 * sy), "STATISTIQUES DU HÉROS", HORIZONTAL_ALIGNMENT_LEFT, 390 * sx, 28, Palette.OR)
	draw_multiline_string(police, Vector2(78 * sx, 918 * sy), _resume_heros(),
		HORIZONTAL_ALIGNMENT_LEFT, 400 * sx, 25, 5, Palette.TEXTE)
	_dessiner_details(police, sx, sy)

	var visibles := _objets_page()
	for index in 6:
		var centre: Vector2 = CENTRES_INVENTAIRE[index] * Vector2(sx, sy)
		if index >= visibles.size():
			continue
		var id := visibles[index]
		if id == _objet_selectionne:
			draw_rect(Rect2(centre - Vector2(100, 88) * sx, Vector2(200, 176) * sx), Color(Palette.ESSENCE, 0.18))
		_dessiner_icone_objet(id, Rect2(centre - Vector2(54, 64) * sx, Vector2(108, 108) * sx))
		_draw_centre(police, Vector2(centre.x - 100 * sx, centre.y + 65 * sy), 200 * sx,
			"NIV. %d" % ReglagesJoueur.niveau_objet(id), 21, Palette.TEXTE)
	var pages := maxi(1, ceili(float(_objets_compatibles().size()) / 6.0))
	if pages > 1:
		_draw_centre(police, Vector2(420 * sx, 1167 * sy), 240 * sx, "%d / %d" % [_page + 1, pages], 20, Palette.TEXTE_ATTENUE)
		draw_string(police, Vector2(82 * sx, 1190 * sy), "‹", HORIZONTAL_ALIGNMENT_CENTER, 70 * sx, 38, Palette.OR)
		draw_string(police, Vector2(928 * sx, 1190 * sy), "›", HORIZONTAL_ALIGNMENT_CENTER, 70 * sx, 38, Palette.OR)
	for index in 3:
		if _actions[index].disabled:
			var r: Rect2 = RECTS_ACTIONS[index]
			draw_rect(Rect2(r.position * Vector2(sx, sy), r.size * Vector2(sx, sy)).grow(-14.0), Color(0.0, 0.0, 0.0, 0.50))

const LIBELLES_BONUS := {"degats": "Dégâts", "pv": "PV max", "cadence": "Cadence",
	"vitesse": "Vitesse", "collecte": "Gouttes"}

# Ce que le heros vaut reellement, pas seulement ce que l'equipement ajoute :
# l'ecran n'affichait que des pourcentages, sans jamais dire ou en etaient les
# degats, les PV et la cadence.
func _resume_heros() -> String:
	var stats := Stats.depuis_reglages(ReglagesJoueur.rangs_competences_effectifs(),
		ReglagesJoueur.passifs_equipes_effectifs(), ReglagesJoueur.bonus_objets_effectifs(),
		ReglagesJoueur.niveau_compte_effectif())
	var reduction := ArbreCompetences.reduction_degats(ReglagesJoueur.rangs_competences_effectifs())
	return "\n".join([
		"Niveau  %d" % ReglagesJoueur.niveau_compte_effectif(),
		"Dégâts  %d" % roundi(stats.degats),
		"PV max  %d" % roundi(stats.pv_max),
		"Cadence  %.2f /s" % stats.cadence,
		"Réduction  %d %%   ·   Pierres  %d" % [roundi(reduction * 100.0), ReglagesJoueur.pierres_forge],
	])

func _dessiner_details(police: Font, sx: float, sy: float) -> void:
	if _objet_selectionne.is_empty() or not CatalogueObjets.OBJETS.has(_objet_selectionne):
		draw_string(police, Vector2(550 * sx, 930 * sy), "AUCUN OBJET SÉLECTIONNÉ", HORIZONTAL_ALIGNMENT_CENTER, 430 * sx, 27, Palette.TEXTE_ATTENUE)
		return
	var d: Dictionary = CatalogueObjets.OBJETS[_objet_selectionne]
	var niveau := ReglagesJoueur.niveau_objet(_objet_selectionne)
	_draw_centre(police, Vector2(550 * sx, 876 * sy), 430 * sx, str(d["nom"]).to_upper(), 29, Palette.TEXTE)
	_draw_centre(police, Vector2(550 * sx, 918 * sy), 430 * sx,
		"NIVEAU %d  •  MONDE %d" % [niveau, int(d["monde"]) + 1], 24, Color(d["teinte"]))
	# Ce que l'objet apporte reellement : sans cette ligne, deux Anneaux de Mondes
	# differents sont indiscernables alors que leurs valeurs vont du simple au
	# decuple.
	var apport := CatalogueObjets.bonus_objet(_objet_selectionne, niveau)
	var parts: Array[String] = []
	for champ in LIBELLES_BONUS:
		var valeur := roundi(float(apport.get(champ, 0.0)) * 100.0)
		if valeur != 0:
			parts.append("%s +%d %%" % [LIBELLES_BONUS[champ], valeur])
	_draw_centre(police, Vector2(550 * sx, 956 * sy), 430 * sx, "  ·  ".join(parts), 21, Palette.OR)
	var texte_forge := "NIVEAU MAXIMUM" if niveau >= Reglages.FORGE_NIVEAU_MAX \
		else "AMÉLIORER : %d PIERRES" % ReglagesJoueur.cout_forge(_objet_selectionne)
	_draw_centre(police, Vector2(550 * sx, 992 * sy), 430 * sx, texte_forge, 24, Palette.TEXTE_ATTENUE)

func _dessiner_icone_objet(id: String, rect: Rect2) -> void:
	var d: Dictionary = CatalogueObjets.OBJETS[id]
	var index := posmod(int(d["chapitre"]), 15)
	Retro16.dessiner_icone_interface(self, index, rect, Color.WHITE.lerp(Color(d["teinte"]), 0.12))

func _draw_centre(police: Font, position: Vector2, largeur: float, texte: String,
		taille_police: int, couleur: Color) -> void:
	draw_string(police, position, texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille_police, couleur)

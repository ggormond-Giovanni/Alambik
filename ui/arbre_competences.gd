extends Control

signal ferme

const FOND := preload("res://assets/visual/maitrises_premium.png")
const HAUT_FIXE := 1740.0
const BAS_FIXE := 180.0
const BRANCHES := ["Offensif", "Défensif", "Utilitaire"]
const COULEURS := {
	"Offensif": Color(1.0, 0.38, 0.22),
	"Défensif": Color(0.30, 0.68, 1.0),
	"Utilitaire": Color(0.42, 0.86, 0.46),
}
const RECTS_BRANCHES := [Rect2(82, 380, 290, 120), Rect2(395, 380, 290, 120), Rect2(708, 380, 290, 120)]
const RECT_AMELIORER := Rect2(216.0, 1518.0, 648.0, 64.0)
const POSITIONS_NOEUDS := [
	Vector2(540, 600), Vector2(345, 755), Vector2(735, 755), Vector2(540, 825),
	Vector2(225, 1010), Vector2(855, 1010), Vector2(540, 1055),
	Vector2(225, 1240), Vector2(855, 1240), Vector2(540, 1270),
]

var integre_menu := false
var _branche := "Offensif"
var _selection := ""
var _message := ""
var _onglets: Array[Button] = []
var _noeuds: Array[Button] = []
var _reset: Button
var _bouton_ameliorer: Button
var _anim := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire_zones()
	_afficher_branche(_branche)
	StyleInterface.animer_entree(self, 16.0)
	Capture.programmer(self)

func _construire_zones() -> void:
	for index in BRANCHES.size():
		_onglets.append(_zone(RECTS_BRANCHES[index], func() -> void: _afficher_branche(BRANCHES[index])))
	for index in 10:
		_noeuds.append(_zone(Rect2(POSITIONS_NOEUDS[index] - Vector2(88, 82), Vector2(176, 164)),
			func() -> void: _sur_noeud(index)))
	_bouton_ameliorer = _zone(RECT_AMELIORER, _ameliorer)
	_reset = _zone(Rect2(250, 1600, 580, 135), _reinitialiser)
	resized.connect(_replacer_zones)
	_replacer_zones()

func _zone(reference: Rect2, action: Callable) -> Button:
	var bouton := StyleInterface.zone_tactile(action)
	bouton.set_meta("reference", reference)
	add_child(bouton)
	return bouton

func _replacer_zones() -> void:
	for enfant in get_children():
		if enfant is Button and enfant.has_meta("reference"):
			var r: Rect2 = enfant.get_meta("reference")
			var adapte := FondAdaptatif.rect(size, FOND, r, HAUT_FIXE, BAS_FIXE)
			enfant.position = adapte.position
			enfant.size = adapte.size

func _afficher_branche(branche: String) -> void:
	_branche = branche
	_message = ""
	var ids: Array = ArbreCompetences.BRANCHES[_branche]
	_selection = str(ids[0]) if not ids.is_empty() else ""
	Sons.jouer("choix", -17.0)
	queue_redraw()

# Toucher un noeud ne fait que le consulter. Il declenchait l'achat directement,
# donc un doigt pose au mauvais endroit depensait des Gouttes sans confirmation.
func _sur_noeud(index: int) -> void:
	var ids: Array = ArbreCompetences.BRANCHES[_branche]
	if index >= ids.size():
		return
	_selection = str(ids[index])
	_message = ""
	Sons.jouer("choix", -18.0)
	queue_redraw()

func _ameliorer() -> void:
	if _selection.is_empty():
		return
	var id := _selection
	var noeud: Dictionary = ArbreCompetences.NOEUDS[id]
	var rang := ReglagesJoueur.rang_competence(id)
	if rang >= ArbreCompetences.rangs(id):
		_message = "%s est au rang maximum." % noeud["nom"]
	elif not ReglagesJoueur.mode_dev and not ArbreCompetences.prerequis_atteint(id, ReglagesJoueur.rangs_competences):
		var requis: Dictionary = ArbreCompetences.NOEUDS[noeud["requis"]]
		_message = "Terminez d’abord %s." % requis["nom"]
	elif not ReglagesJoueur.mode_dev and ReglagesJoueur.gouttes < ReglagesJoueur.cout_competence(id):
		_message = "Il manque %d Gouttes." % (ReglagesJoueur.cout_competence(id) - ReglagesJoueur.gouttes)
	elif ReglagesJoueur.acheter_competence(id):
		_message = "%s rang %d/%d : bonus permanent actif." % [noeud["nom"],
			ReglagesJoueur.rang_competence(id), ArbreCompetences.rangs(id)]
		Sons.jouer("fusion", -12.0)
	queue_redraw()

func _reinitialiser() -> void:
	var rembourses := ReglagesJoueur.reinitialiser_arbre()
	_message = "Réinitialisation : %d Gouttes remboursées." % rembourses
	Sons.jouer("choix", -12.0)
	queue_redraw()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	FondAdaptatif.dessiner_premium(self, FOND, size, HAUT_FIXE, BAS_FIXE)
	var sx := size.x / 1080.0
	var sy := sx
	var police := Polices.CORPS
	var couleur: Color = COULEURS[_branche]
	var xp := "%d / %d" % [ReglagesJoueur.experience_compte, ReglagesJoueur.experience_compte_requise()]
	_draw_centre(police, Vector2(180 * sx, 331 * sy), 720 * sx,
		"NIVEAU %d  •  XP %s  •  GOUTTES %s" % [ReglagesJoueur.niveau_compte_effectif(), xp, ReglagesJoueur.gouttes_affichees()],
		26, Palette.TEXTE)
	for index in BRANCHES.size():
		if BRANCHES[index] == _branche:
			var r: Rect2 = RECTS_BRANCHES[index]
			draw_rect(Rect2(r.position * Vector2(sx, sy), r.size * Vector2(sx, sy)).grow(-10), Color(COULEURS[_branche], 0.16))

	var ids: Array = ArbreCompetences.BRANCHES[_branche]
	for index in mini(10, ids.size()):
		var id := str(ids[index])
		var noeud: Dictionary = ArbreCompetences.NOEUDS[id]
		var rang := ReglagesJoueur.rang_competence(id)
		var disponible := ReglagesJoueur.mode_dev or ArbreCompetences.prerequis_atteint(id, ReglagesJoueur.rangs_competences)
		var centre: Vector2 = POSITIONS_NOEUDS[index] * Vector2(sx, sy)
		if id == _selection:
			draw_circle(centre, 78 * sx + sin(_anim * 3.0) * 3.0, Color(couleur, 0.18))
		var teinte := couleur if rang > 0 else couleur.darkened(0.25) if disponible else Color(0.30, 0.32, 0.38)
		Retro16.dessiner_icone_interface(self, posmod(index + BRANCHES.find(_branche) * 4, 15),
			Rect2(centre - Vector2(49, 49) * sx, Vector2(98, 98) * sx), Color.WHITE.lerp(teinte, 0.24))
		_draw_centre(police, Vector2(centre.x - 70 * sx, centre.y + 71 * sy), 140 * sx,
			"%d/%d" % [rang, ArbreCompetences.rangs(id)], 22, Palette.TEXTE if disponible else Palette.TEXTE_ATTENUE)
		# Le prix du prochain rang se lit sur le noeud : sans lui, comparer dix
		# paliers demandait de les selectionner un par un.
		var maximal := rang >= ArbreCompetences.rangs(id)
		var prix := "MAX" if maximal else ("—" if not disponible \
			else str(ReglagesJoueur.cout_competence(id)))
		var teinte_prix := Palette.TEXTE_ATTENUE
		if not maximal and disponible:
			teinte_prix = Palette.OR if ReglagesJoueur.gouttes >= ReglagesJoueur.cout_competence(id) \
				or ReglagesJoueur.mode_dev else Palette.DANGER
		_draw_centre(police, Vector2(centre.x - 70 * sx, centre.y + 96 * sy), 140 * sx,
			prix, 19, teinte_prix)
	_dessiner_details(police, sx, sy, couleur)

func _dessiner_details(police: Font, sx: float, sy: float, couleur: Color) -> void:
	if _selection.is_empty():
		return
	var noeud: Dictionary = ArbreCompetences.NOEUDS[_selection]
	var rang := ReglagesJoueur.rang_competence(_selection)
	var maximum := ArbreCompetences.rangs(_selection)
	_draw_centre(police, Vector2(92 * sx, 1424 * sy), 896 * sx, "%s  •  %d/%d" % [
		str(noeud["nom"]).to_upper(), rang, maximum], 32, couleur)
	_draw_centre(police, Vector2(120 * sx, 1468 * sy), 840 * sx,
		ArbreCompetences.description_effective(_selection), 26, Palette.TEXTE)
	# Ce que le rang suivant apportera, a cote de ce qu'on a deja : c'est la
	# seule information qui permet de decider avant de depenser.
	var actuel := ArbreCompetences.valeur_au_rang(_selection, rang)
	var comparaison := "ACTUEL %s" % actuel if rang >= maximum \
		else "ACTUEL %s   →   RANG %d  %s" % [actuel, rang + 1,
			ArbreCompetences.valeur_au_rang(_selection, rang + 1)]
	_draw_centre(police, Vector2(120 * sx, 1506 * sy), 840 * sx, comparaison, 23, Palette.OR)
	_dessiner_bouton_ameliorer(police, sx, sy, rang, maximum)
	if not _message.is_empty():
		_draw_centre(police, Vector2(120 * sx, 1600 * sy), 840 * sx, _message, 21, Palette.OR)

func _dessiner_bouton_ameliorer(police: Font, sx: float, sy: float, rang: int, maximum: int) -> void:
	var rect := Rect2(RECT_AMELIORER.position * Vector2(sx, sy),
		RECT_AMELIORER.size * Vector2(sx, sy))
	var atteint := rang >= maximum
	var ouvert := ReglagesJoueur.mode_dev \
		or ArbreCompetences.prerequis_atteint(_selection, ReglagesJoueur.rangs_competences)
	var cout := ReglagesJoueur.cout_competence(_selection)
	var payable := ReglagesJoueur.mode_dev or ReglagesJoueur.gouttes >= cout
	var libelle := "RANG MAXIMUM" if atteint else \
		"VERROUILLÉ" if not ouvert else "AMÉLIORER  ·  %d GOUTTES" % cout
	var actif := not atteint and ouvert and payable
	var accent := Palette.OR if actif else Palette.TEXTE_ATTENUE
	draw_rect(rect, Color(0.020, 0.030, 0.062, 0.94))
	draw_rect(rect, Color(accent, 0.85 if actif else 0.38), false, 3.0)
	_draw_centre(police, Vector2(rect.position.x, rect.get_center().y + 9.0), rect.size.x,
		libelle, 24, accent if actif else Palette.TEXTE_ATTENUE)
	if _bouton_ameliorer != null:
		_bouton_ameliorer.disabled = atteint

func _draw_centre(police: Font, position: Vector2, largeur: float, texte: String,
		taille_police: int, couleur: Color) -> void:
	draw_string(police, position, texte, HORIZONTAL_ALIGNMENT_CENTER, largeur, taille_police, couleur)

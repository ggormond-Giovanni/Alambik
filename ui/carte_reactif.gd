class_name CarteReactif
extends Control

# Une carte de reactif, entierement dessinee : cadre, glyphe, nom, description.
# Le cadre distingue une essence d'un reactif, comme le demande la spec, et la
# cible tactile ne descend jamais sous ce qu'un pouce atteint sans viser.

signal choisie(id: String)

const HAUTEUR := 216.0

var reactif: Reactif
var selectionnee := false
var desactivee := false
var montrer_composants := false

var _survol := 0.0
var _anim := 0.0
var _pulsation := 0.0
var _pointeur := false
var _style_normal: StyleBoxFlat
var _style_actif: StyleBoxFlat

func configurer(reactif_: Reactif) -> void:
	reactif = reactif_
	_style_normal = StyleInterface.panneau(Color(0.075, 0.060, 0.115, 0.97), Color(reactif.teinte, 0.28), 28, 10)
	_style_actif = StyleInterface.panneau(Color(reactif.teinte, 0.16), Color(reactif.teinte, 0.90), 28, 16)
	custom_minimum_size = Vector2(0, HAUTEUR)
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(0, HAUTEUR)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: _pointeur = true)
	mouse_exited.connect(func() -> void: _pointeur = false)

func _process(delta: float) -> void:
	_anim += delta
	var vise := 1.0 if selectionnee else (0.42 if _pointeur else 0.0)
	_survol = lerpf(_survol, vise, minf(1.0, delta * 10.0))
	_pulsation = maxf(0.0, _pulsation - delta * 3.0)
	queue_redraw()

func _gui_input(evenement: InputEvent) -> void:
	if desactivee:
		return
	var appui := false
	if evenement is InputEventScreenTouch:
		appui = (evenement as InputEventScreenTouch).pressed
	elif evenement is InputEventMouseButton:
		appui = (evenement as InputEventMouseButton).pressed
	if appui:
		_pulsation = 1.0
		Sons.jouer("choix", -14.0)
		choisie.emit(reactif.id)
		accept_event()

func _draw() -> void:
	if reactif == null:
		return
	var police := ThemeDB.fallback_font
	var r := Rect2(Vector2(8.0, 7.0), size - Vector2(16.0, 14.0))
	var teinte: Color = reactif.teinte
	var alpha := 0.35 if desactivee else 1.0

	# Surface surelevee : le fond, l'ombre et les coins sont communs a toute l'UI.
	draw_style_box(_style_actif if selectionnee or _survol > 0.55 else _style_normal, r)
	if selectionnee or _pulsation > 0.0:
		var lueur := maxf(_survol, _pulsation)
		draw_rect(Rect2(r.position, Vector2(7.0, r.size.y)), Color(teinte, 0.85 * lueur))
	if reactif.est_essence:
		# Une essence porte un double cadre et une teinte propre : elle ne doit
		# jamais se confondre avec un reactif ordinaire.
		draw_arc(Vector2(r.end.x - 38.0, r.position.y + 38.0), 18.0, 0.0, TAU, 24, Color(Palette.ESSENCE, 0.75 * alpha), 2.0, true)
		draw_string(police, Vector2(r.size.x - 190.0, 34.0), "ESSENCE",
			HORIZONTAL_ALIGNMENT_RIGHT, 170, 22, Color(Palette.ESSENCE, 0.9 * alpha))

	# Vignette du glyphe, a gauche : une icone dessinee, pas un fichier image.
	var centre := Vector2(84.0, r.position.y + r.size.y / 2.0)
	Dessin.halo(self, centre, 60.0, Color(teinte, 0.5 * alpha), 4)
	draw_circle(centre, 44.0, Color(0.07, 0.06, 0.10, alpha))
	draw_arc(centre, 44.0, 0.0, TAU, 28, Color(teinte, 0.8 * alpha), 2.5, true)
	Dessin.glyphe(self, reactif.glyphe, centre, 24.0, Color(teinte, alpha))

	var x := 158.0
	var titre := reactif.nom
	var possedees := Jeu.copies(reactif.id)
	if possedees > 0:
		# Reprendre un reactif l'empile : on annonce ou on en est, sinon le
		# joueur ne sait pas ce qu'il renforce.
		titre += "  (déjà x%d)" % possedees
	draw_string(police, Vector2(x, r.position.y + 62.0), titre, HORIZONTAL_ALIGNMENT_LEFT,
		r.size.x - x - 24.0, 40, Color(Palette.TEXTE, alpha))
	draw_multiline_string(police, Vector2(x, r.position.y + 108.0), reactif.description, HORIZONTAL_ALIGNMENT_LEFT,
		r.size.x - x - 24.0, 28, 3, Color(Palette.TEXTE_ATTENUE, alpha))

	if montrer_composants and reactif.est_essence:
		var composants := Recettes.composants_de(reactif.id)
		if composants.size() == 2:
			var a := CatalogueReactifs.par_id(composants[0])
			var b := CatalogueReactifs.par_id(composants[1])
			if a != null and b != null:
				# On annonce ce qu'on perd avant le clic, jamais apres.
				draw_string(police, Vector2(x, r.size.y - 24.0), "consomme %s + %s" % [a.nom, b.nom],
					HORIZONTAL_ALIGNMENT_LEFT, r.size.x - x - 24.0, 24, Color(Palette.ESSENCE, 0.8 * alpha))

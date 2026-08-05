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

func configurer(reactif_: Reactif) -> void:
	reactif = reactif_
	custom_minimum_size = Vector2(0, HAUTEUR)
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(0, HAUTEUR)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	_anim += delta
	var vise := 1.0 if selectionnee else 0.0
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
	var r := Rect2(Vector2.ZERO, size)
	var teinte: Color = reactif.teinte
	var alpha := 0.35 if desactivee else 1.0

	# Fond de carte : parchemin sombre, liseré teinte par le reactif.
	draw_rect(r, Color(0.10, 0.09, 0.14, 0.96 * alpha))
	if selectionnee or _pulsation > 0.0:
		var lueur := maxf(_survol, _pulsation)
		draw_rect(r.grow(6.0 * lueur), Color(teinte, 0.22 * lueur))
	draw_rect(r, Color(teinte, (0.75 if selectionnee else 0.40) * alpha), false, 3.0)
	if reactif.est_essence:
		# Une essence porte un double cadre et une teinte propre : elle ne doit
		# jamais se confondre avec un reactif ordinaire.
		draw_rect(r.grow(-8.0), Color(Palette.ESSENCE, 0.55 * alpha), false, 2.0)
		draw_string(police, Vector2(r.size.x - 190.0, 34.0), "ESSENCE",
			HORIZONTAL_ALIGNMENT_RIGHT, 170, 22, Color(Palette.ESSENCE, 0.9 * alpha))

	# Vignette du glyphe, a gauche : une icone dessinee, pas un fichier image.
	var centre := Vector2(78.0, r.size.y / 2.0)
	Dessin.halo(self, centre, 60.0, Color(teinte, 0.5 * alpha), 4)
	draw_circle(centre, 44.0, Color(0.07, 0.06, 0.10, alpha))
	draw_arc(centre, 44.0, 0.0, TAU, 28, Color(teinte, 0.8 * alpha), 2.5, true)
	Dessin.glyphe(self, reactif.glyphe, centre, 24.0, Color(teinte, alpha))

	var x := 150.0
	draw_string(police, Vector2(x, 66.0), reactif.nom, HORIZONTAL_ALIGNMENT_LEFT,
		r.size.x - x - 24.0, 40, Color(Palette.TEXTE, alpha))
	draw_multiline_string(police, Vector2(x, 112.0), reactif.description, HORIZONTAL_ALIGNMENT_LEFT,
		r.size.x - x - 24.0, 28, 3, Color(Palette.TEXTE_ATTENUE, alpha))

	if montrer_composants and reactif.est_essence:
		var composants := Recettes.composants_de(reactif.id)
		if composants.size() == 2:
			var a := CatalogueReactifs.par_id(composants[0])
			var b := CatalogueReactifs.par_id(composants[1])
			if a != null and b != null:
				draw_string(police, Vector2(x, r.size.y - 24.0), "%s + %s" % [a.nom, b.nom],
					HORIZONTAL_ALIGNMENT_LEFT, r.size.x - x - 24.0, 24, Color(Palette.ESSENCE, 0.8 * alpha))

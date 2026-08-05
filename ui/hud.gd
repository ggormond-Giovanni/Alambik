extends Control

# Barre de vie, salle courante, inventaire. Dessine, jamais compose de sprites,
# et pose sous la safe area : sur telephone, l'encoche mange le haut.

var _secousse := 0.0
var _anim := 0.0
var _pv_affiches := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Jeu.inventaire_change.connect(rafraichir)

func rafraichir() -> void:
	queue_redraw()

func secouer() -> void:
	_secousse = 1.0

func _process(delta: float) -> void:
	_anim += delta
	_secousse = maxf(0.0, _secousse - delta * 3.0)
	var heros := get_tree().get_first_node_in_group("heros")
	if heros != null:
		var vise: float = clampf(heros.stats.pv / maxf(1.0, heros.stats.pv_max), 0.0, 1.0)
		_pv_affiches = lerpf(_pv_affiches, vise, minf(1.0, delta * 8.0))
	queue_redraw()

func _draw() -> void:
	var police := ThemeDB.fallback_font
	var largeur := get_viewport_rect().size.x
	var haut := Ecran.marge_haute() + 28.0
	var tremble := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _secousse * 6.0

	var heros := get_tree().get_first_node_in_group("heros")
	if heros == null:
		return

	# Barre de vie : large, lisible d'un coup d'oeil au pouce.
	var barre := Rect2(Vector2(60.0, haut) + tremble, Vector2(largeur - 120.0, 34.0))
	draw_rect(barre.grow(4.0), Color(0, 0, 0, 0.45))
	draw_rect(barre, Color(0.16, 0.13, 0.20))
	var remplie := barre
	remplie.size.x *= _pv_affiches
	var teinte := Palette.DANGER.lerp(Color(0.55, 0.92, 0.62), _pv_affiches)
	draw_rect(remplie, teinte)
	draw_rect(Rect2(remplie.position, Vector2(remplie.size.x, 8.0)), Color(1, 1, 1, 0.18))
	draw_rect(barre, Palette.BORD_PAGE, false, 2.0)
	draw_string(police, barre.position + Vector2(14.0, 26.0),
		"%d / %d" % [roundi(heros.stats.pv), roundi(heros.stats.pv_max)],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.10, 0.09, 0.13))

	# Salle courante, en chiffres de page.
	draw_string(police, Vector2(60.0, haut + 74.0), "Page %d / %d" % [Jeu.salle_courante, Reglages.SALLES_PAR_RUN],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Palette.TEXTE)
	if heros.bouclier > 0:
		draw_string(police, Vector2(largeur - 260.0, haut + 74.0), "Bouclier",
			HORIZONTAL_ALIGNMENT_RIGHT, 200, 28, Color(0.82, 0.90, 1.0))

	# Inventaire : une pastille par reactif, teintee et glyphee. C'est la seule
	# trace visible de ce que le joueur a construit pendant la run.
	var x := 62.0
	var y := haut + 122.0
	for id in Jeu.inventaire:
		var r := Jeu.reactif(id)
		if r == null:
			continue
		var centre := Vector2(x, y)
		if r.est_essence:
			Dessin.halo(self, centre, 34.0, Palette.ESSENCE, 3)
			Dessin.contour(self, Dessin.polygone_regulier(centre, 26.0, 6, _anim * 0.4), Palette.ESSENCE, 2.5)
		else:
			draw_circle(centre, 24.0, Color(0.14, 0.12, 0.18))
			draw_arc(centre, 24.0, 0.0, TAU, 20, Color(r.teinte, 0.7), 2.0, true)
		Dessin.glyphe(self, r.glyphe, centre, 13.0, r.teinte)
		x += 58.0
		if x > get_viewport_rect().size.x - 60.0:
			x = 62.0
			y += 58.0

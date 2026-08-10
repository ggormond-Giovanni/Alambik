extends Node2D

# La page du grimoire. Dessinee sous tout le reste, y compris sous les zones
# au sol. Les taches sont tirees une fois par salle a partir de la graine de
# la run : deux runs de meme graine se ressemblent, ce qui aide a rejouer un
# blocage signale par la sonde.

var limites := Rect2()
var numero := 1

var _taches: Array[Dictionary] = []
var _anim := 0.0

func preparer(limites_: Rect2, numero_: int) -> void:
	limites = limites_
	numero = numero_
	_taches.clear()
	var alea := RandomNumberGenerator.new()
	alea.seed = Jeu.graine * 977 + numero
	for i in 26:
		_taches.append({
			"position": Vector2(alea.randf_range(limites.position.x, limites.end.x),
				alea.randf_range(limites.position.y, limites.end.y)),
			"rayon": alea.randf_range(6.0, 46.0),
			"graine": alea.randi() % 500,
			"alpha": alea.randf_range(0.05, 0.18),
		})
	queue_redraw()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _draw() -> void:
	var page := limites
	draw_rect(Rect2(Vector2(-200, -200), get_viewport_rect().size + Vector2(400, 400)), Palette.FOND)
	# La pierre feerique reste assez posee pour les projectiles, mais ses verts et
	# violets lumineux donnent une arene fantasy plutot qu'un gouffre noir.
	draw_rect(page.grow(34.0), Color(0.055, 0.080, 0.105))
	draw_rect(page.grow(22.0), Palette.BORD_ARENE)
	var tuile := 126.0
	var colonnes := ceili(page.size.x / tuile)
	var lignes := ceili(page.size.y / tuile)
	for y in lignes:
		for x in colonnes:
			var rect := Rect2(page.position + Vector2(float(x), float(y)) * tuile, Vector2.ONE * tuile).intersection(page)
			var couleur := Palette.SOL_ARENE if (x + y + numero) % 2 == 0 else Palette.SOL_ARENE_ALT
			draw_rect(rect, couleur)
			draw_rect(rect.grow(-2.0), Color(1.0, 1.0, 1.0, 0.018), false, 1.0)

	# Un grand sceau central donne un point de repere sans voler la lisibilite.
	var centre := page.get_center()
	draw_arc(centre, 188.0, 0.0, TAU, 64, Color(Palette.ESSENCE, 0.14), 5.0, true)
	draw_arc(centre, 136.0, 0.0, TAU, 48, Color(Palette.OR, 0.10), 3.0, true)
	Dessin.contour(self, Dessin.polygone_regulier(centre, 112.0, 6, PI / 6.0), Color(Palette.ESSENCE, 0.11), 3.0)

	for t in _taches:
		var c := Palette.MOUSSE_MAGIQUE
		c.a = t["alpha"] * 0.80
		draw_colored_polygon(Dessin.blob(t["position"], t["rayon"], t["graine"], 0.28), c)
		var scintille := 0.38 + 0.22 * sin(_anim * 2.4 + float(t["graine"]))
		draw_circle(t["position"], minf(4.5, t["rayon"] * 0.16), Color(Palette.ESSENCE, scintille))

	# Roches d'encre et pousses alchimiques ferment les bords comme un decor,
	# tandis que le centre reste parfaitement degage pour les projectiles.
	for cote in [-1.0, 1.0]:
		var x_bord := page.position.x - 18.0 if cote < 0.0 else page.end.x + 18.0
		for i in 12:
			var y_bord := lerpf(page.position.y + 30.0, page.end.y - 30.0, float(i) / 11.0)
			var rayon := 27.0 + 7.0 * sin(float(i) * 2.1 + float(numero))
			draw_circle(Vector2(x_bord, y_bord), rayon, Color(0.070, 0.140, 0.120))
			draw_circle(Vector2(x_bord - cote * 5.0, y_bord - 5.0), rayon * 0.62, Color(Palette.MOUSSE_MAGIQUE, 0.62))
	draw_rect(page, Color(0.040, 0.080, 0.090), false, 8.0)
	draw_rect(page.grow(-8.0), Color(Palette.ESSENCE, 0.28), false, 2.0)

	# Le portail est visible avant son ouverture : il donne un objectif spatial.
	var portail := Vector2(page.get_center().x, page.position.y - 16.0)
	draw_rect(Rect2(portail + Vector2(-106.0, -58.0), Vector2(212.0, 78.0)), Color(0.080, 0.130, 0.160))
	for i in 5:
		var pierre := Rect2(portail + Vector2(-102.0 + float(i) * 41.0, -54.0), Vector2(37.0, 68.0))
		draw_rect(pierre, Color(0.22, 0.30, 0.28))
		draw_rect(pierre, Color(Palette.BORD_PAGE, 0.34), false, 2.0)
	draw_rect(Rect2(portail + Vector2(-56.0, -34.0), Vector2(112.0, 54.0)), Color(0.070, 0.035, 0.120))
	draw_line(portail + Vector2(0.0, -32.0), portail + Vector2(0.0, 18.0), Color(Palette.OR, 0.48), 2.0)

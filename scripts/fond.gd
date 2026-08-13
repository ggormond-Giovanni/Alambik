extends Node2D

# L'arene est dessinee sous tout le reste, y compris sous les zones
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
	_dessiner_retro()

func _dessiner_peint_archive() -> void:
	var arene := limites
	draw_rect(arene.grow(420.0), Palette.FOND)
	# La pierre feerique reste assez posee pour les projectiles, mais ses verts et
	# violets lumineux donnent une arene fantasy plutot qu'un gouffre noir.
	draw_rect(arene.grow(34.0), Color(0.055, 0.080, 0.105))
	draw_rect(arene.grow(22.0), Palette.BORD_ARENE)
	var tuile := 126.0
	var colonnes := ceili(arene.size.x / tuile)
	var lignes := ceili(arene.size.y / tuile)
	for y in lignes:
		for x in colonnes:
			var rect := Rect2(arene.position + Vector2(float(x), float(y)) * tuile, Vector2.ONE * tuile).intersection(arene)
			var couleur := Palette.SOL_ARENE if (x + y + numero) % 2 == 0 else Palette.SOL_ARENE_ALT
			draw_rect(rect, couleur)
			draw_rect(rect.grow(-2.0), Color(1.0, 1.0, 1.0, 0.018), false, 1.0)

	# Un grand sceau central donne un point de repere sans voler la lisibilite.
	var centre := arene.get_center()
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
		var x_bord := arene.position.x - 18.0 if cote < 0.0 else arene.end.x + 18.0
		for i in 12:
			var y_bord := lerpf(arene.position.y + 30.0, arene.end.y - 30.0, float(i) / 11.0)
			var rayon := 27.0 + 7.0 * sin(float(i) * 2.1 + float(numero))
			draw_circle(Vector2(x_bord, y_bord), rayon, Color(0.070, 0.140, 0.120))
			draw_circle(Vector2(x_bord - cote * 5.0, y_bord - 5.0), rayon * 0.62, Color(Palette.MOUSSE_MAGIQUE, 0.62))
	draw_rect(arene, Color(0.040, 0.080, 0.090), false, 8.0)
	draw_rect(arene.grow(-8.0), Color(Palette.ESSENCE, 0.28), false, 2.0)

func _dessiner_retro() -> void:
	var arene := limites
	draw_rect(arene.grow(420.0), Retro16.ENCRE)
	draw_rect(arene.grow(28.0), Color("2a1a3b"))
	draw_rect(arene.grow(18.0), Color("6b4a78"))
	var tuile := 96.0
	var colonnes := ceili(arene.size.x / tuile)
	var lignes := ceili(arene.size.y / tuile)
	for y in lignes:
		for x in colonnes:
			var rect := Rect2(arene.position + Vector2(x, y) * tuile,
				Vector2.ONE * tuile).intersection(arene)
			var couleur := Color("263d4a") if (x + y) % 2 == 0 else Color("304b52")
			draw_rect(rect, couleur)
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4.0)), couleur.lightened(0.12))
			draw_rect(Rect2(rect.position, Vector2(4.0, rect.size.y)), couleur.lightened(0.08))
	# Le sceau central devient une mosaique de blocs, sans courbe antialiassee.
	var centre := Retro16.pixel(arene.get_center())
	for index in 4:
		var taille := 64.0 + index * 24.0
		draw_rect(Rect2(centre - Vector2.ONE * taille * 0.5, Vector2.ONE * taille),
			Color(Retro16.VIOLET, 0.13), false, 4.0)
	for t in _taches:
		var p := Retro16.pixel(t["position"])
		var taille := 4.0 + float(int(t["graine"]) % 3) * 4.0
		draw_rect(Rect2(p, Vector2.ONE * taille), Color(Retro16.CYAN, 0.25))
	for cote in [-1.0, 1.0]:
		var x_bord := arene.position.x - 12.0 if cote < 0.0 else arene.end.x + 4.0
		for index in 18:
			var y_bord := lerpf(arene.position.y, arene.end.y - 28.0, float(index) / 17.0)
			draw_rect(Rect2(Retro16.pixel(Vector2(x_bord, y_bord)), Vector2(16.0, 28.0)),
				Color("3f7552") if index % 2 == 0 else Color("335e49"))
	draw_rect(arene, Retro16.OR, false, 6.0)
	draw_rect(arene.grow(-8.0), Retro16.PAPIER, false, 2.0)

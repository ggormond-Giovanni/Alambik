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
	var page := Rect2(limites.position - Vector2(30, 30), limites.size + Vector2(60, 60))
	draw_rect(Rect2(Vector2(-200, -200), get_viewport_rect().size + Vector2(400, 400)), Palette.FOND)
	draw_rect(page, Palette.PARCHEMIN_SOMBRE)

	# Lignes reglees de la page, plus pales au centre : le regard va au jeu.
	for i in 15:
		var y := page.position.y + page.size.y * float(i + 1) / 16.0
		var pale := 0.35 + 0.30 * absf(float(i) / 14.0 - 0.5) * 2.0
		draw_line(Vector2(page.position.x + 24.0, y), Vector2(page.end.x - 24.0, y),
			Color(Palette.PARCHEMIN_VEINE, pale), 2.0)
	# Marge d'annotation, comme sur une page de garde.
	draw_line(Vector2(page.position.x + 66.0, page.position.y + 20.0),
		Vector2(page.position.x + 66.0, page.end.y - 20.0), Color(0.55, 0.30, 0.34, 0.30), 2.0)

	for t in _taches:
		var c := Palette.PARCHEMIN_VEINE
		c.a = t["alpha"]
		draw_colored_polygon(Dessin.blob(t["position"], t["rayon"], t["graine"], 0.28), c)

	# Vignette : quatre bandes sombres qui referment la page sur elle-meme. Sans
	# elle, l'arene se dilue dans le fond et on ne sait plus ou sont ses bords.
	var epaisseur := 90.0
	for i in 8:
		var t := float(i) / 7.0
		var a := 0.30 * (1.0 - t)
		var creux := page.grow(-epaisseur * t)
		draw_rect(creux, Color(0, 0, 0, a), false, epaisseur / 7.0)

	# Bord de page : double filet, coins marques. C'est ce qui donne l'impression
	# de jouer dans un livre plutot que dans un rectangle.
	draw_rect(page, Palette.BORD_PAGE, false, 4.0)
	draw_rect(page.grow(-10.0), Color(Palette.BORD_PAGE, 0.45), false, 1.5)
	for coin in [page.position, Vector2(page.end.x, page.position.y), page.end, Vector2(page.position.x, page.end.y)]:
		draw_circle(coin, 9.0, Palette.BORD_PAGE)
		draw_circle(coin, 4.0, Palette.OR)

	# Numero de page, en bas a droite, discret.
	var police := ThemeDB.fallback_font
	draw_string(police, Vector2(page.end.x - 90.0, page.end.y + 44.0), "— %d —" % numero,
		HORIZONTAL_ALIGNMENT_RIGHT, 80, 26, Color(Palette.TEXTE_ATTENUE, 0.6))

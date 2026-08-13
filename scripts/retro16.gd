class_name Retro16
extends RefCounted

# Toute la direction artistique tient sur une grille commune. Les silhouettes
# restent ainsi nettes sur mobile et chaque nouvelle creature herite du meme
# langage sans demander une planche peinte supplementaire.

const PAS := 4.0
const ENCRE := Color("171126")
const OMBRE := Color("302040")
const PAPIER := Color("ffe6ad")
const OR := Color("ffb52e")
const ROSE := Color("ef476f")
const CYAN := Color("42d9c8")
const VIOLET := Color("9b72e8")
const VERT := Color("54c071")
const BLEU_NUIT := Color("263d4a")

static func pixel(position: Vector2) -> Vector2:
	return (position / PAS).round() * PAS

static func rectangle(canvas: CanvasItem, rect: Rect2, couleur: Color) -> void:
	var position := pixel(rect.position)
	var taille := (rect.size / PAS).round() * PAS
	canvas.draw_rect(Rect2(position, taille), couleur)

static func contour_rectangle(canvas: CanvasItem, rect: Rect2, fond: Color,
		bord: Color, epaisseur := 4.0) -> void:
	rectangle(canvas, rect, bord)
	rectangle(canvas, rect.grow(-epaisseur), fond)

static func polygone(canvas: CanvasItem, points: Array[Vector2], couleur: Color) -> void:
	var ajustes := PackedVector2Array()
	for point in points:
		ajustes.append(pixel(point))
	canvas.draw_colored_polygon(ajustes, couleur)

static func dessiner_fond_interface(canvas: CanvasItem, taille: Vector2,
		accent: Color, temps := 0.0, opacite := 1.0) -> void:
	rectangle(canvas, Rect2(Vector2.ZERO, taille), Color(ENCRE, opacite))
	var tuile := 64.0
	for y in range(0, ceili(taille.y / tuile)):
		for x in range(0, ceili(taille.x / tuile)):
			if (x + y) % 2 == 0:
				rectangle(canvas, Rect2(x * tuile, y * tuile, tuile, tuile),
					Color(OMBRE, 0.18 * opacite))
	var centre := pixel(Vector2(taille.x * 0.5, taille.y * 0.22))
	for index in 4:
		var largeur := 224.0 - index * 40.0
		var decalage := pixel(Vector2(sin(temps * 0.8 + index) * 8.0, index * 20.0))
		contour_rectangle(canvas, Rect2(centre + decalage - Vector2(largeur, largeur) * 0.5,
			Vector2(largeur, largeur)), Color(ENCRE, 0.0),
			Color(accent, (0.16 - index * 0.025) * opacite), 4.0)
	for y in range(0, int(taille.y), 8):
		canvas.draw_rect(Rect2(0.0, float(y), taille.x, 1.0),
			Color(0.01, 0.005, 0.02, 0.07 * opacite))
	dessiner_coins(canvas, taille, Color(accent, 0.42 * opacite), 18.0)

static func dessiner_coins(canvas: CanvasItem, taille: Vector2, couleur: Color,
		marge := 10.0) -> void:
	for coin in [Vector2(marge, marge), Vector2(taille.x - marge, marge),
			Vector2(marge, taille.y - marge), Vector2(taille.x - marge, taille.y - marge)]:
		var sx := 1.0 if coin.x < taille.x * 0.5 else -1.0
		var sy := 1.0 if coin.y < taille.y * 0.5 else -1.0
		rectangle(canvas, Rect2(coin, Vector2(sx * 36.0, sy * 4.0)), couleur)
		rectangle(canvas, Rect2(coin, Vector2(sx * 4.0, sy * 36.0)), couleur)

static func dessiner_heros(canvas: CanvasItem, anim: float, attaque: bool,
		direction: Vector2, teinte: Color) -> void:
	var image := int(anim * 9.0) % 4
	var pas_jambe: float = [-4.0, 0.0, 4.0, 0.0][image]
	var bob: float = [-2.0, 0.0, -2.0, 0.0][image]
	# Cape, capuche et yeux forment une lecture immediate en moins de dix aplats.
	rectangle(canvas, Rect2(-28.0, 8.0 + bob, 56.0, 32.0), Color("3b205f"))
	rectangle(canvas, Rect2(-24.0, -2.0 + bob, 48.0, 38.0), Color("512b78"))
	rectangle(canvas, Rect2(-20.0, -34.0 + bob, 40.0, 38.0), Color("6c3aa0"))
	rectangle(canvas, Rect2(-16.0, -25.0 + bob, 32.0, 24.0), ENCRE)
	rectangle(canvas, Rect2(-10.0, -18.0 + bob, 6.0, 6.0), OR)
	rectangle(canvas, Rect2(4.0, -18.0 + bob, 6.0, 6.0), OR)
	rectangle(canvas, Rect2(8.0, -46.0 + bob, 20.0, 12.0), Color("8e55bd"))
	rectangle(canvas, Rect2(20.0, -42.0 + bob, 12.0, 8.0), Color("bd7ee2"))
	rectangle(canvas, Rect2(-18.0 + pas_jambe, 34.0, 14.0, 12.0), ENCRE)
	rectangle(canvas, Rect2(4.0 - pas_jambe, 34.0, 14.0, 12.0), ENCRE)
	var main := pixel(direction.normalized() * (42.0 if attaque else 32.0))
	if attaque:
		var travers := direction.orthogonal() * (8.0 if image % 2 == 0 else -8.0)
		rectangle(canvas, Rect2(pixel(main + travers) - Vector2(10.0, 10.0),
			Vector2(20.0, 20.0)), Color(teinte, 0.38))
	rectangle(canvas, Rect2(main - Vector2(8.0, 8.0), Vector2(16.0, 16.0)),
		teinte.darkened(0.25))
	rectangle(canvas, Rect2(main - Vector2(4.0, 4.0), Vector2(8.0, 8.0)),
		teinte.lightened(0.35))

static func dessiner_ennemi(canvas: CanvasItem, donnees: Dictionary, anim: float,
		etat: String, direction: Vector2) -> void:
	var r: float = donnees["rayon"]
	var couleur: Color = donnees["couleur"]
	var forme := str(donnees.get("forme", "goutte"))
	var image := int(anim * 7.0) % 4
	var bob: float = [-4.0, 0.0, 4.0, 0.0][image]
	match forme:
		"plume": _ennemi_plume(canvas, r, couleur, direction, image)
		"ruban": _ennemi_ruban(canvas, r, couleur, direction, image)
		"dard": _ennemi_dard(canvas, r, couleur, direction, etat)
		"belier": _ennemi_belier(canvas, r, couleur, direction, etat)
		"masque": _ennemi_masque(canvas, r, couleur, bob)
		"miroir": _ennemi_miroir(canvas, r, couleur, anim, etat)
		"fiole": _ennemi_fiole(canvas, r, couleur, bob, etat)
		"fuseau": _ennemi_fuseau(canvas, r, couleur, anim)
		"phaseur": _ennemi_phaseur(canvas, r, couleur, bob, etat)
		_:
			_ennemi_goutte(canvas, r, couleur, bob, image)

static func _ennemi_goutte(canvas: CanvasItem, r: float, couleur: Color,
		bob: float, image: int) -> void:
	rectangle(canvas, Rect2(-r, -r * 0.66 + bob, r * 2.0, r * 1.48),
		couleur.darkened(0.30))
	rectangle(canvas, Rect2(-r * 0.78, -r * 0.84 + bob, r * 1.56, r * 1.38), couleur)
	for cote in [-1.0, 1.0]:
		rectangle(canvas, Rect2(float(cote) * r * 0.34 - 5.0,
			-r * 0.28 + bob, 10.0, 10.0), PAPIER)
	var pied := 4.0 if image % 2 == 0 else -4.0
	rectangle(canvas, Rect2(-r * 0.78 + pied, r * 0.44 + bob, 16.0, 12.0), OMBRE)
	rectangle(canvas, Rect2(r * 0.78 - 16.0 - pied, r * 0.44 + bob, 16.0, 12.0), OMBRE)

static func _ennemi_plume(canvas: CanvasItem, r: float, couleur: Color,
		direction: Vector2, image: int) -> void:
	canvas.draw_set_transform(Vector2.ZERO, direction.angle(), Vector2.ONE)
	rectangle(canvas, Rect2(-r * 1.25, -12.0, r * 2.5, 24.0), couleur.darkened(0.22))
	rectangle(canvas, Rect2(-r * 0.82, -20.0, r * 1.52, 40.0), couleur)
	for cran in 3:
		var x := -r * 0.52 + cran * r * 0.42
		rectangle(canvas, Rect2(x, -28.0 - (4.0 if (cran + image) % 2 else 0.0),
			12.0, 16.0), couleur.lightened(0.24))
	rectangle(canvas, Rect2(r * 0.52, -5.0, r * 0.72, 10.0), PAPIER)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _ennemi_ruban(canvas: CanvasItem, r: float, couleur: Color,
		direction: Vector2, image: int) -> void:
	canvas.draw_set_transform(Vector2.ZERO, direction.angle(), Vector2.ONE)
	for segment in 4:
		var y := (-8.0 if (segment + image) % 2 == 0 else 8.0)
		rectangle(canvas, Rect2(-r * 1.35 + segment * r * 0.58, y - 8.0,
			r * 0.72, 16.0), couleur.lightened(segment * 0.05))
	rectangle(canvas, Rect2(r * 0.62, -10.0, 20.0, 20.0), PAPIER)
	rectangle(canvas, Rect2(r * 0.68, -4.0, 8.0, 8.0), ENCRE)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _ennemi_dard(canvas: CanvasItem, r: float, couleur: Color,
		direction: Vector2, etat: String) -> void:
	canvas.draw_set_transform(Vector2.ZERO, direction.angle(), Vector2.ONE)
	var pointe := r * (1.65 if etat == "charger" else 1.25)
	polygone(canvas, [Vector2(-r, -r * 0.62), Vector2(r * 0.48, -r * 0.62),
		Vector2(pointe, 0.0), Vector2(r * 0.48, r * 0.62), Vector2(-r, r * 0.62)],
		couleur)
	rectangle(canvas, Rect2(-r * 0.62, -r * 0.36, r * 0.92, r * 0.72),
		couleur.lightened(0.22))
	rectangle(canvas, Rect2(r * 0.16, -5.0, 10.0, 10.0), PAPIER)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _ennemi_belier(canvas: CanvasItem, r: float, couleur: Color,
		direction: Vector2, etat: String) -> void:
	canvas.draw_set_transform(Vector2.ZERO, direction.angle(), Vector2.ONE)
	rectangle(canvas, Rect2(-r, -r * 0.66, r * 1.65, r * 1.32), couleur)
	rectangle(canvas, Rect2(r * 0.35, -r * 0.48, r * (0.92 if etat == "charger" else 0.65),
		r * 0.96), PAPIER.darkened(0.12))
	for cote in [-1.0, 1.0]:
		rectangle(canvas, Rect2(-r * 0.88, float(cote) * r * 0.68 - 8.0,
			r * 0.72, 16.0), couleur.darkened(0.30))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _ennemi_masque(canvas: CanvasItem, r: float, couleur: Color, bob: float) -> void:
	contour_rectangle(canvas, Rect2(-r * 0.82, -r + bob, r * 1.64, r * 1.86),
		couleur.darkened(0.20), couleur.lightened(0.24), 8.0)
	rectangle(canvas, Rect2(-r * 0.66, -r * 0.34 + bob, r * 1.32, r * 0.46), PAPIER)
	for fente in [-0.42, 0.0, 0.42]:
		rectangle(canvas, Rect2(r * float(fente) - 4.0, -r * 0.34 + bob, 8.0,
			r * 0.46), ENCRE)
	for cote in [-1.0, 1.0]:
		rectangle(canvas, Rect2(float(cote) * r * 0.88 - 6.0, -12.0 + bob, 12.0, 28.0),
			couleur.lightened(0.22))

static func _ennemi_miroir(canvas: CanvasItem, r: float, couleur: Color,
		anim: float, etat: String) -> void:
	var pulsation := 8.0 if etat == "pulse" and int(anim * 12.0) % 2 == 0 else 0.0
	polygone(canvas, [Vector2(0.0, -r - pulsation), Vector2(r + pulsation, 0.0),
		Vector2(0.0, r + pulsation), Vector2(-r - pulsation, 0.0)], couleur.darkened(0.30))
	polygone(canvas, [Vector2(0.0, -r * 0.72), Vector2(r * 0.72, 0.0),
		Vector2(0.0, r * 0.72), Vector2(-r * 0.72, 0.0)], PAPIER)
	rectangle(canvas, Rect2(-r * 0.44, -8.0, r * 0.88, 16.0), couleur)
	rectangle(canvas, Rect2(-4.0, -r * 0.44, 8.0, r * 0.88), couleur)

static func _ennemi_fiole(canvas: CanvasItem, r: float, couleur: Color,
		bob: float, etat: String) -> void:
	var gonflement := 8.0 if etat == "gonfler" else 0.0
	rectangle(canvas, Rect2(-12.0, -r - 10.0, 24.0, 20.0), PAPIER.darkened(0.20))
	contour_rectangle(canvas, Rect2(-r * 0.72 - gonflement, -r * 0.46 + bob,
		r * 1.44 + gonflement * 2.0, r * 1.36), couleur, couleur.lightened(0.28), 8.0)
	rectangle(canvas, Rect2(-r * 0.52, r * 0.02 + bob, r * 1.04, r * 0.60),
		couleur.lightened(0.20))
	for x in [-12.0, 8.0]:
		rectangle(canvas, Rect2(x, bob - 4.0, 8.0, 8.0), PAPIER)

static func _ennemi_fuseau(canvas: CanvasItem, r: float, couleur: Color, anim: float) -> void:
	var decalage := 4.0 if int(anim * 6.0) % 2 == 0 else -4.0
	rectangle(canvas, Rect2(-12.0, -r - 10.0, 24.0, r * 2.0 + 20.0), couleur)
	rectangle(canvas, Rect2(-r, -12.0 + decalage, r * 2.0, 24.0),
		couleur.lightened(0.24))
	rectangle(canvas, Rect2(-6.0, -6.0, 12.0, 12.0), PAPIER)
	for cote in [-1.0, 1.0]:
		rectangle(canvas, Rect2(float(cote) * r * 0.76 - 4.0, -r * 0.72,
			8.0, r * 1.44), Color(CYAN, 0.62))

static func _ennemi_phaseur(canvas: CanvasItem, r: float, couleur: Color,
		bob: float, etat: String) -> void:
	var alpha := 0.56 if etat == "phase" else 1.0
	for index in 4:
		var cote := -1.0 if index % 2 == 0 else 1.0
		rectangle(canvas, Rect2(cote * (10.0 + index * 7.0) - 10.0,
			-r + index * 12.0 + bob, 20.0, r * 1.22),
			Color(couleur, alpha * (0.92 - index * 0.14)))
	rectangle(canvas, Rect2(-10.0, -10.0 + bob, 20.0, 20.0), PAPIER)
	rectangle(canvas, Rect2(-4.0, -4.0 + bob, 8.0, 8.0), VIOLET)

static func dessiner_boss(canvas: CanvasItem, donnees: Dictionary, anim: float,
		phase: int, motif: String) -> void:
	var r: float = donnees["rayon"]
	var couleur: Color = donnees["couleur"]
	var image := int(anim * (9.0 if motif != "pause" else 5.0)) % 4
	var bob: float = [-4.0, 0.0, 4.0, 0.0][image]
	var attaque := motif != "pause"
	var echelle := Vector2(1.06, 0.94) if attaque and image % 2 == 0 else Vector2.ONE
	canvas.draw_set_transform(Vector2(0.0, bob), 0.0, echelle)
	if str(donnees.get("rang_boss", "")) == "miniboss":
		_dessiner_miniboss(canvas, str(donnees.get("silhouette", "correcteur")), r,
			couleur, anim, image)
	else:
		_dessiner_signature(canvas, posmod(int(donnees.get("ornement", 0)), 10), r,
			couleur, anim, image)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if phase == 2:
		for index in 4:
			var p := pixel(Vector2.RIGHT.rotated(anim + index * PI * 0.5) * r * 1.20)
			rectangle(canvas, Rect2(p - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), ROSE)

static func _dessiner_miniboss(canvas: CanvasItem, silhouette: String, r: float,
		couleur: Color, anim: float, image: int) -> void:
	match silhouette:
		"rature":
			for sens in [-1.0, 1.0]:
				canvas.draw_set_transform(Vector2.ZERO, float(sens) * PI * 0.20, Vector2.ONE)
				rectangle(canvas, Rect2(-r, -18.0, r * 2.0, 36.0), couleur)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"errata":
			for index in 3:
				var p := pixel(Vector2.RIGHT.rotated(anim * (0.7 + index * 0.1) + index * TAU / 3.0) * r * 0.42)
				contour_rectangle(canvas, Rect2(p - Vector2(42.0, 42.0), Vector2(84.0, 84.0)),
					couleur.lightened(index * 0.08), OMBRE, 8.0)
		"correcteur":
			contour_rectangle(canvas, Rect2(-r * 0.88, -r * 0.82, r * 1.76, r * 1.64),
				couleur, couleur.lightened(0.28), 8.0)
			rectangle(canvas, Rect2(-r * 0.72, -18.0, r * 1.44, 36.0), PAPIER)
			for x in [-0.46, 0.0, 0.46]:
				rectangle(canvas, Rect2(r * float(x) - 5.0, -18.0, 10.0, 36.0), OMBRE)
		"reliure":
			for cote in [-1.0, 1.0]:
				var y := float(cote) * 20.0
				contour_rectangle(canvas, Rect2(-r, y - 38.0, r * 2.0, 76.0),
					couleur, PAPIER, 8.0)
			for dent in 5:
				rectangle(canvas, Rect2(-r * 0.72 + dent * r * 0.36, -8.0, 16.0, 28.0), OMBRE)
		"virgule":
			contour_rectangle(canvas, Rect2(-r * 0.72, -r * 0.76, r * 1.44, r * 1.44),
				couleur, couleur.lightened(0.28), 8.0)
			for index in 4:
				rectangle(canvas, Rect2(r * (0.42 + index * 0.18), r * (0.18 + index * 0.17),
					28.0 - index * 4.0, 28.0 - index * 4.0), couleur.lightened(index * 0.08))
		"index":
			rectangle(canvas, Rect2(-r * 0.58, -10.0, r * 1.16, r * 0.82), couleur)
			for doigt in 5:
				var x := (float(doigt) - 2.0) * r * 0.25
				var haut := r * (0.66 + (2 - absi(doigt - 2)) * 0.12)
				rectangle(canvas, Rect2(x - 9.0, -haut, 18.0, haut), couleur.lightened(0.24))
		"marge":
			rectangle(canvas, Rect2(-22.0, -r, 44.0, r * 2.0), couleur)
			for cote in [-1.0, 1.0]:
				rectangle(canvas, Rect2(float(cote) * r * 0.84 - 8.0, -r, 16.0, r * 2.0), PAPIER)
				rectangle(canvas, Rect2(float(cote) * r * 0.48, -r, float(cote) * r * 0.36, 12.0), PAPIER)
				rectangle(canvas, Rect2(float(cote) * r * 0.48, r - 12.0, float(cote) * r * 0.36, 12.0), PAPIER)
		"enlumineur":
			for index in 12:
				var p := pixel(Vector2.RIGHT.rotated(anim * 0.18 + index * TAU / 12.0) * r * 0.76)
				rectangle(canvas, Rect2(p - Vector2(13.0, 13.0), Vector2(26.0, 26.0)), couleur)
			contour_rectangle(canvas, Rect2(-r * 0.54, -r * 0.54, r * 1.08, r * 1.08),
				PAPIER, couleur, 8.0)
		"signet":
			contour_rectangle(canvas, Rect2(-r * 0.74, -r * 0.74, r * 1.48, r * 1.48),
				couleur, PAPIER, 10.0)
			for index in 3:
				rectangle(canvas, Rect2(-18.0 + index * 12.0, r * (0.72 + index * 0.14),
					36.0 - index * 8.0, 20.0), couleur)
		"copiste":
			for cote in [-1.0, 1.0]:
				var x := float(cote) * r * 0.42
				contour_rectangle(canvas, Rect2(x - r * 0.52, -r * 0.64, r * 1.04, r * 1.28),
					couleur.lightened(0.06 if cote > 0.0 else 0.0), PAPIER, 8.0)
				rectangle(canvas, Rect2(x + float(cote) * 10.0 - 6.0, -10.0, 12.0, 12.0), OMBRE)
		_:
			contour_rectangle(canvas, Rect2(-r * 0.82, -r * 0.82, r * 1.64, r * 1.64),
				couleur, PAPIER, 8.0)
	# Le coeur commun relie les dix silhouettes a une meme famille visuelle.
	rectangle(canvas, Rect2(-18.0, -18.0, 36.0, 36.0), ENCRE)
	rectangle(canvas, Rect2(-8.0, -8.0, 16.0, 16.0), ROSE if image % 2 == 0 else PAPIER)

static func _dessiner_signature(canvas: CanvasItem, type: int, r: float,
		couleur: Color, anim: float, image: int) -> void:
	# Les dix signatures partagent une masse imposante mais jamais la meme couronne.
	contour_rectangle(canvas, Rect2(-r * 0.78, -r * 0.64, r * 1.56, r * 1.40),
		couleur.darkened(0.22), couleur.lightened(0.22), 12.0)
	match type:
		0:
			for index in 5:
				var x := (float(index) - 2.0) * r * 0.30
				rectangle(canvas, Rect2(x - 10.0, -r * (0.88 + absf(float(index) - 2.0) * 0.10),
					20.0, r * 0.54), PAPIER if index % 2 == 0 else VIOLET)
		1:
			for cote in [-1.0, 1.0]:
				polygone(canvas, [Vector2(float(cote) * r * 0.30, -r * 0.52),
					Vector2(float(cote) * r * 0.84, -r * 1.02),
					Vector2(float(cote) * r * 0.68, -r * 0.30)], ROSE)
		2:
			for index in 5:
				var angle := -PI + float(index) * PI / 4.0
				var p := Vector2(cos(angle), sin(angle)) * r * 0.72
				polygone(canvas, [p + Vector2(0.0, -34.0), p + Vector2(18.0, 18.0),
					p + Vector2(-18.0, 18.0)], CYAN)
		3:
			polygone(canvas, [Vector2(-12.0, -r), Vector2(r * 0.28, -r * 0.20),
				Vector2(0.0, -r * 0.20), Vector2(16.0, r * 0.54),
				Vector2(-r * 0.32, -r * 0.08), Vector2(-4.0, -r * 0.08)], OR)
		4:
			for tete in [-1.0, 0.0, 1.0]:
				var x := float(tete) * r * 0.55
				rectangle(canvas, Rect2(x - 24.0, -r * (0.92 + 0.14 * absf(float(tete))),
					48.0, 64.0), VERT)
				rectangle(canvas, Rect2(x - 7.0, -r * 0.80, 14.0, 14.0), PAPIER)
		5:
			for visage in 5:
				var p := pixel(Vector2.RIGHT.rotated(anim * 0.15 + visage * TAU / 5.0) * r * 0.64)
				contour_rectangle(canvas, Rect2(p - Vector2(24.0, 20.0), Vector2(48.0, 40.0)),
					VIOLET, PAPIER, 6.0)
		6:
			for cote in [-1.0, 1.0]:
				polygone(canvas, [Vector2(float(cote) * r * 0.52, -r * 0.42),
					Vector2(float(cote) * r * 1.14, -r * 0.74),
					Vector2(float(cote) * r * 0.92, r * 0.50),
					Vector2(float(cote) * r * 0.44, r * 0.22)], OMBRE)
		7:
			for index in 6:
				var p := pixel(Vector2.RIGHT.rotated(index * TAU / 6.0) * r * 0.82)
				contour_rectangle(canvas, Rect2(p - Vector2(18.0, 18.0), Vector2(36.0, 36.0)),
					ENCRE, CYAN, 6.0)
		8:
			rectangle(canvas, Rect2(-r * 0.58, -24.0, r * 1.16, 48.0), ENCRE)
			for dent in 6:
				var x := -r * 0.46 + dent * r * 0.18
				rectangle(canvas, Rect2(x, -24.0 if dent % 2 == 0 else 8.0, 12.0, 20.0), PAPIER)
		_:
			rectangle(canvas, Rect2(-30.0, -r * 1.02, 60.0, r * 0.48), PAPIER.darkened(0.18))
			contour_rectangle(canvas, Rect2(-r * 0.48, -r * 0.72, r * 0.96, r * 1.18),
				Color(OR, 0.82), PAPIER, 8.0)
			for bulle in 3:
				var p := pixel(Vector2(-22.0 + bulle * 22.0,
					-r * 0.28 + fmod(anim * (28.0 + bulle * 5.0), r * 0.62)))
				rectangle(canvas, Rect2(p, Vector2(10.0, 10.0)), PAPIER)
	# Oeil/creuset central anime : point focal commun aux boss de campagne.
	rectangle(canvas, Rect2(-34.0, -24.0, 68.0, 48.0), ENCRE)
	rectangle(canvas, Rect2(-18.0, -14.0, 36.0, 28.0), PAPIER)
	rectangle(canvas, Rect2((-5.0 if image < 2 else 5.0) - 6.0, -10.0, 12.0, 20.0),
		ROSE)

static func dessiner_projectile(canvas: CanvasItem, trainee: Array[Vector2], position: Vector2,
		couleur: Color, hostile: bool) -> void:
	for index in range(trainee.size() - 1, -1, -2):
		var relatif := pixel(trainee[index] - position)
		var taille := maxf(4.0, 12.0 - float(index))
		rectangle(canvas, Rect2(relatif - Vector2.ONE * taille * 0.5,
			Vector2.ONE * taille), Color(couleur, 0.32 + 0.05 * index))
	rectangle(canvas, Rect2(-14.0, -14.0, 28.0, 28.0), couleur.darkened(0.28))
	rectangle(canvas, Rect2(-9.0, -9.0, 18.0, 18.0), couleur)
	rectangle(canvas, Rect2(-4.0, -4.0, 8.0, 8.0), ROSE if hostile else PAPIER)

static func dessiner_cadre(canvas: CanvasItem, taille: Vector2, anim: float) -> void:
	for y in range(0, int(taille.y), 8):
		canvas.draw_rect(Rect2(0.0, float(y), taille.x, 1.0), Color(0.02, 0.01, 0.04, 0.055))
	dessiner_coins(canvas, taille, Color("7e5ab5"))
	var police := ThemeDB.fallback_font
	var pulse := 0.72 + sin(anim * 3.0) * 0.18
	canvas.draw_string(police, Vector2(0.0, taille.y - 24.0), "ALAMBIC  •  16-BIT",
		HORIZONTAL_ALIGNMENT_CENTER, taille.x, 18, Color(OR, pulse))

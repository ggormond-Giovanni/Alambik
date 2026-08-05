class_name Dessin
extends RefCounted

# Banque de formes. Le jeu tourne sans un seul fichier image : tout ce qu'on
# voit est trace ici. Chaque fonction prend le CanvasItem appelant, ce qui
# permet de composer des silhouettes a partir de primitives partagees.

# Un halo : plusieurs disques concentriques d'alpha decroissant. Sans texture,
# c'est ce qui remplace un degrade radial, et ca reste bon marche en 2D.
static func halo(ci: CanvasItem, centre: Vector2, rayon: float, couleur: Color, couches := 5) -> void:
	for i in range(couches, 0, -1):
		var t := float(i) / float(couches)
		var c := couleur
		c.a = couleur.a * pow(1.0 - t, 2.0) * 0.55
		ci.draw_circle(centre, rayon * t, c)

static func polygone_regulier(centre: Vector2, rayon: float, cotes: int, rotation := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in cotes:
		var angle := rotation + TAU * float(i) / float(cotes)
		points.append(centre + Vector2(cos(angle), sin(angle)) * rayon)
	return points

static func etoile(centre: Vector2, rayon_ext: float, rayon_int: float, pointes: int, rotation := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in pointes * 2:
		var angle := rotation + TAU * float(i) / float(pointes * 2)
		var r := rayon_ext if i % 2 == 0 else rayon_int
		points.append(centre + Vector2(cos(angle), sin(angle)) * r)
	return points

# Silhouette de goutte : ronde en bas, pointue vers la direction donnee.
static func goutte(centre: Vector2, rayon: float, angle: float, allongement := 1.7) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 22
	for i in segments:
		var t := TAU * float(i) / float(segments)
		var r := rayon * (1.0 + 0.55 * cos(t))
		var p := Vector2(cos(t), sin(t)) * r
		p.x *= allongement * 0.62 + 0.38
		points.append(centre + p.rotated(angle))
	return points

# Contour organique legerement bruite : un blob d'encre plutot qu'un cercle.
static func blob(centre: Vector2, rayon: float, graine: int, amplitude := 0.16, phase := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 26
	for i in segments:
		var t := TAU * float(i) / float(segments)
		var bruit := sin(t * 3.0 + graine) * 0.6 + sin(t * 5.0 - graine * 1.7 + phase) * 0.4
		points.append(centre + Vector2(cos(t), sin(t)) * rayon * (1.0 + amplitude * bruit))
	return points

static func plume(longueur: float, largeur: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := 14
	for i in segments + 1:
		var t := float(i) / float(segments)
		var x := lerpf(-longueur * 0.5, longueur * 0.5, t)
		points.append(Vector2(x, -largeur * sin(PI * t) * (1.0 - t * 0.35)))
	for i in range(segments, -1, -1):
		var t := float(i) / float(segments)
		var x := lerpf(-longueur * 0.5, longueur * 0.5, t)
		points.append(Vector2(x, largeur * sin(PI * t) * (1.0 - t * 0.15)))
	return points

static func dard(longueur: float, largeur: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(longueur, 0.0),
		Vector2(-longueur * 0.35, -largeur),
		Vector2(-longueur * 0.75, 0.0),
		Vector2(-longueur * 0.35, largeur),
	])

static func eclair(depuis: Vector2, vers: Vector2, ecart: float, graine: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var alea := RandomNumberGenerator.new()
	alea.seed = graine
	var segments := 7
	var perpendiculaire := (vers - depuis).normalized().orthogonal()
	for i in segments + 1:
		var t := float(i) / float(segments)
		var base := depuis.lerp(vers, t)
		var devie := 0.0 if i == 0 or i == segments else alea.randf_range(-ecart, ecart)
		points.append(base + perpendiculaire * devie)
	return points

static func contour(ci: CanvasItem, points: PackedVector2Array, couleur: Color, epaisseur := 3.0) -> void:
	var boucle := points.duplicate()
	if boucle.size() > 0:
		boucle.append(boucle[0])
	ci.draw_polyline(boucle, couleur, epaisseur, true)

# Icone d'un reactif, dessinee a partir de son glyphe. Aucun fichier image :
# ajouter un reactif ne demande pas d'ouvrir un logiciel de dessin.
static func glyphe(ci: CanvasItem, nom: String, centre: Vector2, taille: float, couleur: Color) -> void:
	match nom:
		"eventail":
			for k in [-1.0, 0.0, 1.0]:
				var d := Vector2(0, -taille).rotated(k * 0.42)
				ci.draw_line(centre - d * 0.35, centre + d, couleur, 4.0, true)
		"zigzag":
			ci.draw_polyline(PackedVector2Array([
				centre + Vector2(-taille, taille * 0.6),
				centre + Vector2(-taille * 0.2, -taille * 0.5),
				centre + Vector2(taille * 0.35, taille * 0.35),
				centre + Vector2(taille, -taille * 0.7)]), couleur, 4.0, true)
		"lance":
			ci.draw_line(centre + Vector2(0, taille), centre + Vector2(0, -taille), couleur, 4.0, true)
			ci.draw_colored_polygon(PackedVector2Array([
				centre + Vector2(0, -taille * 1.25),
				centre + Vector2(-taille * 0.35, -taille * 0.5),
				centre + Vector2(taille * 0.35, -taille * 0.5)]), couleur)
		"flamme":
			var f := PackedVector2Array()
			for i in 18:
				var t := TAU * float(i) / 18.0
				var r := taille * (0.75 + 0.35 * cos(t * 2.0)) * (1.0 - 0.35 * cos(t))
				f.append(centre + Vector2(sin(t) * r * 0.8, -cos(t) * r))
			ci.draw_colored_polygon(f, couleur)
		"cristal":
			ci.draw_colored_polygon(etoile(centre, taille, taille * 0.32, 6, -PI / 2.0), couleur)
		"eclair":
			ci.draw_colored_polygon(PackedVector2Array([
				centre + Vector2(taille * 0.25, -taille),
				centre + Vector2(-taille * 0.55, taille * 0.1),
				centre + Vector2(-taille * 0.05, taille * 0.1),
				centre + Vector2(-taille * 0.3, taille),
				centre + Vector2(taille * 0.6, -taille * 0.15),
				centre + Vector2(taille * 0.05, -taille * 0.15)]), couleur)
		"goutte":
			ci.draw_colored_polygon(goutte(centre, taille * 0.62, -PI / 2.0, 1.5), couleur)
		"eclats":
			for k in 3:
				var a := -PI / 2.0 + float(k) * TAU / 3.0
				ci.draw_colored_polygon(PackedVector2Array([
					centre + Vector2(cos(a), sin(a)) * taille,
					centre + Vector2(cos(a + 0.5), sin(a + 0.5)) * taille * 0.35,
					centre + Vector2(cos(a - 0.5), sin(a - 0.5)) * taille * 0.35]), couleur)
		"triple_barre":
			for k in 3:
				var y := centre.y + (float(k) - 1.0) * taille * 0.55
				ci.draw_line(Vector2(centre.x - taille, y), Vector2(centre.x + taille * (1.0 - 0.25 * k), y), couleur, 4.0, true)
		"masse":
			ci.draw_line(centre + Vector2(taille * 0.6, taille), centre + Vector2(-taille * 0.2, -taille * 0.2), couleur, 5.0, true)
			ci.draw_colored_polygon(polygone_regulier(centre + Vector2(-taille * 0.35, -taille * 0.45), taille * 0.6, 6, 0.3), couleur)
		"patte":
			ci.draw_circle(centre + Vector2(0, taille * 0.3), taille * 0.5, couleur)
			for k in 3:
				ci.draw_circle(centre + Vector2((float(k) - 1.0) * taille * 0.55, -taille * 0.45), taille * 0.22, couleur)
		"fiole":
			ci.draw_colored_polygon(PackedVector2Array([
				centre + Vector2(-taille * 0.28, -taille),
				centre + Vector2(taille * 0.28, -taille),
				centre + Vector2(taille * 0.28, -taille * 0.3),
				centre + Vector2(taille * 0.65, taille * 0.75),
				centre + Vector2(-taille * 0.65, taille * 0.75)]), couleur)
		"oeil":
			ci.draw_colored_polygon(PackedVector2Array([
				centre + Vector2(-taille, 0),
				centre + Vector2(0, -taille * 0.62),
				centre + Vector2(taille, 0),
				centre + Vector2(0, taille * 0.62)]), couleur)
			ci.draw_circle(centre, taille * 0.28, Palette.FOND)
		"hexagone":
			contour(ci, polygone_regulier(centre, taille, 6, PI / 6.0), couleur, 4.0)
		"vague":
			for k in 2:
				var v := PackedVector2Array()
				for i in 13:
					var t := float(i) / 12.0
					v.append(centre + Vector2(lerpf(-taille, taille, t), sin(t * TAU) * taille * 0.3 + (float(k) - 0.5) * taille * 0.7))
				ci.draw_polyline(v, couleur, 3.5, true)
		"nuage":
			for p in [Vector2(-taille * 0.5, taille * 0.1), Vector2(taille * 0.5, taille * 0.1), Vector2(0, -taille * 0.35)]:
				ci.draw_circle(centre + p, taille * 0.55, couleur)
		_:
			ci.draw_circle(centre, taille * 0.7, couleur)

class_name Geometrie
extends RefCounted

# Intersection segment / rectangle, algorithme de Liang-Barsky.
#
# Pourquoi ne pas interroger le moteur physique : un raycast lance sur les blocs
# de la salle renvoyait "libre" alors qu'un bloc coupait bel et bien la ligne,
# et le bot tirait dans la pierre pendant deux minutes. Un calcul explicite se
# teste, lui.

static func segment_coupe_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	var bords := [
		[-d.x, a.x - rect.position.x],
		[d.x, rect.end.x - a.x],
		[-d.y, a.y - rect.position.y],
		[d.y, rect.end.y - a.y],
	]
	for bord in bords:
		var p: float = bord[0]
		var q: float = bord[1]
		if absf(p) < 0.00001:
			# Segment parallele a ce bord : hors de la bande, aucune intersection.
			if q < 0.0:
				return false
			continue
		var r := q / p
		if p < 0.0:
			if r > t1:
				return false
			t0 = maxf(t0, r)
		else:
			if r < t0:
				return false
			t1 = minf(t1, r)
	return t0 <= t1

# La marge compte : un projectile a un rayon, donc une ligne qui frole un bloc
# de quelques pixels est en realite bouchee.
static func ligne_libre(a: Vector2, b: Vector2, obstacles: Array, marge := 0.0) -> bool:
	for rect in obstacles:
		if segment_coupe_rect(a, b, (rect as Rect2).grow(marge)):
			return false
	return true

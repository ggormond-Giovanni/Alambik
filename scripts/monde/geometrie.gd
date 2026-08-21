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

# Une limite d'arene decrit le bord du sol, mais un personnage est un disque.
# Contraindre son centre sans son rayon lui laisse visuellement la moitie du
# corps dans le mur.
static func contraindre_dans_rect(position: Vector2, rect: Rect2, rayon: float) -> Vector2:
	var interieur := rect.grow(-maxf(0.0, rayon))
	if interieur.size.x < 0.0 or interieur.size.y < 0.0:
		return rect.get_center()
	return Vector2(clampf(position.x, interieur.position.x, interieur.end.x),
		clampf(position.y, interieur.position.y, interieur.end.y))

# Ou viser pour toucher une cible en mouvement. L'anticipation est bornee : au
# dela, une creature qui change d'avis fait rater tous les tirs au lieu de
# quelques-uns. Partagee par le heros et le familier, qui tiraient chacun leur
# propre version — celle du familier partait en plus du mauvais point.
static func point_anticipe(position_cible: Vector2, vitesse_cible: Vector2,
		origine: Vector2, vitesse_tir: float) -> Vector2:
	var vol := minf(Reglages.ANTICIPATION_DUREE_MAX,
		origine.distance_to(position_cible) / maxf(80.0, vitesse_tir))
	return position_cible + vitesse_cible * vol * Reglages.ANTICIPATION_PART

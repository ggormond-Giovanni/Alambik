class_name Ciblage
extends RefCounted

static func plus_proche(depuis: Vector2, positions: Array[Vector2]) -> int:
	var meilleur := -1
	var meilleure_distance := INF
	for i in positions.size():
		var d := depuis.distance_squared_to(positions[i])
		if d < meilleure_distance:
			meilleure_distance = d
			meilleur = i
	return meilleur

extends Control

var couleur := Palette.ESSENCE

func configurer(couleur_: Color) -> void:
	couleur = couleur_
	custom_minimum_size = Vector2(0, 980)
	queue_redraw()

func _draw() -> void:
	var x := size.x * 0.5
	# Un tronc vertical, lisible sans glissement horizontal sur telephone.
	draw_line(Vector2(x, 105), Vector2(x, 855), Color(couleur, 0.32), 22.0, true)
	for y in [105.0, 355.0, 605.0, 855.0]:
		Dessin.halo(self, Vector2(x, y), 84.0, Color(couleur, 0.22), 3)
		draw_circle(Vector2(x, y), 42.0, Color(0.055, 0.042, 0.085))
		draw_arc(Vector2(x, y), 42.0, 0.0, TAU, 28, Color(couleur, 0.75), 4.0, true)

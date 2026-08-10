extends Control

var couleur := Palette.ESSENCE
var nombre := 4

func configurer(couleur_: Color, nombre_: int) -> void:
	couleur = couleur_
	nombre = nombre_
	custom_minimum_size = Vector2(0, maxf(730.0, float(nombre) * 230.0 + 30.0))
	queue_redraw()

func _draw() -> void:
	var x := size.x * 0.5
	# Un tronc vertical, lisible sans glissement horizontal sur telephone.
	var dernier_y := 105.0 + float(nombre - 1) * 230.0
	draw_line(Vector2(x, 105), Vector2(x, dernier_y), Color(couleur, 0.32), 22.0, true)
	for index in nombre:
		var y := 105.0 + float(index) * 230.0
		Dessin.halo(self, Vector2(x, y), 84.0, Color(couleur, 0.22), 3)
		draw_circle(Vector2(x, y), 42.0, Color(0.055, 0.042, 0.085))
		draw_arc(Vector2(x, y), 42.0, 0.0, TAU, 28, Color(couleur, 0.75), 4.0, true)

class_name OngletMenu
extends Button

var symbole := "stats"
var actif := false:
	set(valeur):
		actif = valeur
		queue_redraw()

func configurer(symbole_: String) -> void:
	symbole = symbole_
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(0.0, 122.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	queue_redraw()

func _draw() -> void:
	var centre := size * Vector2(0.5, 0.46)
	var couleur := Palette.OR if actif else Palette.TEXTE_ATTENUE
	if actif:
		var fond := Rect2(Vector2(5.0, 4.0), size - Vector2(10.0, 8.0))
		draw_rect(fond, Color(Palette.OR, 0.16))
		draw_rect(fond, Color(Palette.OR, 0.72), false, 3.0)
		draw_circle(Vector2(size.x * 0.5, size.y - 10.0), 4.0, Palette.OR)
	match symbole:
		"boutique": _dessiner_boutique(centre, 30.0, couleur)
		"stuff": _dessiner_bouclier(centre, 31.0, couleur)
		"grimoire": _dessiner_livre(centre, 31.0, couleur)
		"sorts": _dessiner_sort(centre, 30.0, couleur)
		"arbre": _dessiner_arbre(centre, 30.0, couleur)

func _dessiner_boutique(centre: Vector2, taille: float, couleur: Color) -> void:
	var corps := Rect2(centre + Vector2(-taille, -8.0), Vector2(taille * 2.0, taille * 1.15))
	draw_rect(corps, Color(couleur, 0.28))
	draw_rect(corps, couleur, false, 4.0)
	draw_arc(centre + Vector2(0.0, -8.0), taille * 0.52, PI, TAU, 22, couleur, 4.0, true)
	draw_line(centre + Vector2(-taille, 3.0), centre + Vector2(taille, 3.0), couleur, 4.0)

func _dessiner_bouclier(centre: Vector2, taille: float, couleur: Color) -> void:
	var forme := PackedVector2Array([
		centre + Vector2(-taille, -taille * 0.72), centre + Vector2(0.0, -taille),
		centre + Vector2(taille, -taille * 0.72), centre + Vector2(taille * 0.78, taille * 0.46),
		centre + Vector2(0.0, taille), centre + Vector2(-taille * 0.78, taille * 0.46)])
	draw_colored_polygon(forme, Color(couleur, 0.28))
	Dessin.contour(self, forme, couleur, 4.0)
	draw_line(centre + Vector2(0.0, -taille * 0.72), centre + Vector2(0.0, taille * 0.65), couleur, 3.0)

func _dessiner_fiole(centre: Vector2, taille: float, couleur: Color) -> void:
	draw_rect(Rect2(centre + Vector2(-8.0, -taille), Vector2(16.0, 19.0)), couleur)
	var ballon := PackedVector2Array([
		centre + Vector2(-8.0, -12.0), centre + Vector2(-24.0, 18.0),
		centre + Vector2(-17.0, 29.0), centre + Vector2(17.0, 29.0),
		centre + Vector2(24.0, 18.0), centre + Vector2(8.0, -12.0)])
	draw_colored_polygon(ballon, Color(couleur, 0.34))
	Dessin.contour(self, ballon, couleur, 4.0)
	draw_line(centre + Vector2(-17.0, 15.0), centre + Vector2(17.0, 15.0), couleur, 3.0, true)

func _dessiner_sort(centre: Vector2, taille: float, couleur: Color) -> void:
	draw_colored_polygon(Dessin.etoile(centre, taille, taille * 0.42, 6, -PI / 2.0), Color(couleur, 0.38))
	Dessin.contour(self, Dessin.etoile(centre, taille, taille * 0.42, 6, -PI / 2.0), couleur, 4.0)
	draw_circle(centre, 8.0, couleur)

func _dessiner_arbre(centre: Vector2, taille: float, couleur: Color) -> void:
	draw_line(centre + Vector2(0.0, taille), centre + Vector2(0.0, -taille), couleur, 5.0, true)
	for cote in [-1.0, 1.0]:
		draw_line(centre + Vector2(0.0, 4.0), centre + Vector2(cote * 25.0, -16.0), couleur, 4.0, true)
		draw_circle(centre + Vector2(cote * 26.0, -18.0), 9.0, couleur)
	draw_circle(centre + Vector2(0.0, -taille), 10.0, couleur)

func _dessiner_livre(centre: Vector2, taille: float, couleur: Color) -> void:
	var gauche := Rect2(centre + Vector2(-taille, -23.0), Vector2(taille - 2.0, 48.0))
	var droite := Rect2(centre + Vector2(2.0, -23.0), Vector2(taille - 2.0, 48.0))
	for page in [gauche, droite]:
		draw_rect(page, Color(couleur, 0.26))
		draw_rect(page, couleur, false, 3.0)
	draw_line(centre + Vector2(0.0, -23.0), centre + Vector2(0.0, 27.0), couleur, 4.0)

func _dessiner_couronne(centre: Vector2, taille: float, couleur: Color) -> void:
	var couronne := PackedVector2Array([
		centre + Vector2(-taille, 20.0), centre + Vector2(-taille, -17.0),
		centre + Vector2(-taille * 0.45, 1.0), centre + Vector2(0.0, -taille),
		centre + Vector2(taille * 0.45, 1.0), centre + Vector2(taille, -17.0),
		centre + Vector2(taille, 20.0)])
	draw_colored_polygon(couronne, Color(couleur, 0.32))
	Dessin.contour(self, couronne, couleur, 4.0)

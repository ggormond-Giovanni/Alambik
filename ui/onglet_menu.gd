class_name OngletMenu
extends Button

var symbole := "stats"
var _selection := 0.0
var _pression := 0.0
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
	button_down.connect(func() -> void: _pression = 1.0)
	button_up.connect(func() -> void: _pression = 0.0)
	queue_redraw()

func _process(delta: float) -> void:
	var cible := 1.0 if actif else 0.0
	var vitesse := 18.0 if ReglagesJoueur.effets_reduits else 10.0
	var avant := _selection
	_selection = move_toward(_selection, cible, delta * vitesse)
	if not is_equal_approx(avant, _selection) or _pression > 0.0:
		queue_redraw()

func _draw() -> void:
	var centre := size * Vector2(0.5, 0.46) - Vector2(0.0, _selection * 7.0)
	var couleur := Palette.TEXTE_ATTENUE.lerp(Palette.OR, _selection)
	var taille_icone := 31.0 * (1.0 - _pression * 0.07)
	if _selection > 0.001:
		var fond := Rect2(Vector2(5.0, 4.0), size - Vector2(10.0, 8.0))
		draw_rect(fond, Color(Palette.OR, 0.16 * _selection))
		draw_rect(fond, Color(Palette.OR, 0.72 * _selection), false, 3.0)
		draw_circle(Vector2(size.x * 0.5, size.y - 10.0), 4.0 * _selection, Palette.OR)
	match symbole:
		"stuff": _dessiner_bouclier(centre, taille_icone, couleur)
		"grimoire": _dessiner_livre(centre, taille_icone, couleur)
		"sorts": _dessiner_sort(centre, taille_icone * 0.97, couleur)
		"arbre": _dessiner_arbre(centre, taille_icone * 0.97, couleur)

func _dessiner_bouclier(centre: Vector2, taille: float, couleur: Color) -> void:
	var forme := PackedVector2Array([
		centre + Vector2(-taille, -taille * 0.72), centre + Vector2(0.0, -taille),
		centre + Vector2(taille, -taille * 0.72), centre + Vector2(taille * 0.78, taille * 0.46),
		centre + Vector2(0.0, taille), centre + Vector2(-taille * 0.78, taille * 0.46)])
	draw_colored_polygon(forme, Color(couleur, 0.28))
	Dessin.contour(self, forme, couleur, 4.0)
	draw_line(centre + Vector2(0.0, -taille * 0.72), centre + Vector2(0.0, taille * 0.65), couleur, 3.0)

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

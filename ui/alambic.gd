extends Control

# La salle 5 et la salle 9. Deux reactifs choisis par le joueur disparaissent
# et deviennent une essence. Trois regles de la spec sont tenues ici :
# une essence n'est jamais composant, on peut partir sans fusionner, et
# l'interface montre ce qui est possible avant le clic au lieu de punir apres.

signal termine

var _liste: VBoxContainer
var _cartes: Array[CarteReactif] = []
var _selection: Array[String] = []
var _bouton_fusionner: Button
var _bouton_passer: Button
var _apercu: Label
var _anim := 0.0
var _fusion_en_cours := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_construire()
	if Jeu.mode_auto:
		_jouer_automatiquement()

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()

func _construire() -> void:
	var marge := MarginContainer.new()
	marge.set_anchors_preset(Control.PRESET_FULL_RECT)
	marge.add_theme_constant_override("margin_left", 44)
	marge.add_theme_constant_override("margin_right", 44)
	marge.add_theme_constant_override("margin_top", int(Ecran.marge_haute()) + 430)
	marge.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse()) + 30)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 16)
	marge.add_child(colonne)

	var defilement := ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(defilement)

	_liste = VBoxContainer.new()
	_liste.add_theme_constant_override("separation", 14)
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defilement.add_child(_liste)

	_apercu = Label.new()
	_apercu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apercu.add_theme_font_size_override("font_size", 30)
	_apercu.custom_minimum_size = Vector2(0, 44)
	colonne.add_child(_apercu)

	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 18)
	colonne.add_child(boutons)

	_bouton_fusionner = _creer_bouton("Fusionner", Palette.ESSENCE)
	_bouton_fusionner.pressed.connect(_sur_fusionner)
	boutons.add_child(_bouton_fusionner)

	# La spec est explicite : garder ses reactifs est un choix legitime, la
	# salle ne doit jamais se transformer en peage.
	_bouton_passer = _creer_bouton("Quitter sans fusionner", Palette.TEXTE_ATTENUE)
	_bouton_passer.pressed.connect(_sur_passer)
	boutons.add_child(_bouton_passer)

	_construire_cartes()

func _creer_bouton(texte: String, teinte: Color) -> Button:
	var bouton := Button.new()
	bouton.text = texte
	bouton.custom_minimum_size = Vector2(0, 108)   # cible tactile confortable
	bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bouton.add_theme_font_size_override("font_size", 30)
	bouton.add_theme_color_override("font_color", teinte)
	bouton.add_theme_color_override("font_disabled_color", Color(teinte, 0.28))
	return bouton

func _construire_cartes() -> void:
	for enfant in _liste.get_children():
		enfant.queue_free()
	_cartes.clear()
	var fusionnables := _ids_fusionnables()
	# Une carte par reactif, pas par exemplaire : avec des copies empilees, la
	# liste affichait trois fois Main leste sans dire que c'etait le meme.
	for entree in Jeu.inventaire_groupe():
		var id: String = entree[0]
		var reactif := Jeu.reactif(id)
		if reactif == null:
			continue
		var carte := CarteReactif.new()
		carte.configurer(reactif)
		carte.custom_minimum_size = Vector2(0, 150)
		carte.selectionnee = id in _selection
		carte.desactivee = not id in fusionnables and not id in _selection
		carte.choisie.connect(_sur_choix)
		_liste.add_child(carte)
		_cartes.append(carte)
	_rafraichir_boutons()

func _ids_fusionnables() -> Array[String]:
	var ids: Array[String] = []
	for paire in AlambicLogique.paires_possibles(Jeu.inventaire):
		# Un premier reactif deja choisi restreint les partenaires acceptables.
		if _selection.size() == 1 and not _selection[0] in [paire[0], paire[1]]:
			continue
		for id in [paire[0], paire[1]]:
			if not id in ids:
				ids.append(id)
	return ids

func _rafraichir_boutons() -> void:
	var possible := _selection.size() == 2 \
		and AlambicLogique.peut_fusionner(Jeu.inventaire, _selection[0], _selection[1])
	_bouton_fusionner.disabled = not possible
	if possible:
		var essence := Jeu.reactif(Recettes.essence_pour(_selection[0], _selection[1]))
		_apercu.text = "→ %s" % essence.nom
		_apercu.add_theme_color_override("font_color", Palette.ESSENCE)
	elif AlambicLogique.paires_possibles(Jeu.inventaire).is_empty():
		_apercu.text = "Aucun de ces réactifs ne se combine."
		_apercu.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)
	else:
		_apercu.text = "Choisissez deux réactifs compatibles."
		_apercu.add_theme_color_override("font_color", Palette.TEXTE_ATTENUE)

func _sur_choix(id: String) -> void:
	if _fusion_en_cours:
		return
	if id in _selection:
		_selection.erase(id)
	elif _selection.size() < 2:
		_selection.append(id)
	_construire_cartes()

func _sur_fusionner() -> void:
	if _fusion_en_cours or _selection.size() != 2:
		return
	if not AlambicLogique.peut_fusionner(Jeu.inventaire, _selection[0], _selection[1]):
		return
	_fusion_en_cours = true
	var essence := Recettes.essence_pour(_selection[0], _selection[1])
	Sons.jouer("fusion", -8.0)
	var consommes: Array[String] = _selection.duplicate()
	Jeu.retirer_reactifs(consommes)
	Jeu.ajouter_reactif(essence)
	_selection.clear()
	_construire_cartes()
	_apercu.text = "%s !" % Jeu.reactif(essence).nom
	_apercu.add_theme_color_override("font_color", Palette.ESSENCE)
	await get_tree().create_timer(1.1).timeout
	termine.emit()

func _sur_passer() -> void:
	if _fusion_en_cours:
		return
	termine.emit()

func _jouer_automatiquement() -> void:
	await get_tree().create_timer(0.25).timeout
	var paires := AlambicLogique.paires_possibles(Jeu.inventaire)
	if paires.is_empty():
		termine.emit()
		return
	_selection = [paires[0][0], paires[0][1]]
	_construire_cartes()
	_sur_fusionner()

func _draw() -> void:
	var police := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.06, 0.93))
	var haut := Ecran.marge_haute() + 80.0
	draw_string(police, Vector2(0, haut), "L'alambic", HORIZONTAL_ALIGNMENT_CENTER, size.x, 52, Palette.ESSENCE)
	draw_string(police, Vector2(0, haut + 44.0), "Deux réactifs entrent, une essence sort.",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, Palette.TEXTE_ATTENUE)
	_dessiner_alambic(Vector2(size.x / 2.0, haut + 210.0))

func _dessiner_alambic(centre: Vector2) -> void:
	var teintes: Array[Color] = []
	for id in _selection:
		var r := Jeu.reactif(id)
		if r != null:
			teintes.append(r.teinte)
	var teinte := Palette.ESSENCE
	if teintes.size() == 1:
		teinte = teintes[0]
	elif teintes.size() == 2:
		teinte = teintes[0].lerp(teintes[1], 0.5)

	# Cornue : un ballon, un col, un bec. Le liquide prend la couleur de ce
	# qu'on a selectionne, donc l'ecran reagit avant meme la fusion.
	var ballon := centre + Vector2(0, 40.0)
	Dessin.halo(self, ballon, 170.0, Color(teinte, 0.6), 5)
	var verre := Color(0.72, 0.80, 0.92, 0.22)
	draw_circle(ballon, 92.0, verre)
	draw_arc(ballon, 92.0, 0.0, TAU, 40, Color(0.85, 0.92, 1.0, 0.6), 3.5, true)
	var niveau := 0.35 + 0.25 * float(_selection.size())
	var liquide := PackedVector2Array()
	var haut_liquide := ballon.y + 92.0 - 184.0 * niveau
	for i in 33:
		var t := float(i) / 32.0
		var x := lerpf(ballon.x - 86.0, ballon.x + 86.0, t)
		liquide.append(Vector2(x, haut_liquide + sin(t * 9.0 + _anim * 3.0) * 5.0))
	for i in range(32, -1, -1):
		var t := float(i) / 32.0
		liquide.append(Vector2(lerpf(ballon.x - 86.0, ballon.x + 86.0, t), ballon.y + 88.0))
	draw_colored_polygon(liquide, Color(teinte, 0.75))
	# Col et bec.
	draw_rect(Rect2(centre.x - 22.0, centre.y - 92.0, 44.0, 96.0), verre)
	draw_rect(Rect2(centre.x - 30.0, centre.y - 104.0, 60.0, 18.0), Color(0.85, 0.92, 1.0, 0.45))
	draw_line(Vector2(centre.x + 20.0, centre.y - 56.0), Vector2(centre.x + 132.0, centre.y - 8.0),
		Color(0.85, 0.92, 1.0, 0.5), 7.0, true)
	# Bulles.
	for i in 5:
		var phase := fmod(_anim * 0.6 + float(i) * 0.2, 1.0)
		var p := Vector2(ballon.x + sin(float(i) * 2.4 + _anim) * 46.0, ballon.y + 78.0 - 150.0 * phase)
		draw_circle(p, 5.0 + 4.0 * (1.0 - phase), Color(1, 1, 1, 0.35 * (1.0 - phase)))

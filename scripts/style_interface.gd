class_name StyleInterface
extends RefCounted

# Pixel art moderne : construction nette sur la grille, mais profondeur,
# transparences colorees et lumiere de fantasy plutot qu'un aplat austere.

static func panneau(fond: Color, bord: Color, rayon := 24, ombre := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = bord
	style.set_border_width_all(4)
	style.set_corner_radius_all(maxi(0, mini(rayon, 10)))
	style.corner_detail = 5
	style.shadow_color = Color(0.005, 0.012, 0.035, 0.72)
	style.shadow_size = maxi(0, mini(ombre, 12))
	style.shadow_offset = Vector2(0.0, 7.0)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	return style

static func panneau_leger(accent := Palette.ESSENCE, rayon := 22) -> StyleBoxFlat:
	var style := panneau(Color(0.075, 0.105, 0.205, 0.90), Color(accent, 0.46), rayon, 6)
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_width_left = 4
	return style

# Les fonds partagent une profondeur et une grille tres discrete. Les contenus
# gardent leur accent propre, mais un changement d'ecran ne ressemble plus a un
# changement de jeu.
static func dessiner_fond(canvas: CanvasItem, taille: Vector2, accent := Palette.ESSENCE,
		temps := 0.0, opacite := 1.0) -> void:
	Retro16.dessiner_fond_interface(canvas, taille, accent, temps, opacite)

static func dessiner_entete(canvas: CanvasItem, taille: Vector2, surtitre: String,
		titre: String, sous_titre: String, accent := Palette.OR,
		y := 104.0, aligne_gauche := false) -> void:
	var police := Polices.CORPS
	var cadre := Rect2(28.0, y - 72.0, taille.x - 56.0, 154.0 if not sous_titre.is_empty() else 126.0)
	canvas.draw_rect(cadre, Color(0.025, 0.045, 0.115, 0.92))
	canvas.draw_rect(cadre, Color(accent, 0.62), false, 4.0)
	canvas.draw_rect(Rect2(cadre.position + Vector2(8.0, 8.0), cadre.size - Vector2(16.0, 16.0)),
		Color(Palette.BORD_PAGE, 0.38), false, 2.0)
	for coin in [cadre.position + Vector2(12.0, 12.0),
		cadre.position + Vector2(cadre.size.x - 12.0, 12.0),
		cadre.position + Vector2(12.0, cadre.size.y - 12.0),
		cadre.end - Vector2(12.0, 12.0)]:
		canvas.draw_circle(coin, 5.0, Color(accent, 0.86))
	var x := 54.0 if aligne_gauche else 0.0
	var largeur := taille.x - 108.0 if aligne_gauche else taille.x
	var alignement := HORIZONTAL_ALIGNMENT_LEFT if aligne_gauche else HORIZONTAL_ALIGNMENT_CENTER
	canvas.draw_string(police, Vector2(x, y - 40.0), surtitre.to_upper(), alignement,
		largeur, 20, Color(accent, 0.86))
	canvas.draw_string(police, Vector2(x, y + 14.0), titre, alignement,
		largeur, 46, Palette.TEXTE)
	if not sous_titre.is_empty():
		canvas.draw_string(police, Vector2(x, y + 58.0), sous_titre, alignement,
			largeur, 23, Palette.TEXTE_ATTENUE)
	var ligne_y := y + (82.0 if not sous_titre.is_empty() else 54.0)
	var ligne_largeur := minf(largeur, 620.0)
	var ligne_x := x if aligne_gauche else (taille.x - ligne_largeur) * 0.5
	Retro16.rectangle(canvas, Rect2(ligne_x, ligne_y, ligne_largeur, 4.0),
		Color(accent, 0.42))

# Les ecrans premium sont peints : leurs boutons ne sont que des zones tactiles
# posees sur la peinture. Un Button garde pourtant ses styleboxes de survol, de
# clic et de focus, que Godot dessine par-dessus le decor — d'ou les rectangles
# gris qui apparaissaient sous la souris. `flat` n'enleve que l'etat normal.
static func rendre_invisible(bouton: Button) -> Button:
	bouton.flat = true
	bouton.focus_mode = Control.FOCUS_NONE
	bouton.mouse_filter = Control.MOUSE_FILTER_STOP
	var vide := StyleBoxEmpty.new()
	for etat in ["normal", "hover", "pressed", "focus", "disabled"]:
		bouton.add_theme_stylebox_override(etat, vide)
	return bouton

static func zone_tactile(action := Callable()) -> Button:
	var bouton := Button.new()
	rendre_invisible(bouton)
	if action.is_valid():
		bouton.pressed.connect(action)
	return bouton

static func styliser_bouton(bouton: Button, accent := Palette.OR, secondaire := false) -> void:
	# Pas de focus clavier ni de déclenchement au premier contact : sur mobile,
	# le joueur doit pouvoir glisser hors du bouton pour annuler son geste.
	bouton.focus_mode = Control.FOCUS_NONE
	bouton.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	var fond := Color(0.095, 0.125, 0.235, 0.96) if secondaire else Color(accent.darkened(0.46), 0.94)
	bouton.add_theme_stylebox_override("normal", panneau(fond, Color(accent, 0.42), 0, 0))
	# L'état hover ne porte aucune information : un écran tactile n'en a pas.
	bouton.add_theme_stylebox_override("hover", panneau(fond, Color(accent, 0.42), 0, 0))
	bouton.add_theme_stylebox_override("pressed", panneau(Color(accent, 0.48), accent.lightened(0.24), 0, 3))
	bouton.add_theme_stylebox_override("focus", panneau(Color(accent, 0.24), accent, 0, 0))
	bouton.add_theme_stylebox_override("disabled", panneau(Color(0.06, 0.05, 0.08, 0.72), Color(accent, 0.14), 0, 0))
	bouton.add_theme_color_override("font_color", Palette.TEXTE)
	bouton.add_theme_color_override("font_hover_color", Color.WHITE)
	bouton.add_theme_color_override("font_pressed_color", Color.WHITE)
	bouton.add_theme_color_override("font_focus_color", Color.WHITE)
	bouton.add_theme_color_override("font_disabled_color", Color(Palette.TEXTE_ATTENUE, 0.62))
	bouton.add_theme_constant_override("outline_size", 4)
	bouton.add_theme_constant_override("icon_max_width", 64)
	bouton.add_theme_constant_override("h_separation", 16)
	bouton.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.13, 0.88))
	if not bouton.has_meta("micro_animation_installee"):
		bouton.set_meta("micro_animation_installee", true)
		bouton.resized.connect(func() -> void: bouton.pivot_offset = bouton.size * 0.5)
		bouton.button_down.connect(func() -> void:
			StyleInterface._animer_bouton(bouton,
				Vector2.ONE * (0.985 if ReglagesJoueur.effets_reduits else 0.955), true))
		bouton.button_up.connect(func() -> void:
			StyleInterface._animer_bouton(bouton, Vector2.ONE, false))

static func _animer_bouton(bouton: Button, echelle: Vector2, enfonce: bool) -> void:
	if not is_instance_valid(bouton):
		return
	var precedente: Variant = bouton.get_meta("micro_animation", null)
	if precedente is Tween and (precedente as Tween).is_valid():
		(precedente as Tween).kill()
	var animation := bouton.create_tween()
	animation.set_trans(Tween.TRANS_QUINT if enfonce else Tween.TRANS_BACK)
	animation.set_ease(Tween.EASE_OUT)
	animation.tween_property(bouton, "scale", echelle,
		0.06 if ReglagesJoueur.effets_reduits else (0.09 if enfonce else 0.20))
	bouton.set_meta("micro_animation", animation)

static func styliser_option(bouton: CheckButton, accent := Palette.ESSENCE) -> void:
	bouton.focus_mode = Control.FOCUS_NONE
	bouton.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	bouton.add_theme_font_size_override("font_size", 25)
	bouton.add_theme_color_override("font_color", Palette.TEXTE)
	bouton.add_theme_color_override("font_pressed_color", Color.WHITE)
	bouton.add_theme_stylebox_override("normal", panneau_leger(accent, 18))
	bouton.add_theme_stylebox_override("hover", panneau_leger(accent, 18))
	bouton.add_theme_stylebox_override("pressed",
		panneau(Color(accent, 0.15), Color(accent, 0.56), 18, 3))

static func styliser_selecteur(selecteur: OptionButton, accent := Palette.ESSENCE) -> void:
	selecteur.focus_mode = Control.FOCUS_NONE
	selecteur.add_theme_font_size_override("font_size", 23)
	selecteur.add_theme_color_override("font_color", Palette.TEXTE)
	selecteur.add_theme_color_override("font_disabled_color", Color(Palette.TEXTE_ATTENUE, 0.62))
	selecteur.add_theme_stylebox_override("normal", panneau_leger(accent, 18))
	selecteur.add_theme_stylebox_override("hover",
		panneau(Color(accent, 0.10), Color(accent, 0.48), 18, 4))
	selecteur.add_theme_stylebox_override("pressed",
		panneau(Color(accent, 0.16), Color(accent, 0.68), 18, 3))
	selecteur.add_theme_stylebox_override("disabled",
		panneau(Color(0.025, 0.022, 0.040, 0.72), Color(accent, 0.12), 18, 1))
	var menu := selecteur.get_popup()
	menu.add_theme_font_size_override("font_size", 22)
	menu.add_theme_color_override("font_color", Palette.TEXTE)
	menu.add_theme_color_override("font_hover_color", Color.WHITE)
	menu.add_theme_stylebox_override("panel", panneau(Color(0.025, 0.020, 0.045, 0.99),
		Color(accent, 0.42), 18, 8))

static func styliser_curseur(curseur: HSlider, accent := Palette.ESSENCE) -> void:
	curseur.focus_mode = Control.FOCUS_NONE
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0.020, 0.018, 0.036, 0.92)
	fond.set_corner_radius_all(0)
	fond.content_margin_top = 8.0
	fond.content_margin_bottom = 8.0
	var rempli := StyleBoxFlat.new()
	rempli.bg_color = Color(accent, 0.74)
	rempli.set_corner_radius_all(0)
	rempli.content_margin_top = 8.0
	rempli.content_margin_bottom = 8.0
	curseur.add_theme_stylebox_override("slider", fond)
	curseur.add_theme_stylebox_override("grabber_area", rempli)
	curseur.add_theme_stylebox_override("grabber_area_highlight", rempli)

static func animer_entree(controle: Control, distance := 22.0) -> void:
	var duree_fondu := 0.12 if ReglagesJoueur.effets_reduits else 0.28
	var duree_mouvement := 0.16 if ReglagesJoueur.effets_reduits else 0.42
	var mouvement := distance * (0.25 if ReglagesJoueur.effets_reduits else 1.0)
	controle.modulate.a = 0.0
	controle.position.y += mouvement
	controle.pivot_offset = controle.size * 0.5
	controle.scale = Vector2.ONE * (0.985 if ReglagesJoueur.effets_reduits else 0.925)
	var animation := controle.create_tween()
	animation.set_parallel(true)
	animation.set_trans(Tween.TRANS_QUINT)
	animation.set_ease(Tween.EASE_OUT)
	animation.tween_property(controle, "modulate:a", 1.0, duree_fondu)
	animation.tween_property(controle, "position:y", controle.position.y - mouvement, duree_mouvement)
	animation.tween_property(controle, "scale", Vector2.ONE, duree_mouvement)

# Les listes apparaissent element par element : le regard comprend l'ordre des
# choix sans que l'ecran entier saute d'un seul bloc.
static func animer_liste(conteneur: Control, intervalle := 0.055) -> void:
	var enfants := conteneur.get_children()
	for index in enfants.size():
		var enfant := enfants[index] as CanvasItem
		if enfant == null:
			continue
		enfant.modulate.a = 0.0
		enfant.scale = Vector2.ONE * (0.995 if ReglagesJoueur.effets_reduits else 0.965)
		if enfant is Control:
			(enfant as Control).pivot_offset = (enfant as Control).size * 0.5
		var animation := enfant.create_tween()
		animation.tween_interval((0.015 if ReglagesJoueur.effets_reduits else intervalle) * index)
		animation.set_trans(Tween.TRANS_QUINT)
		animation.set_ease(Tween.EASE_OUT)
		animation.tween_property(enfant, "modulate:a", 1.0,
			0.10 if ReglagesJoueur.effets_reduits else 0.26)
		animation.parallel().tween_property(enfant, "scale", Vector2.ONE,
			0.12 if ReglagesJoueur.effets_reduits else 0.32)

static func animer_rafraichissement(controle: Control) -> void:
	controle.modulate.a = 0.35
	controle.position.x += 12.0 if not ReglagesJoueur.effets_reduits else 3.0
	var animation := controle.create_tween()
	animation.set_trans(Tween.TRANS_QUINT)
	animation.set_ease(Tween.EASE_OUT)
	animation.tween_property(controle, "modulate:a", 1.0,
		0.10 if ReglagesJoueur.effets_reduits else 0.24)
	animation.parallel().tween_property(controle, "position:x", controle.position.x -
		(12.0 if not ReglagesJoueur.effets_reduits else 3.0),
		0.12 if ReglagesJoueur.effets_reduits else 0.30)

static func basculer_contenu(sortant: Control, entrant: Control, direction := 1.0) -> void:
	if not is_instance_valid(sortant) or not is_instance_valid(entrant):
		return
	if sortant.has_meta("transition_contenu"):
		return
	sortant.set_meta("transition_contenu", true)
	var distance := 18.0 if ReglagesJoueur.effets_reduits else 112.0
	var duree := 0.10 if ReglagesJoueur.effets_reduits else 0.28
	var sortie := sortant.create_tween().set_parallel(true)
	sortie.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	sortie.tween_property(sortant, "modulate:a", 0.0, duree)
	sortie.tween_property(sortant, "position:x", sortant.position.x - distance * direction, duree)
	sortie.tween_property(sortant, "scale", Vector2.ONE * 0.94, duree)
	await sortie.finished
	sortant.visible = false
	sortant.modulate.a = 1.0
	sortant.position.x += distance * direction
	entrant.visible = true
	entrant.modulate.a = 0.0
	entrant.position.x += distance * direction
	entrant.scale = Vector2.ONE * 0.94
	var entree := entrant.create_tween().set_parallel(true)
	entree.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	entree.tween_property(entrant, "modulate:a", 1.0, duree * 1.45)
	entree.tween_property(entrant, "position:x", entrant.position.x - distance * direction, duree * 1.45)
	entree.tween_property(entrant, "scale", Vector2.ONE, duree * 1.45)
	await entree.finished
	sortant.remove_meta("transition_contenu")

# L'action n'est executee qu'une fois l'ecran sorti. Cela evite les queue_free
# et changements de scene secs encore visibles pendant la derniere image.
static func sortir_puis(controle: Control, action: Callable, distance := -18.0) -> void:
	if controle.has_meta("sortie_interface_en_cours"):
		return
	controle.set_meta("sortie_interface_en_cours", true)
	controle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var duree := 0.11 if ReglagesJoueur.effets_reduits else 0.34
	var mouvement := distance * (0.25 if ReglagesJoueur.effets_reduits else 1.0)
	var animation := controle.create_tween()
	animation.set_parallel(true)
	animation.set_trans(Tween.TRANS_QUINT)
	animation.set_ease(Tween.EASE_IN)
	animation.tween_property(controle, "modulate:a", 0.0, duree)
	animation.tween_property(controle, "position:y", controle.position.y + mouvement, duree)
	animation.tween_property(controle, "scale", Vector2.ONE *
		(0.98 if ReglagesJoueur.effets_reduits else 1.065), duree)
	animation.chain().tween_callback(action)

static func ajouter_icone(bouton: Button, index: int, largeur := 60) -> void:
	bouton.icon = Retro16.icone_interface(index)
	bouton.expand_icon = true
	bouton.add_theme_constant_override("icon_max_width", largeur)

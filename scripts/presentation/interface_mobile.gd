class_name InterfaceMobile
extends RefCounted

const FOND_ACCUEIL := preload("res://assets/visual/menu_vallee_alambics.png")
const FOND_INTERFACE := preload("res://assets/visual/fond_interface_scriptorium.png")

static func dessiner_fond(canvas: CanvasItem, taille: Vector2, accueil := false,
		accent := Palette.ESSENCE, temps := 0.0) -> void:
	var texture := FOND_ACCUEIL if accueil else FOND_INTERFACE
	FondAdaptatif.dessiner_cover(canvas, texture, taille, Color.WHITE, 0.44 if accueil else 0.50)
	# Voiles continus : le décor reste une couche indépendante et le contenu garde
	# toujours assez de contraste, quelle que soit la proportion du téléphone.
	canvas.draw_rect(Rect2(Vector2.ZERO, taille), Color(0.015, 0.028, 0.075, 0.28 if accueil else 0.42))
	canvas.draw_rect(Rect2(0.0, 0.0, taille.x, minf(taille.y * 0.19, 360.0)),
		Color(0.008, 0.018, 0.052, 0.46))
	canvas.draw_rect(Rect2(0.0, maxf(0.0, taille.y - minf(taille.y * 0.22, 430.0)),
		taille.x, minf(taille.y * 0.22, 430.0)), Color(0.006, 0.015, 0.046, 0.52))
	for index in 14:
		var x := fmod(float(index * 193 + 77), maxf(1.0, taille.x))
		var y := fmod(float(index * 137 + 191), maxf(1.0, taille.y * 0.72))
		var pulsation := 0.10 + 0.07 * sin(temps * 1.6 + float(index))
		canvas.draw_circle(Vector2(x, y), 1.5 + float(index % 3), Color(accent, pulsation))
	_dessiner_coins(canvas, taille, Color(accent, 0.36))

static func panneau(accent := Palette.OR, fort := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.060, 0.145, 0.96 if fort else 0.90)
	style.border_color = Color(accent, 0.72 if fort else 0.48)
	style.set_border_width_all(3 if fort else 2)
	style.set_corner_radius_all(18)
	style.corner_detail = 8
	style.shadow_color = Color(0.002, 0.008, 0.030, 0.66)
	style.shadow_size = 12 if fort else 8
	style.shadow_offset = Vector2(0.0, 7.0)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	return style

static func panneau_leger(accent := Palette.ESSENCE) -> StyleBoxFlat:
	var style := panneau(accent, false)
	style.bg_color = Color(0.040, 0.070, 0.155, 0.78)
	style.border_color = Color(accent, 0.34)
	style.shadow_size = 5
	return style

static func styliser_bouton(bouton: Button, accent := Palette.OR, principal := false) -> void:
	bouton.focus_mode = Control.FOCUS_NONE
	bouton.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	bouton.add_theme_font_size_override("font_size", 27 if not principal else 31)
	bouton.add_theme_color_override("font_color", Palette.TEXTE)
	bouton.add_theme_color_override("font_hover_color", Color.WHITE)
	bouton.add_theme_color_override("font_pressed_color", Color.WHITE)
	bouton.add_theme_color_override("font_disabled_color", Color(Palette.TEXTE_ATTENUE, 0.52))
	bouton.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.06, 0.92))
	bouton.add_theme_constant_override("outline_size", 3)
	var normal := panneau(accent, principal)
	if principal:
		normal.bg_color = Color(accent.darkened(0.48), 0.97)
		normal.border_color = Color(accent.lightened(0.12), 0.88)
	var survol := normal.duplicate()
	survol.bg_color = Color(normal.bg_color.lightened(0.08), normal.bg_color.a)
	var appuye := normal.duplicate()
	appuye.bg_color = Color(accent, 0.38)
	appuye.border_color = accent.lightened(0.24)
	appuye.shadow_size = 3
	var desactive := panneau_leger(accent)
	desactive.bg_color = Color(0.025, 0.035, 0.070, 0.64)
	for paire in [["normal", normal], ["hover", survol], ["pressed", appuye],
			["focus", survol], ["disabled", desactive]]:
		bouton.add_theme_stylebox_override(str(paire[0]), paire[1])

static func styliser_label(label: Label, taille := 26, accent := Color.TRANSPARENT,
		centre := false) -> Label:
	label.add_theme_font_size_override("font_size", taille)
	label.add_theme_color_override("font_color", Palette.TEXTE if accent.a <= 0.0 else accent)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.06, 0.84))
	label.add_theme_constant_override("outline_size", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centre:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

static func appliquer_marges(conteneur: MarginContainer, reserve_bas := 0.0,
		large := false) -> void:
	var lateral := 30 if not large else 52
	conteneur.add_theme_constant_override("margin_left", lateral)
	conteneur.add_theme_constant_override("margin_right", lateral)
	conteneur.add_theme_constant_override("margin_top", int(Ecran.marge_haute() + 24.0))
	conteneur.add_theme_constant_override("margin_bottom", int(Ecran.marge_basse() + reserve_bas + 24.0))

static func _dessiner_coins(canvas: CanvasItem, taille: Vector2, couleur: Color) -> void:
	var marge := 18.0
	var longueur := 52.0
	for coin in [Vector2(marge, marge), Vector2(taille.x - marge, marge),
			Vector2(marge, taille.y - marge), Vector2(taille.x - marge, taille.y - marge)]:
		var sx := 1.0 if coin.x < taille.x * 0.5 else -1.0
		var sy := 1.0 if coin.y < taille.y * 0.5 else -1.0
		canvas.draw_line(coin, coin + Vector2(longueur * sx, 0.0), couleur, 3.0)
		canvas.draw_line(coin, coin + Vector2(0.0, longueur * sy), couleur, 3.0)

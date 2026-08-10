class_name StyleInterface
extends RefCounted

# Un langage commun pour tous les ecrans : surfaces profondes, coins doux,
# bordures lumineuses et reactions tactiles franches.

static func panneau(fond: Color, bord: Color, rayon := 24, ombre := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = bord
	style.set_border_width_all(2)
	style.set_corner_radius_all(rayon)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = ombre
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 16.0
	style.content_margin_bottom = 16.0
	return style

static func styliser_bouton(bouton: Button, accent := Palette.OR, secondaire := false) -> void:
	# Pas de focus clavier ni de déclenchement au premier contact : sur mobile,
	# le joueur doit pouvoir glisser hors du bouton pour annuler son geste.
	bouton.focus_mode = Control.FOCUS_NONE
	bouton.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	var fond := Color(0.075, 0.060, 0.115, 0.96) if secondaire else Color(accent, 0.18)
	bouton.add_theme_stylebox_override("normal", panneau(fond, Color(accent, 0.42), 24, 8))
	# L'état hover ne porte aucune information : un écran tactile n'en a pas.
	bouton.add_theme_stylebox_override("hover", panneau(fond, Color(accent, 0.42), 24, 8))
	bouton.add_theme_stylebox_override("pressed", panneau(Color(accent, 0.38), accent, 20, 4))
	bouton.add_theme_stylebox_override("focus", panneau(Color(accent, 0.24), accent, 24, 10))
	bouton.add_theme_stylebox_override("disabled", panneau(Color(0.06, 0.05, 0.08, 0.72), Color(accent, 0.14), 24, 2))
	bouton.add_theme_color_override("font_color", Palette.TEXTE)
	bouton.add_theme_color_override("font_hover_color", Color.WHITE)
	bouton.add_theme_color_override("font_pressed_color", Color.WHITE)
	bouton.add_theme_color_override("font_focus_color", Color.WHITE)
	bouton.add_theme_color_override("font_disabled_color", Color(Palette.TEXTE_ATTENUE, 0.35))
	bouton.add_theme_constant_override("outline_size", 4)
	bouton.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.04, 0.75))

static func animer_entree(controle: Control, distance := 22.0) -> void:
	controle.modulate.a = 0.0
	controle.position.y += distance
	var animation := controle.create_tween()
	animation.set_parallel(true)
	animation.set_trans(Tween.TRANS_QUINT)
	animation.set_ease(Tween.EASE_OUT)
	animation.tween_property(controle, "modulate:a", 1.0, 0.28)
	animation.tween_property(controle, "position:y", controle.position.y - distance, 0.42)

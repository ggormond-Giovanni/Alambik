extends RefCounted

func test_la_cible_tactile_globale_est_assez_grande(v: Verif) -> void:
	v.vrai(Ecran.CIBLE_TACTILE >= 112.0, "les actions essentielles ont une vraie cible de pouce")

func test_le_joystick_est_dimensionne_pour_un_pouce(v: Verif) -> void:
	v.vrai(JoystickLogique.RAYON >= Ecran.CIBLE_TACTILE, "le joystick flottant ne demande aucune precision")

func test_les_boutons_partagent_une_reaction_mobile(v: Verif) -> void:
	var bouton := Button.new()
	StyleInterface.styliser_bouton(bouton, Palette.OR)
	v.egal(bouton.action_mode, BaseButton.ACTION_MODE_BUTTON_RELEASE,
		"une action part au relachement pour pouvoir annuler le geste")
	v.egal(bouton.focus_mode, Control.FOCUS_NONE,
		"le focus clavier ne pollue pas l'interface tactile")
	v.vrai(bouton.has_theme_stylebox_override("pressed"),
		"chaque bouton possede un etat enfonce explicite")
	bouton.free()

func test_les_surfaces_secondaires_restent_hierarchisees(v: Verif) -> void:
	var style := StyleInterface.panneau_leger(Palette.ESSENCE)
	v.egal(style.border_width_left, 4, "la barre laterale porte l'accent de section")
	v.vrai(style.shadow_size <= 6, "une section reste moins surelevee qu'une action principale")

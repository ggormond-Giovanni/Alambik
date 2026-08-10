extends RefCounted

func test_la_cible_tactile_globale_est_assez_grande(v: Verif) -> void:
	v.vrai(Ecran.CIBLE_TACTILE >= 112.0, "les actions essentielles ont une vraie cible de pouce")

func test_le_joystick_est_dimensionne_pour_un_pouce(v: Verif) -> void:
	v.vrai(JoystickLogique.RAYON >= Ecran.CIBLE_TACTILE, "le joystick flottant ne demande aucune precision")

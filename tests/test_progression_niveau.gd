extends RefCounted

func test_la_progression_depend_de_l_experience(v: Verif) -> void:
	Jeu.demarrer_run(1)
	var requise := Jeu.experience_requise()
	Jeu.ajouter_experience(requise - 1)
	v.egal(Jeu.niveau, 1, "le niveau ne monte pas avant de remplir la jauge")
	Jeu.ajouter_experience(1)
	v.egal(Jeu.niveau, 2, "remplir la jauge fait gagner un niveau")
	v.egal(Jeu.experience, 0, "l'experience depensee repart de zero")

func test_le_cout_des_niveaux_augmente(v: Verif) -> void:
	Jeu.demarrer_run(1)
	var premier := Jeu.experience_requise()
	Jeu.ajouter_experience(premier)
	v.vrai(Jeu.experience_requise() > premier, "les augments s'espacent progressivement")

func test_un_gros_gain_conserve_le_surplus(v: Verif) -> void:
	Jeu.demarrer_run(1)
	var premier := Jeu.experience_requise()
	Jeu.ajouter_experience(premier + 3)
	v.egal(Jeu.experience, 3, "le surplus d'experience n'est pas perdu")

extends RefCounted

func test_affiche_les_bonus_chiffres(v: Verif) -> void:
	var lignes := DetailsReactif.lignes(CatalogueReactifs.par_id("encre_lourde"))
	v.vrai("Dégâts +45 %" in lignes, "les dégâts sont traduits en pourcentage")
	v.vrai("Vitesse des projectiles -30 %" in lignes, "les malus sont affichés avec leur signe")

func test_affiche_les_valeurs_des_effets(v: Verif) -> void:
	var texte := DetailsReactif.texte(CatalogueReactifs.par_id("braise"))
	v.vrai("6 dégâts/s" in texte, "la brûlure affiche ses dégâts")
	v.vrai("3 s" in texte, "la brûlure affiche sa durée")

func test_tient_compte_du_rendement_des_copies(v: Verif) -> void:
	var lignes := DetailsReactif.lignes(CatalogueReactifs.par_id("main_leste"), 2)
	v.vrai("Cadence de tir +40 %" in lignes, "deux copies affichent leur bonus total pondéré")

func test_detaille_les_bonus_du_heros(v: Verif) -> void:
	var texte := DetailsReactif.texte(CatalogueReactifs.par_id("fiole_de_vie"))
	v.vrai("PV maximum +40" in texte, "la fiole affiche les PV exacts")

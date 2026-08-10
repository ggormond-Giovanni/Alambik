extends RefCounted

func test_meilleur_resultat_progresse(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.meilleure_salle = 0
	r.enregistrer_resultat(4, false)
	v.egal(r.meilleure_salle, 4, "un premier resultat s'enregistre")
	r.enregistrer_resultat(2, false)
	v.egal(r.meilleure_salle, 4, "un resultat moins bon ne remplace pas le meilleur")
	r.enregistrer_resultat(9, false)
	v.egal(r.meilleure_salle, 9, "un meilleur resultat remplace")
	r.free()

func test_victoires_comptees(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.victoires = 0
	r.runs = 0
	r.enregistrer_resultat(10, true)
	r.enregistrer_resultat(3, false)
	v.egal(r.victoires, 1, "une seule victoire sur deux runs")
	v.egal(r.runs, 2, "les deux runs sont comptees")
	r.free()

func test_le_niveau_vingt_est_un_prestige_et_le_plafond(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.niveau_heros = Reglages.NIVEAU_HEROS_MAX - 1
	r.experience_heros = r.experience_heros_requise() - 1
	r.ajouter_experience_heros(1)
	v.egal(r.niveau_heros, Reglages.NIVEAU_HEROS_MAX, "le dernier gain atteint le prestige")
	v.egal(r.experience_heros, 0, "la jauge disparait au niveau maximal")
	r.ajouter_experience_heros(100000)
	v.egal(r.niveau_heros, Reglages.NIVEAU_HEROS_MAX, "aucun niveau vingt-et-un n'existe")
	v.vrai(r.est_prestigieux(), "le palier maximal active l'etoile")
	v.egal(r.titre_heros(), "HÉROS ★", "le prestige est visible dans le titre")
	v.presque(r.bonus_niveau_pv(), 19.0 + Reglages.PRESTIGE_PV, "le prestige donne son gros bonus de PV")
	v.presque(r.multiplicateur_niveau_degats(), 1.095 * Reglages.PRESTIGE_DEGATS,
		"le prestige multiplie les degats acquis")
	v.presque(r.multiplicateur_niveau_vitesse(), 1.0475 * Reglages.PRESTIGE_VITESSE,
		"le prestige multiplie la vitesse acquise")
	r.free()

func test_les_niveaux_demandent_un_vrai_farm(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.niveau_heros = 1
	v.vrai(r.experience_heros_requise() >= 70, "le tout premier niveau n'arrive plus gratuitement")
	r.niveau_heros = 10
	v.vrai(r.experience_heros_requise() >= 500, "la courbe devient franchement exigeante")
	r.free()

func test_monter_de_niveau_revele_le_sort_au_rang_zero(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.niveau_heros = 1
	r.experience_heros = 0
	r.rangs_sorts = {}
	r.ajouter_experience_heros(r.experience_heros_requise())
	v.egal(r.niveau_heros, 2, "le heros atteint le niveau deux")
	v.vrai(r.sort_decouvert("onde_alchimique"), "son sort est revele")
	v.egal(r.rang_sort("onde_alchimique"), 0, "mais attend toujours son premier drop de defi")
	v.vrai(not r.sort_debloque("onde_alchimique"), "le rang zero ne peut pas etre equipe")
	r.free()

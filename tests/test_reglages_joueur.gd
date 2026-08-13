extends RefCounted

func test_meilleur_resultat_progresse(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.meilleures_par_chapitre = {}
	r.enregistrer_resultat(4, false, 2)
	v.egal(r.meilleure_du_chapitre(2), 4, "un premier resultat s'enregistre")
	r.enregistrer_resultat(2, false, 2)
	v.egal(r.meilleure_du_chapitre(2), 4, "un resultat moins bon ne remplace pas le meilleur")
	r.enregistrer_resultat(9, false, 2)
	v.egal(r.meilleure_du_chapitre(2), 9, "un meilleur resultat remplace")
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

func test_une_annexe_ne_modifie_pas_la_campagne(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.meilleures_par_chapitre = {"0": 3}
	r.runs = 0
	r.enregistrer_resultat_annexe(true)
	v.egal(r.meilleure_du_chapitre(0), 3, "la Mine et les Epreuves ne touchent pas au chapitre")
	v.egal(r.runs, 1, "la tentative annexe compte dans l'activite globale")
	r.free()

func test_le_niveau_de_compte_ne_donne_aucune_statistique(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.niveau_compte = 1
	r.experience_compte = r.experience_compte_requise() - 1
	r.ajouter_experience_compte(1)
	v.egal(r.niveau_compte, 2, "le gain fait progresser le compte")
	v.egal(r.experience_compte, 0, "le surplus est reporte proprement au niveau suivant")
	v.egal(r.titre_compte(), "COMPTE", "le niveau est clairement un niveau de compte")
	var stats := Stats.depuis_reglages()
	v.presque(stats.pv_max, Reglages.HEROS_PV, "le compte n'ajoute aucun PV")
	v.presque(stats.degats, Reglages.TIR_DEGATS, "le compte n'ajoute aucun degat")
	r.free()

func test_les_niveaux_demandent_un_vrai_farm(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.niveau_compte = 1
	v.vrai(r.experience_compte_requise() >= 70, "le tout premier niveau n'arrive plus gratuitement")
	r.niveau_compte = 10
	v.vrai(r.experience_compte_requise() >= 500, "la courbe devient franchement exigeante")
	r.free()

func test_le_choix_de_musique_est_valide_et_persistant(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.piste_musique = "first_arcade"
	r.definir_piste_musique("dynamic_arcade")
	v.egal(r.piste_musique, "dynamic_arcade", "Dynamic Arcade peut etre selectionnee")
	r.definir_piste_musique("piste_inconnue")
	v.egal(r.piste_musique, "dynamic_arcade", "une piste inconnue ne remplace pas le choix")
	r.free()

func test_l_arsenal_ne_depend_pas_du_niveau_de_compte(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	r.niveau_compte = 1
	r.experience_compte = 0
	r.rangs_sorts = {}
	r.ajouter_experience_compte(r.experience_compte_requise())
	v.egal(r.niveau_compte, 2, "le compte atteint le niveau deux")
	v.vrai(r.sort_decouvert("onde_alchimique"), "les Epreuves peuvent proposer le sort a tout niveau")
	v.egal(r.rang_sort("onde_alchimique"), 0, "mais attend toujours son premier drop de defi")
	v.vrai(not r.sort_debloque("onde_alchimique"), "le rang zero ne peut pas etre equipe")
	r.free()

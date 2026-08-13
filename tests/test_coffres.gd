extends RefCounted

const FinDeRun = preload("res://ui/fin_de_run.gd")

func test_qualite_evolue_aux_quatre_paliers(v: Verif) -> void:
	v.egal(Recompenses.coffre_pour(4)["palier"], 0, "aucun coffre avant cinq salles")
	v.egal(Recompenses.coffre_pour(5)["nom"], "Mini coffre", "palier cinq")
	v.egal(Recompenses.coffre_pour(10)["nom"], "Petit coffre", "palier dix")
	v.egal(Recompenses.coffre_pour(18)["nom"], "Coffre moyen", "mourir salle 19 garde le palier quinze")
	v.egal(Recompenses.coffre_pour(20)["nom"], "Grand coffre", "clear complet")

func test_garantie_du_grand_coffre(v: Verif) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var grand := Recompenses.coffre_pour(20)
	v.vrai(Recompenses.donne_objet(grand, Recompenses.GARANTIE_APRES_GRANDS_COFFRES - 1, rng),
		"le cinquieme grand coffre sans objet est garanti")

func test_les_gouttes_suivent_les_trente_chapitres(v: Verif) -> void:
	var grand := Recompenses.coffre_pour(20)
	var debut := RandomNumberGenerator.new()
	debut.seed = 17
	var fin := RandomNumberGenerator.new()
	fin.seed = 17
	var gouttes_debut := Recompenses.tirer_gouttes_coffre(grand, 0, debut)
	var gouttes_fin := Recompenses.tirer_gouttes_coffre(grand, Chapitres.nombre() - 1, fin)
	v.vrai(gouttes_fin >= gouttes_debut * 15,
		"le dernier chapitre finance les Maitrises tardives sans invalider le debut")

func test_l_economie_finance_l_arbre_sur_la_campagne(v: Verif) -> void:
	var cout_total := 0
	for id in ArbreCompetences.NOEUDS:
		cout_total += ArbreCompetences.cout(id)
	var grand := Recompenses.coffre_pour(20)
	var moyenne_base := (float(grand["gouttes_min"]) + float(grand["gouttes_max"])) * 0.5
	var revenu_campagne := 0.0
	for chapitre in Chapitres.nombre():
		revenu_campagne += moyenne_base * pow(Reglages.GOUTTES_MULT_PAR_CHAPITRE, chapitre)
	v.vrai(revenu_campagne > float(cout_total),
		"un grand coffre moyen par chapitre peut financer les trente Maitrises")
	v.vrai(revenu_campagne < float(cout_total) * 1.50,
		"la campagne ne distribue pas assez pour rendre tous les choix gratuits trop tot")

func test_l_ouverture_separe_impact_et_revelation(v: Verif) -> void:
	v.presque(FinDeRun.progression_ouverture(0.5), 0.0, "le coffre reste ferme pendant son arrivee")
	v.vrai(FinDeRun.progression_ouverture(1.35) > 0.0, "le couvercle s'ouvre apres l'impact")
	v.presque(FinDeRun.progression_ouverture(2.0), 1.0, "le coffre finit completement ouvert")
	v.presque(FinDeRun.progression_revelation(1.2), 0.0, "la recompense ne devance pas le coffre")
	v.presque(FinDeRun.progression_revelation(2.2), 1.0, "la recompense devient entierement lisible")

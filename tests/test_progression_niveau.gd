extends RefCounted

func test_les_runs_n_ont_plus_de_formule_de_niveau(v: Verif) -> void:
	Jeu.demarrer_run(1)
	v.vrai(not "niveau" in Jeu and not "experience" in Jeu,
		"la progression de combat depend des pages, pas d'une jauge cachee")

func test_les_deux_modes_ont_la_bonne_longueur(v: Verif) -> void:
	Jeu.demarrer_run(1, 1, 0, "grimoire")
	v.egal(Jeu.salles_du_chapitre(), 30, "un grimoire offre trente recompenses")
	Jeu.demarrer_run(1, 1, 7, "epreuve_sorts")
	v.egal(Jeu.salles_du_chapitre(), 12, "le defi va droit au but en douze paliers")
	v.egal(Jeu.chapitre, 0, "le defi garde sa propre difficulte quel que soit le livre consulte")
	v.vrai(not Vagues.pour_salle(5, 0, 1, "epreuve_sorts").is_empty(),
		"chaque palier du defi contient un combat")
	for numero in [4, 8, 12]:
		v.egal(Vagues.pour_salle(numero, 0, 1, "epreuve_sorts"), [[Chapitres.par_index(0)["boss"]]],
			"le palier %d du defi est un boss" % numero)
	for numero in [1, 2, 3, 5, 6, 7, 9, 10, 11]:
		var vagues := Vagues.pour_salle(numero, 0, 1, "epreuve_sorts")
		v.egal(vagues.size(), 1, "le palier %d est une grande vague unique" % numero)
		v.vrai(vagues[0].size() >= 7, "la vague de defi est plus dense que celle d'un grimoire")

func test_la_table_de_loot_des_sorts_est_exacte(v: Verif) -> void:
	var comptes := {"ultime": 0, "actif": 0, "passif": 0, "gouttes": 0}
	for jet in range(1, 101):
		var type := Recompenses.type_epreuve_pour_jet(jet)
		comptes[type] += 1
	v.egal(comptes["ultime"], 5, "cinq pour cent d'ultimes")
	v.egal(comptes["actif"], 10, "dix pour cent d'actifs")
	v.egal(comptes["passif"], 10, "dix pour cent de passifs")
	v.egal(comptes["gouttes"], 75, "sinon la recompense donne des gouttes")

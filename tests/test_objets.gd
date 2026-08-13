extends RefCounted

func test_deux_anneaux_et_un_collier_par_monde(v: Verif) -> void:
	v.egal(CatalogueObjets.OBJETS.size(), 30, "les trente chapitres ont chacun leur objet")
	for monde in Chapitres.MONDES.size():
		var anneaux := 0
		var colliers := 0
		for chapitre_monde in 3:
			var objets := CatalogueObjets.du_chapitre(monde * 3 + chapitre_monde)
			v.egal(objets.size(), 1, "un seul objet est associe au chapitre")
			var slot: String = CatalogueObjets.OBJETS[objets[0]]["slot"]
			anneaux += 1 if slot == "anneau" else 0
			colliers += 1 if slot == "collier" else 0
		v.egal(anneaux, 2, "le monde fournit deux anneaux")
		v.egal(colliers, 1, "le monde fournit un collier")

func test_le_coffre_ne_demande_jamais_un_doublon(v: Verif) -> void:
	var rng := RandomNumberGenerator.new()
	var id := CatalogueObjets.objet_du_chapitre(0)
	v.egal(CatalogueObjets.tirer_manquant(0, [], rng), id, "le chapitre donne son objet")
	v.egal(CatalogueObjets.tirer_manquant(0, [id], rng), "", "un objet possede ne retombe pas")

func test_la_forge_appartient_au_slot(v: Verif) -> void:
	var anneaux := [CatalogueObjets.objet_du_chapitre(0), CatalogueObjets.objet_du_chapitre(1)]
	var forge := {"anneau_gauche": 3, "anneau_droit": 0, "collier": 0}
	var premier := CatalogueObjets.bonus_effectifs({"anneau_gauche": anneaux[0]}, forge)
	var second := CatalogueObjets.bonus_effectifs({"anneau_gauche": anneaux[1]}, forge)
	v.egal(premier, second, "changer d'anneau conserve tout l'investissement du slot")

func test_ajouter_un_objet_l_equipe_si_le_slot_est_vide(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	var id := CatalogueObjets.objet_du_chapitre(0)
	v.vrai(r.ajouter_objet(id), "un objet connu peut etre ajoute")
	v.egal(r.equipements["anneau_gauche"], id, "le premier anneau equipe le premier slot vide")
	v.vrai(not r.ajouter_objet(id), "le meme objet n'est jamais requis en doublon")
	r.free()

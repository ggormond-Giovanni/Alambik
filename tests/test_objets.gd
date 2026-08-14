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

func test_la_forge_appartient_a_l_objet(v: Verif) -> void:
	var anneaux := [CatalogueObjets.objet_du_chapitre(0), CatalogueObjets.objet_du_chapitre(1)]
	var forge := {anneaux[0]: 3, anneaux[1]: 0}
	var premier := CatalogueObjets.bonus_effectifs({"anneau_gauche": anneaux[0]}, forge)
	var second := CatalogueObjets.bonus_effectifs({"anneau_gauche": anneaux[1]}, forge)
	v.vrai(float(premier["degats"]) > float(second["degats"]),
		"changer d'anneau ne transfere pas les niveaux de l'ancien objet")

func test_ajouter_un_objet_l_equipe_si_le_slot_est_vide(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	var id := CatalogueObjets.objet_du_chapitre(0)
	v.vrai(r.ajouter_objet(id), "un objet connu peut etre ajoute")
	v.egal(r.equipements["anneau_gauche"], id, "le premier anneau equipe le premier slot vide")
	v.vrai(not r.ajouter_objet(id), "le meme objet n'est jamais requis en doublon")
	v.vrai(r.retirer_objet("anneau_gauche"), "un objet equipe peut etre retire")
	v.egal(r.equipements["anneau_gauche"], "", "le joueur peut volontairement laisser un slot vide")
	r.pierres_forge = 999
	v.vrai(r.ameliorer_objet(id), "un objet possede peut etre ameliore")
	v.egal(r.niveau_objet(id), 1, "le niveau est stocke sur l'objet")
	r.free()

func test_migration_forge_et_slot_volontairement_vide(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	var id := CatalogueObjets.objet_du_chapitre(0)
	r.objets.clear()
	r.objets.append(id)
	r.equipements = {"anneau_gauche": id, "anneau_droit": "", "collier": ""}
	r.forge_niveaux = {"anneau_gauche": 3, "anneau_droit": 0, "collier": 0}
	r._migrer_forge_par_objet()
	v.egal(r.niveau_objet(id), 3, "une ancienne Forge de slot migre vers l'objet equipe")
	v.vrai(not r.forge_niveaux.has("anneau_gauche"), "l'ancienne cle de slot est retiree")
	r.equipements["anneau_gauche"] = ""
	r._migrer_equipements()
	v.egal(r.equipements["anneau_gauche"], "", "un slot vide volontaire n'est pas rempli au chargement")
	r.free()

func test_la_forge_est_plafonnee(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	var id := CatalogueObjets.objet_du_chapitre(0)
	r.objets.clear()
	r.objets.append(id)
	r.pierres_forge = 999999
	r.forge_niveaux[id] = Reglages.FORGE_NIVEAU_MAX
	v.vrai(not r.ameliorer_objet(id), "un objet au niveau maximal ne peut plus monter")
	r.forge_niveaux[id] = Reglages.FORGE_NIVEAU_MAX + 99
	v.egal(r.niveau_objet(id), Reglages.FORGE_NIVEAU_MAX,
		"une ancienne sauvegarde trop haute est ramenee au plafond")
	r.free()

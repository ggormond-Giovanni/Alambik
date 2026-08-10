extends RefCounted

func test_le_catalogue_couvre_les_trois_emplacements(v: Verif) -> void:
	var slots := {}
	for id in CatalogueObjets.OBJETS:
		slots[CatalogueObjets.OBJETS[id]["slot"]] = true
	v.egal(slots.size(), 3, "arme, robe et talisman ont des objets")

func test_chaque_grimoire_a_exactement_un_trio(v: Verif) -> void:
	for chapitre in Chapitres.nombre():
		var trio := CatalogueObjets.du_chapitre(chapitre)
		v.egal(trio.size(), 3, "le grimoire %d a trois objets" % chapitre)
		var slots := {}
		for id in trio:
			slots[CatalogueObjets.OBJETS[id]["slot"]] = true
		v.egal(slots.size(), 3, "le trio contient arme, robe et talisman")

func test_le_coffre_evite_les_doublons(v: Verif) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var trio := CatalogueObjets.du_chapitre(0)
	var possedes: Array[String] = [trio[0], trio[1]]
	v.egal(CatalogueObjets.tirer_manquant(0, possedes, rng), trio[2], "le coffre donne la seule piece manquante")
	possedes.append(trio[2])
	v.egal(CatalogueObjets.tirer_manquant(0, possedes, rng), "", "un trio complet demande des gouttes")

func test_ajouter_un_objet_le_place_dans_l_inventaire(v: Verif) -> void:
	var r := ReglagesJoueur
	var anciens := r.objets.duplicate()
	var ancien_dernier := r.dernier_objet_obtenu
	var ancienne_sauvegarde := r.sauvegarde_active
	r.sauvegarde_active = false
	r.objets.clear()
	var id := CatalogueObjets.du_chapitre(0)[0]
	v.vrai(r.ajouter_objet(id), "un objet connu peut etre ajoute")
	v.egal(r.objets.size(), 1, "le loot est conserve dans le stuff")
	v.egal(r.dernier_objet_obtenu, id, "le dernier loot est memorise")
	r.objets.assign(anciens)
	r.dernier_objet_obtenu = ancien_dernier
	r.sauvegarde_active = ancienne_sauvegarde

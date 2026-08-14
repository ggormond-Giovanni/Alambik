extends Node

# Options et meilleur resultat, gardes en local. Aucun SDK, aucune collecte :
# c'est explicitement hors perimetre de la V1.

const FICHIER := "user://alambic.cfg"
const VERSION_CAMPAGNE := 2

var victoires := 0
var runs := 0
# Une entree par chapitre suffit : les annexes ne doivent jamais ouvrir la
# campagne ni contaminer sa meilleure progression.
var meilleures_par_chapitre := {}
var chapitre_choisi := 0
var gouttes := 0
var rangs_competences := {}
var niveau_compte := 1
var experience_compte := 0
var mode_dev := false
var volume_musique := 1.0
var volume_effets := 1.0
var piste_musique := "first_arcade"
var secousses_ecran := true
var effets_reduits := false
# Comment le Sort actif part : par son icone seule, par une tape rapide dans la
# zone de deplacement, ou par une double tape rapide.
var raccourci_sort := RaccourciTactile.MODE_DEFAUT
var sort_actif_equipe := ""
var ultime_equipe := ""
var passifs_equipes: Array[String] = []
var rangs_sorts := {}
var objets: Array[String] = []
var dernier_objet_obtenu := ""
var grands_coffres_sans_objet := {}
var equipements := {"anneau_gauche": "", "anneau_droit": "", "collier": ""}
# La Forge appartient desormais a l'objet, pas a l'emplacement. Changer
# d'anneau ne transfere donc plus artificiellement tous les niveaux investis.
var forge_niveaux := {}
var pierres_forge := 0
var mode_run_choisi := "grimoire"
var sauvegarde_active := true

signal maitrise_changee
signal reglages_changes

func _ready() -> void:
	charger()
	Sons.appliquer_reglages()

func charger() -> void:
	var config := ConfigFile.new()
	if config.load(FICHIER) != OK:
		return
	victoires = config.get_value("resultats", "victoires", 0)
	runs = config.get_value("resultats", "runs", 0)
	meilleures_par_chapitre = config.get_value("resultats", "par_chapitre", {})
	chapitre_choisi = config.get_value("options", "chapitre_choisi", 0)
	if int(config.get_value("campagne", "version", 1)) < VERSION_CAMPAGNE:
		_migrer_ancienne_campagne()
	# Migration transparente : les anciens points deviennent des gouttes.
	gouttes = int(config.get_value("monnaie", "gouttes", config.get_value("maitrise", "points", 0)))
	rangs_competences = config.get_value("maitrise", "rangs", {})
	# Les anciennes sauvegardes utilisaient la section "heros" pour ce qui est
	# en realite une progression de compte.
	niveau_compte = maxi(1, int(config.get_value("compte", "niveau",
		config.get_value("heros", "niveau", 1))))
	experience_compte = int(config.get_value("compte", "experience",
		config.get_value("heros", "experience", 0)))
	mode_dev = bool(config.get_value("options", "mode_dev", false))
	volume_musique = clampf(float(config.get_value("audio", "musique", 1.0)), 0.0, 1.0)
	volume_effets = clampf(float(config.get_value("audio", "effets", 1.0)), 0.0, 1.0)
	piste_musique = str(config.get_value("audio", "piste", "first_arcade"))
	if piste_musique not in ["first_arcade", "dynamic_arcade"]:
		piste_musique = "first_arcade"
	secousses_ecran = bool(config.get_value("accessibilite", "secousses", true))
	effets_reduits = bool(config.get_value("accessibilite", "effets_reduits", false))
	raccourci_sort = RaccourciTactile.mode_valide(str(config.get_value("commandes", "raccourci_sort",
		RaccourciTactile.MODE_DEFAUT)))
	sort_actif_equipe = str(config.get_value("sorts", "actif", ""))
	ultime_equipe = str(config.get_value("sorts", "ultime", ""))
	passifs_equipes.clear()
	for id in config.get_value("sorts", "passifs", []):
		var passif := str(id)
		if Sorts.PASSIFS.has(passif) and passifs_equipes.size() < nombre_slots_passifs():
			passifs_equipes.append(passif)
	var anciens_sorts_debloques: Array[String] = []
	for id in config.get_value("sorts", "debloques", []):
		var sort_id := str(id)
		if Sorts.contient(sort_id):
			anciens_sorts_debloques.append(sort_id)
	rangs_sorts = config.get_value("sorts", "rangs", {})
	# Migration : un sort utilisable dans une ancienne sauvegarde devient rang 1.
	for id in anciens_sorts_debloques:
		rangs_sorts[id] = maxi(1, int(rangs_sorts.get(id, 0)))
	objets.clear()
	for id in config.get_value("stuff", "objets", []):
		var objet := str(id)
		if CatalogueObjets.OBJETS.has(objet):
			objets.append(objet)
	dernier_objet_obtenu = str(config.get_value("stuff", "dernier", ""))
	grands_coffres_sans_objet = config.get_value("stuff", "pities", {})
	equipements = config.get_value("stuff", "equipements", equipements)
	forge_niveaux = config.get_value("stuff", "forge", forge_niveaux)
	pierres_forge = maxi(0, int(config.get_value("stuff", "pierres_forge", 0)))
	_migrer_equipements()
	_migrer_forge_par_objet()
	mode_run_choisi = str(config.get_value("options", "mode_run", "grimoire"))
	# Le prototype graphique n'est plus un mode : toutes les descentes utilisent
	# maintenant le rendu 16-bit, donc les anciennes sauvegardes reviennent en campagne.
	if mode_run_choisi not in ["grimoire", "epreuve_sorts", "mine"]:
		mode_run_choisi = "grimoire"

func sauvegarder() -> void:
	if not sauvegarde_active:
		return
	var config := ConfigFile.new()
	config.set_value("resultats", "victoires", victoires)
	config.set_value("resultats", "runs", runs)
	config.set_value("resultats", "par_chapitre", meilleures_par_chapitre)
	config.set_value("options", "chapitre_choisi", chapitre_choisi)
	config.set_value("monnaie", "gouttes", gouttes)
	config.set_value("maitrise", "rangs", rangs_competences)
	config.set_value("compte", "niveau", niveau_compte)
	config.set_value("compte", "experience", experience_compte)
	config.set_value("options", "mode_dev", mode_dev)
	config.set_value("audio", "musique", volume_musique)
	config.set_value("audio", "effets", volume_effets)
	config.set_value("audio", "piste", piste_musique)
	config.set_value("accessibilite", "secousses", secousses_ecran)
	config.set_value("accessibilite", "effets_reduits", effets_reduits)
	config.set_value("commandes", "raccourci_sort", raccourci_sort)
	config.set_value("sorts", "actif", sort_actif_equipe)
	config.set_value("sorts", "ultime", ultime_equipe)
	config.set_value("sorts", "passifs", passifs_equipes)
	config.set_value("sorts", "rangs", rangs_sorts)
	config.set_value("stuff", "objets", objets)
	config.set_value("stuff", "dernier", dernier_objet_obtenu)
	config.set_value("stuff", "pities", grands_coffres_sans_objet)
	config.set_value("stuff", "equipements", equipements)
	config.set_value("stuff", "forge", forge_niveaux)
	config.set_value("stuff", "pierres_forge", pierres_forge)
	config.set_value("options", "mode_run", mode_run_choisi)
	config.set_value("campagne", "version", VERSION_CAMPAGNE)
	config.save(FICHIER)

func _migrer_ancienne_campagne() -> void:
	var anciennes: Dictionary = meilleures_par_chapitre.duplicate()
	var converties := {}
	for cle in anciennes:
		var monde := int(cle)
		var progression := clampi(int(anciennes[cle]), 0, 30)
		for acte in 3:
			var dans_acte := clampi(progression - acte * 10, 0, 10)
			if dans_acte > 0:
				converties[str(monde * 3 + acte)] = mini(Reglages.SALLES_PAR_RUN, dans_acte * 2)
	meilleures_par_chapitre = converties
	chapitre_choisi = clampi(chapitre_choisi * 3, 0, Chapitres.nombre() - 1)

func ajouter_objet(id: String) -> bool:
	if not CatalogueObjets.OBJETS.has(id) or id in objets:
		return false
	objets.append(id)
	dernier_objet_obtenu = id
	_equipement_automatique(id)
	sauvegarder()
	maitrise_changee.emit()
	return true

func _migrer_equipements() -> void:
	for slot in ["anneau_gauche", "anneau_droit", "collier"]:
		var id := str(equipements.get(slot, ""))
		if not CatalogueObjets.compatible(slot, id) or id not in objets:
			equipements[slot] = ""

func _migrer_forge_par_objet() -> void:
	# Anciennes sauvegardes : le niveau etait stocke sur le slot. On le donne a
	# l'objet actuellement equipe, puis on retire les trois anciennes cles.
	for slot in ["anneau_gauche", "anneau_droit", "collier"]:
		if not forge_niveaux.has(slot):
			continue
		var id := str(equipements.get(slot, ""))
		if not id.is_empty():
			forge_niveaux[id] = maxi(int(forge_niveaux.get(id, 0)), int(forge_niveaux[slot]))
		forge_niveaux.erase(slot)

func _equipement_automatique(id: String) -> void:
	for slot in ["anneau_gauche", "anneau_droit", "collier"]:
		if str(equipements.get(slot, "")).is_empty() and CatalogueObjets.compatible(slot, id):
			equipements[slot] = id
			return

func equiper_objet(slot: String, id: String) -> bool:
	if id not in objets_disponibles() or not CatalogueObjets.compatible(slot, id):
		return false
	# Un anneau ne peut pas occuper les deux emplacements simultanement.
	for autre in equipements:
		if autre != slot and equipements[autre] == id:
			equipements[autre] = ""
	equipements[slot] = id
	sauvegarder()
	maitrise_changee.emit()
	return true

func retirer_objet(slot: String) -> bool:
	if slot not in equipements or str(equipements[slot]).is_empty():
		return false
	equipements[slot] = ""
	sauvegarder()
	maitrise_changee.emit()
	return true

func niveau_objet(id: String) -> int:
	return clampi(int(forge_niveaux.get(id, 0)), 0, Reglages.FORGE_NIVEAU_MAX) \
		if CatalogueObjets.OBJETS.has(id) else 0

func cout_forge(id: String) -> int:
	return Reglages.cout_forge(niveau_objet(id))

func ameliorer_objet(id: String) -> bool:
	if id not in objets_disponibles() or niveau_objet(id) >= Reglages.FORGE_NIVEAU_MAX \
			or pierres_forge < cout_forge(id):
		return false
	pierres_forge -= cout_forge(id)
	forge_niveaux[id] = niveau_objet(id) + 1
	sauvegarder()
	maitrise_changee.emit()
	return true

func ajouter_pierres_forge(nombre: int) -> int:
	if nombre <= 0:
		return 0
	var gain := maxi(1, roundi(float(nombre) \
		* ArbreCompetences.multiplicateur_pierres(rangs_competences_effectifs())))
	pierres_forge += gain
	sauvegarder()
	maitrise_changee.emit()
	return gain

func grands_coffres_rates(chapitre: int) -> int:
	return int(grands_coffres_sans_objet.get(str(chapitre), 0))

func enregistrer_grand_coffre(chapitre: int, objet_obtenu: bool) -> void:
	var cle := str(chapitre)
	grands_coffres_sans_objet[cle] = 0 if objet_obtenu else grands_coffres_rates(chapitre) + 1
	sauvegarder()

func definir_reglages_audio(musique: float, effets: float) -> void:
	volume_musique = clampf(musique, 0.0, 1.0)
	volume_effets = clampf(effets, 0.0, 1.0)
	Sons.appliquer_reglages()
	sauvegarder()
	reglages_changes.emit()

func definir_piste_musique(id: String) -> void:
	if id not in ["first_arcade", "dynamic_arcade"] or id == piste_musique:
		return
	piste_musique = id
	Sons.appliquer_reglages()
	sauvegarder()
	reglages_changes.emit()

func definir_raccourci_sort(mode: String) -> void:
	var demande := RaccourciTactile.mode_valide(mode)
	if demande == raccourci_sort:
		return
	raccourci_sort = demande
	sauvegarder()
	reglages_changes.emit()

func definir_accessibilite(secousses: bool, reduire_effets: bool) -> void:
	secousses_ecran = secousses
	effets_reduits = reduire_effets
	sauvegarder()
	reglages_changes.emit()

func ajouter_gouttes(nombre: int) -> void:
	if mode_dev:
		return
	if nombre <= 0:
		return
	gouttes += maxi(1, roundi(float(nombre) * ArbreCompetences.multiplicateur_collecte(rangs_competences_effectifs()) \
		* (1.0 + float(bonus_objets_effectifs()["collecte"]))))
	sauvegarder()
	maitrise_changee.emit()

func experience_compte_requise() -> int:
	var profondeur := niveau_compte - 1
	return 70 + profondeur * 30 + profondeur * profondeur * 2

func ajouter_experience_compte(nombre: int) -> void:
	if nombre <= 0:
		return
	var gain := roundi(float(nombre) * ArbreCompetences.multiplicateur_experience(rangs_competences_effectifs()))
	experience_compte += maxi(1, gain)
	while experience_compte >= experience_compte_requise():
		var requis := experience_compte_requise()
		experience_compte -= requis
		niveau_compte += 1
	sauvegarder()
	maitrise_changee.emit()

func niveau_compte_effectif() -> int:
	return niveau_compte

func titre_compte() -> String:
	return "COMPTE"

func rang_competence(id: String) -> int:
	if not ArbreCompetences.NOEUDS.has(id):
		return 0
	return ArbreCompetences.rangs(id) if mode_dev \
		else clampi(int(rangs_competences.get(id, 0)), 0, ArbreCompetences.rangs(id))

func gouttes_affichees() -> String:
	return "∞" if mode_dev else str(gouttes)

func rangs_competences_effectifs() -> Dictionary:
	if mode_dev:
		var tous_les_rangs := {}
		for id in ArbreCompetences.NOEUDS:
			tous_les_rangs[id] = ArbreCompetences.rangs(id)
		return tous_les_rangs
	return rangs_competences

func objets_disponibles() -> Array[String]:
	if not mode_dev:
		return objets
	var tous: Array[String] = []
	for id in CatalogueObjets.OBJETS:
		tous.append(id)
	return tous

func bonus_objets_effectifs() -> Dictionary:
	return CatalogueObjets.bonus_effectifs(equipements, forge_niveaux)

func passifs_equipes_effectifs() -> Dictionary:
	var resultat := {}
	for id in passifs_equipes:
		if Sorts.PASSIFS.has(id) and sort_debloque(id):
			resultat[id] = efficacite_sort(id)
	return resultat

func cout_competence(id: String) -> int:
	return ArbreCompetences.cout(id, rang_competence(id))

func peut_acheter_competence(id: String) -> bool:
	if not ArbreCompetences.NOEUDS.has(id):
		return false
	return rang_competence(id) < ArbreCompetences.rangs(id) \
		and (mode_dev or ArbreCompetences.prerequis_atteint(id, rangs_competences)) \
		and (mode_dev or gouttes >= cout_competence(id))

func acheter_competence(id: String) -> bool:
	if not peut_acheter_competence(id):
		return false
	if not mode_dev:
		gouttes -= cout_competence(id)
	rangs_competences[id] = rang_competence(id) + 1
	sauvegarder()
	maitrise_changee.emit()
	return true

func equiper_sort(id: String, type: String) -> void:
	if not sort_debloque(id):
		return
	if type == "actif" and Sorts.ACTIFS.has(id):
		sort_actif_equipe = id
	elif type == "ultime" and Sorts.ULTIMES.has(id):
		ultime_equipe = id
	sauvegarder()
	maitrise_changee.emit()

func retirer_sort(type: String) -> bool:
	if type == "actif" and not sort_actif_equipe.is_empty():
		sort_actif_equipe = ""
	elif type == "ultime" and not ultime_equipe.is_empty():
		ultime_equipe = ""
	else:
		return false
	sauvegarder()
	maitrise_changee.emit()
	return true

func basculer_passif(id: String) -> String:
	if not Sorts.PASSIFS.has(id) or not sort_debloque(id):
		return "verrouille"
	if id in passifs_equipes:
		passifs_equipes.erase(id)
		sauvegarder()
		maitrise_changee.emit()
		return "retire"
	if passifs_equipes.size() >= nombre_slots_passifs():
		return "plein"
	passifs_equipes.append(id)
	sauvegarder()
	maitrise_changee.emit()
	return "equipe"

func nombre_slots_passifs() -> int:
	return 2 if ArbreCompetences.donne_second_passif(rangs_competences_effectifs()) else 1

func sort_actif_effectif() -> String:
	return sort_actif_equipe if sort_debloque(sort_actif_equipe) else ""

func ultime_effectif() -> String:
	return ultime_equipe if sort_debloque(ultime_equipe) else ""

func sort_debloque(id: String) -> bool:
	return Sorts.contient(id) and (mode_dev or rang_sort(id) > 0)

func sort_decouvert(id: String) -> bool:
	return Sorts.contient(id)

func rang_sort(id: String) -> int:
	return Reglages.CAPACITE_RANG_MAX if mode_dev and Sorts.contient(id) \
		else clampi(int(rangs_sorts.get(id, 0)), 0, Reglages.CAPACITE_RANG_MAX)

func efficacite_sort(id: String) -> float:
	var rang := rang_sort(id)
	return 0.0 if rang <= 0 else 1.0 + float(rang - 1) * Reglages.CAPACITE_BONUS_PAR_RANG

func debloquer_sort(id: String) -> bool:
	if not Sorts.contient(id) or not sort_decouvert(id) or rang_sort(id) >= Reglages.CAPACITE_RANG_MAX:
		return false
	rangs_sorts[id] = rang_sort(id) + 1
	sauvegarder()
	maitrise_changee.emit()
	return true

func reinitialiser_arbre() -> int:
	var rembourses := 0
	for id in rangs_competences:
		if not ArbreCompetences.NOEUDS.has(id):
			continue
		for rang in int(rangs_competences[id]):
			rembourses += ArbreCompetences.cout(id, rang)
	gouttes += rembourses
	rangs_competences.clear()
	sauvegarder()
	maitrise_changee.emit()
	return rembourses

func definir_mode_dev(actif: bool) -> void:
	mode_dev = actif
	if not mode_dev:
		# Un objet seulement equipe pour un test ne doit pas devenir un vrai drop.
		_migrer_equipements()
	sauvegarder()
	maitrise_changee.emit()
	reglages_changes.emit()

func reinitialiser_progression() -> void:
	victoires = 0
	runs = 0
	meilleures_par_chapitre.clear()
	chapitre_choisi = 0
	gouttes = 0
	rangs_competences.clear()
	niveau_compte = 1
	experience_compte = 0
	sort_actif_equipe = ""
	ultime_equipe = ""
	passifs_equipes.clear()
	rangs_sorts.clear()
	objets.clear()
	dernier_objet_obtenu = ""
	grands_coffres_sans_objet.clear()
	equipements = {"anneau_gauche": "", "anneau_droit": "", "collier": ""}
	forge_niveaux = {}
	pierres_forge = 0
	mode_run_choisi = "grimoire"
	sauvegarder()
	maitrise_changee.emit()
	reglages_changes.emit()

func enregistrer_resultat(salle: int, victoire: bool, chapitre := 0) -> void:
	runs += 1
	if victoire:
		victoires += 1
	var cle := str(chapitre)
	if salle > int(meilleures_par_chapitre.get(cle, 0)):
		meilleures_par_chapitre[cle] = salle
	sauvegarder()

func enregistrer_resultat_annexe(victoire: bool) -> void:
	runs += 1
	if victoire:
		victoires += 1
	sauvegarder()

func meilleure_du_chapitre(chapitre: int) -> int:
	return int(meilleures_par_chapitre.get(str(chapitre), 0))

# Palier de reference des annexes. Sans lui, la Mine rapporterait autant au
# premier Monde qu'apres le dernier et cesserait d'etre une source de Pierres.
func palier_atteint() -> int:
	if mode_dev:
		return Chapitres.nombre() - 1
	var meilleur := 0
	for cle in meilleures_par_chapitre:
		var index := int(cle)
		if index >= 0 and index < Chapitres.nombre() and int(meilleures_par_chapitre[cle]) > 0:
			meilleur = maxi(meilleur, Chapitres.palier(index))
	return meilleur

func pierres_mine() -> int:
	return Reglages.pierres_mine(palier_atteint())

# Un chapitre s'ouvre quand le precedent a ete termine. Le premier est toujours
# ouvert : personne ne doit rester devant une porte close au premier lancement.
func chapitre_debloque(chapitre: int) -> bool:
	if mode_dev:
		return true
	if chapitre <= 0:
		return true
	var precedent := Chapitres.par_index(chapitre - 1)
	return meilleure_du_chapitre(chapitre - 1) >= int(precedent["salles"])

func choisir_chapitre(chapitre: int) -> void:
	chapitre_choisi = clampi(chapitre, 0, Chapitres.nombre() - 1)
	sauvegarder()

func choisir_mode_run(mode: String) -> void:
	if mode not in ["grimoire", "epreuve_sorts", "mine"]:
		return
	mode_run_choisi = mode
	sauvegarder()

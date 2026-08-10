extends Node

# Options et meilleur resultat, gardes en local. Aucun SDK, aucune collecte :
# c'est explicitement hors perimetre de la V1.

const FICHIER := "user://alambic.cfg"

var meilleure_salle := 0
var victoires := 0
var runs := 0
# Une entree par chapitre : la page la plus profonde atteinte. C'est la seule
# chose qu'une run laisse derriere elle.
var meilleures_par_chapitre := {}
var chapitre_choisi := 0
var recettes_decouvertes: Array[String] = []
var gouttes := 0
var rangs_competences := {}
var niveau_heros := 1
var experience_heros := 0
var mode_dev := false
var volume_musique := 1.0
var volume_effets := 1.0
var secousses_ecran := true
var effets_reduits := false
var sort_actif_equipe := ""
var ultime_equipe := ""
var passifs_equipes: Array[String] = []
var sorts_debloques: Array[String] = []
var rangs_sorts := {}
var objets: Array[String] = []
var dernier_objet_obtenu := ""
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
	meilleure_salle = config.get_value("resultats", "meilleure_salle", 0)
	victoires = config.get_value("resultats", "victoires", 0)
	runs = config.get_value("resultats", "runs", 0)
	meilleures_par_chapitre = config.get_value("resultats", "par_chapitre", {})
	chapitre_choisi = config.get_value("options", "chapitre_choisi", 0)
	recettes_decouvertes.clear()
	for recette in config.get_value("decouvertes", "recettes", []):
		recettes_decouvertes.append(str(recette))
	# Migration transparente : les anciens points deviennent des gouttes.
	gouttes = int(config.get_value("monnaie", "gouttes", config.get_value("maitrise", "points", 0)))
	rangs_competences = config.get_value("maitrise", "rangs", {})
	niveau_heros = clampi(int(config.get_value("heros", "niveau", 1)), 1, Reglages.NIVEAU_HEROS_MAX)
	experience_heros = int(config.get_value("heros", "experience", 0))
	if niveau_heros >= Reglages.NIVEAU_HEROS_MAX:
		experience_heros = 0
	mode_dev = bool(config.get_value("options", "mode_dev", false))
	volume_musique = clampf(float(config.get_value("audio", "musique", 1.0)), 0.0, 1.0)
	volume_effets = clampf(float(config.get_value("audio", "effets", 1.0)), 0.0, 1.0)
	secousses_ecran = bool(config.get_value("accessibilite", "secousses", true))
	effets_reduits = bool(config.get_value("accessibilite", "effets_reduits", false))
	sort_actif_equipe = str(config.get_value("sorts", "actif", ""))
	ultime_equipe = str(config.get_value("sorts", "ultime", ""))
	passifs_equipes.clear()
	for id in config.get_value("sorts", "passifs", []):
		var passif := str(id)
		if Sorts.PASSIFS.has(passif) and passifs_equipes.size() < 2:
			passifs_equipes.append(passif)
	sorts_debloques.clear()
	for id in config.get_value("sorts", "debloques", []):
		var sort_id := str(id)
		if Sorts.contient(sort_id):
			sorts_debloques.append(sort_id)
	rangs_sorts = config.get_value("sorts", "rangs", {})
	# Migration : un sort utilisable dans une ancienne sauvegarde devient rang 1.
	for id in sorts_debloques:
		rangs_sorts[id] = maxi(1, int(rangs_sorts.get(id, 0)))
	_reveler_sorts_jusqu_au_niveau()
	_synchroniser_sorts_utilisables()
	objets.clear()
	for id in config.get_value("stuff", "objets", []):
		var objet := str(id)
		if CatalogueObjets.OBJETS.has(objet):
			objets.append(objet)
	dernier_objet_obtenu = str(config.get_value("stuff", "dernier", ""))
	mode_run_choisi = str(config.get_value("options", "mode_run", "grimoire"))
	if mode_run_choisi not in ["grimoire", "epreuve_sorts"]:
		mode_run_choisi = "grimoire"

func sauvegarder() -> void:
	if not sauvegarde_active:
		return
	var config := ConfigFile.new()
	config.set_value("resultats", "meilleure_salle", meilleure_salle)
	config.set_value("resultats", "victoires", victoires)
	config.set_value("resultats", "runs", runs)
	config.set_value("resultats", "par_chapitre", meilleures_par_chapitre)
	config.set_value("options", "chapitre_choisi", chapitre_choisi)
	config.set_value("decouvertes", "recettes", recettes_decouvertes)
	config.set_value("monnaie", "gouttes", gouttes)
	config.set_value("maitrise", "rangs", rangs_competences)
	config.set_value("heros", "niveau", niveau_heros)
	config.set_value("heros", "experience", experience_heros)
	config.set_value("options", "mode_dev", mode_dev)
	config.set_value("audio", "musique", volume_musique)
	config.set_value("audio", "effets", volume_effets)
	config.set_value("accessibilite", "secousses", secousses_ecran)
	config.set_value("accessibilite", "effets_reduits", effets_reduits)
	config.set_value("sorts", "actif", sort_actif_equipe)
	config.set_value("sorts", "ultime", ultime_equipe)
	config.set_value("sorts", "passifs", passifs_equipes)
	config.set_value("sorts", "debloques", sorts_debloques)
	config.set_value("sorts", "rangs", rangs_sorts)
	config.set_value("stuff", "objets", objets)
	config.set_value("stuff", "dernier", dernier_objet_obtenu)
	config.set_value("options", "mode_run", mode_run_choisi)
	config.save(FICHIER)

func ajouter_objet(id: String) -> bool:
	if not CatalogueObjets.OBJETS.has(id):
		return false
	objets.append(id)
	dernier_objet_obtenu = id
	sauvegarder()
	maitrise_changee.emit()
	return true

func definir_reglages_audio(musique: float, effets: float) -> void:
	volume_musique = clampf(musique, 0.0, 1.0)
	volume_effets = clampf(effets, 0.0, 1.0)
	Sons.appliquer_reglages()
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

func experience_heros_requise() -> int:
	if niveau_heros >= Reglages.NIVEAU_HEROS_MAX:
		return 0
	var profondeur := niveau_heros - 1
	return 70 + profondeur * 30 + profondeur * profondeur * 2

func ajouter_experience_heros(nombre: int) -> void:
	if niveau_heros >= Reglages.NIVEAU_HEROS_MAX:
		return
	var gain := roundi(float(nombre) * ArbreCompetences.multiplicateur_experience(rangs_competences_effectifs()))
	experience_heros += maxi(1, gain)
	while niveau_heros < Reglages.NIVEAU_HEROS_MAX and experience_heros >= experience_heros_requise():
		var requis := experience_heros_requise()
		experience_heros -= requis
		niveau_heros += 1
		_reveler_sort_niveau(niveau_heros)
	if niveau_heros >= Reglages.NIVEAU_HEROS_MAX:
		experience_heros = 0
	sauvegarder()
	maitrise_changee.emit()

func multiplicateur_niveau_degats() -> float:
	var progression := 1.0 + float(niveau_heros_effectif() - 1) * 0.005
	return progression * (Reglages.PRESTIGE_DEGATS if est_prestigieux() else 1.0)

func multiplicateur_niveau_vitesse() -> float:
	var progression := 1.0 + float(niveau_heros_effectif() - 1) * 0.0025
	return progression * (Reglages.PRESTIGE_VITESSE if est_prestigieux() else 1.0)

func bonus_niveau_pv() -> float:
	return float(niveau_heros_effectif() - 1) + (Reglages.PRESTIGE_PV if est_prestigieux() else 0.0)

func niveau_heros_effectif() -> int:
	return niveau_heros

func est_prestigieux() -> bool:
	return niveau_heros_effectif() >= Reglages.NIVEAU_HEROS_MAX

func titre_heros() -> String:
	return "HÉROS ★" if est_prestigieux() else "HÉROS"

func rang_competence(id: String) -> int:
	return int(rangs_competences.get(id, 0))

func gouttes_affichees() -> String:
	return "∞" if mode_dev else str(gouttes)

func rangs_competences_effectifs() -> Dictionary:
	return rangs_competences

func bonus_objets_effectifs() -> Dictionary:
	return CatalogueObjets.bonus_effectifs(objets)

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
	var noeud: Dictionary = ArbreCompetences.NOEUDS[id]
	return rang_competence(id) < ArbreCompetences.MAX_RANG \
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

func basculer_passif(id: String) -> String:
	if not Sorts.PASSIFS.has(id) or not sort_debloque(id):
		return "verrouille"
	if id in passifs_equipes:
		passifs_equipes.erase(id)
		sauvegarder()
		maitrise_changee.emit()
		return "retire"
	if passifs_equipes.size() >= 2:
		return "plein"
	passifs_equipes.append(id)
	sauvegarder()
	maitrise_changee.emit()
	return "equipe"

func sort_actif_effectif() -> String:
	return sort_actif_equipe if sort_debloque(sort_actif_equipe) else ""

func ultime_effectif() -> String:
	return ultime_equipe if sort_debloque(ultime_equipe) else ""

func sort_debloque(id: String) -> bool:
	return Sorts.contient(id) and (mode_dev or rang_sort(id) > 0)

func sort_decouvert(id: String) -> bool:
	return Sorts.contient(id) and (mode_dev or rangs_sorts.has(id))

func rang_sort(id: String) -> int:
	return 5 if mode_dev and Sorts.contient(id) else clampi(int(rangs_sorts.get(id, 0)), 0, 5)

func efficacite_sort(id: String) -> float:
	return float(rang_sort(id))

func _reveler_sort_niveau(niveau: int) -> void:
	var id := Sorts.id_du_niveau(niveau)
	if not id.is_empty() and not rangs_sorts.has(id):
		rangs_sorts[id] = 0

func _reveler_sorts_jusqu_au_niveau() -> void:
	for niveau in range(2, niveau_heros + 1):
		_reveler_sort_niveau(niveau)

func _synchroniser_sorts_utilisables() -> void:
	sorts_debloques.clear()
	for id in rangs_sorts:
		if Sorts.contient(id) and int(rangs_sorts[id]) > 0:
			sorts_debloques.append(id)

func debloquer_sort(id: String) -> bool:
	if not Sorts.contient(id) or not sort_decouvert(id) or rang_sort(id) >= 5:
		return false
	rangs_sorts[id] = rang_sort(id) + 1
	_synchroniser_sorts_utilisables()
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
	sauvegarder()
	maitrise_changee.emit()

func recette_decouverte(a: String, b: String) -> bool:
	return mode_dev or Recettes.cle(a, b) in recettes_decouvertes

func decouvrir_recette(a: String, b: String) -> void:
	var cle := Recettes.cle(a, b)
	if cle in recettes_decouvertes:
		return
	recettes_decouvertes.append(cle)
	sauvegarder()

func enregistrer_resultat(salle: int, victoire: bool, chapitre := 0) -> void:
	runs += 1
	if victoire:
		victoires += 1
	if salle > meilleure_salle:
		meilleure_salle = salle
	var cle := str(chapitre)
	if salle > int(meilleures_par_chapitre.get(cle, 0)):
		meilleures_par_chapitre[cle] = salle
	sauvegarder()

func meilleure_du_chapitre(chapitre: int) -> int:
	return int(meilleures_par_chapitre.get(str(chapitre), 0))

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
	if mode not in ["grimoire", "epreuve_sorts"]:
		return
	mode_run_choisi = mode
	sauvegarder()

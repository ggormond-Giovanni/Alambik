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
var points_maitrise := 0
var rangs_competences := {}
var niveau_heros := 1
var experience_heros := 0
var mode_dev := false

signal maitrise_changee

func _ready() -> void:
	charger()

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
	points_maitrise = int(config.get_value("maitrise", "points", 0))
	rangs_competences = config.get_value("maitrise", "rangs", {})
	niveau_heros = int(config.get_value("heros", "niveau", 1))
	experience_heros = int(config.get_value("heros", "experience", 0))
	mode_dev = bool(config.get_value("options", "mode_dev", false))

func sauvegarder() -> void:
	var config := ConfigFile.new()
	config.set_value("resultats", "meilleure_salle", meilleure_salle)
	config.set_value("resultats", "victoires", victoires)
	config.set_value("resultats", "runs", runs)
	config.set_value("resultats", "par_chapitre", meilleures_par_chapitre)
	config.set_value("options", "chapitre_choisi", chapitre_choisi)
	config.set_value("decouvertes", "recettes", recettes_decouvertes)
	config.set_value("maitrise", "points", points_maitrise)
	config.set_value("maitrise", "rangs", rangs_competences)
	config.set_value("heros", "niveau", niveau_heros)
	config.set_value("heros", "experience", experience_heros)
	config.set_value("options", "mode_dev", mode_dev)
	config.save(FICHIER)

func ajouter_points_maitrise(nombre: int) -> void:
	if mode_dev:
		return
	if nombre <= 0:
		return
	points_maitrise += nombre
	sauvegarder()
	maitrise_changee.emit()

func experience_heros_requise() -> int:
	return 40 + (niveau_heros - 1) * 20

func ajouter_experience_heros(nombre: int) -> void:
	var gain := roundi(float(nombre) * ArbreCompetences.multiplicateur_experience(rangs_competences_effectifs()))
	experience_heros += maxi(1, gain)
	while experience_heros >= experience_heros_requise():
		experience_heros -= experience_heros_requise()
		niveau_heros += 1
	sauvegarder()
	maitrise_changee.emit()

func multiplicateur_niveau_degats() -> float:
	return 1.0 + float(niveau_heros_effectif() - 1) * 0.005

func multiplicateur_niveau_vitesse() -> float:
	return 1.0 + float(niveau_heros_effectif() - 1) * 0.0025

func bonus_niveau_pv() -> float:
	return float(niveau_heros_effectif() - 1)

func niveau_heros_effectif() -> int:
	return 100 if mode_dev else niveau_heros

func rang_competence(id: String) -> int:
	if mode_dev and ArbreCompetences.NOEUDS.has(id):
		return ArbreCompetences.MAX_RANG
	return int(rangs_competences.get(id, 0))

func points_maitrise_affiches() -> String:
	return "∞" if mode_dev else str(points_maitrise)

func rangs_competences_effectifs() -> Dictionary:
	if not mode_dev:
		return rangs_competences
	var maximums := {}
	for id in ArbreCompetences.NOEUDS:
		maximums[id] = ArbreCompetences.MAX_RANG
	return maximums

func cout_competence(id: String) -> int:
	return ArbreCompetences.cout(id, rang_competence(id))

func peut_acheter_competence(id: String) -> bool:
	if not ArbreCompetences.NOEUDS.has(id):
		return false
	var noeud: Dictionary = ArbreCompetences.NOEUDS[id]
	return rang_competence(id) < ArbreCompetences.MAX_RANG \
		and ArbreCompetences.prerequis_atteint(id, rangs_competences) \
		and points_maitrise >= cout_competence(id)

func acheter_competence(id: String) -> bool:
	if not peut_acheter_competence(id):
		return false
	points_maitrise -= cout_competence(id)
	rangs_competences[id] = rang_competence(id) + 1
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
	points_maitrise += rembourses
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

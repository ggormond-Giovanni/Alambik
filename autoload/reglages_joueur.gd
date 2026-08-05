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

func sauvegarder() -> void:
	var config := ConfigFile.new()
	config.set_value("resultats", "meilleure_salle", meilleure_salle)
	config.set_value("resultats", "victoires", victoires)
	config.set_value("resultats", "runs", runs)
	config.set_value("resultats", "par_chapitre", meilleures_par_chapitre)
	config.set_value("options", "chapitre_choisi", chapitre_choisi)
	config.save(FICHIER)

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
	if chapitre <= 0:
		return true
	var precedent := Chapitres.par_index(chapitre - 1)
	return meilleure_du_chapitre(chapitre - 1) >= int(precedent["salles"])

func choisir_chapitre(chapitre: int) -> void:
	chapitre_choisi = clampi(chapitre, 0, Chapitres.nombre() - 1)
	sauvegarder()

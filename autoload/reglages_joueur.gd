extends Node

# Options et meilleur resultat, gardes en local. Aucun SDK, aucune collecte :
# c'est explicitement hors perimetre de la V1.

const FICHIER := "user://alambic.cfg"

var meilleure_salle := 0
var victoires := 0
var runs := 0

func _ready() -> void:
	charger()

func charger() -> void:
	var config := ConfigFile.new()
	if config.load(FICHIER) != OK:
		return
	meilleure_salle = config.get_value("resultats", "meilleure_salle", 0)
	victoires = config.get_value("resultats", "victoires", 0)
	runs = config.get_value("resultats", "runs", 0)

func sauvegarder() -> void:
	var config := ConfigFile.new()
	config.set_value("resultats", "meilleure_salle", meilleure_salle)
	config.set_value("resultats", "victoires", victoires)
	config.set_value("resultats", "runs", runs)
	config.save(FICHIER)

func enregistrer_resultat(salle: int, victoire: bool) -> void:
	runs += 1
	if victoire:
		victoires += 1
	if salle > meilleure_salle:
		meilleure_salle = salle
	sauvegarder()

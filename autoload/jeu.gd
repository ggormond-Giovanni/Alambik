extends Node

# Etat de la run en cours. La mort renvoie au menu sans rien conserver :
# aucune meta-progression en V1, c'est explicitement hors perimetre.

signal run_terminee(victoire: bool)
signal inventaire_change

var salle_courante := 0
var inventaire: Array[String] = []
var rng := RandomNumberGenerator.new()
var graine := 0
var mode_auto := false          # le bot headless pilote la run
var ennemis_abattus := 0
# Compteurs de diagnostic : sans eux, un blocage ne dit pas si le heros tirait
# dans le vide, dans un mur, ou pas du tout.
var tirs_emis := 0
var tirs_touches := 0
var tirs_dans_un_mur := 0
var tirs_perdus := 0
var debut_run := 0.0

func demarrer_run(graine_demandee: int = 0, salle_de_depart: int = 1) -> void:
	# Une graine explicite rend une run rejouable : c'est ce qui permet au bot
	# headless de reproduire un blocage au lieu de le raconter.
	graine = graine_demandee if graine_demandee != 0 else randi()
	rng = RandomNumberGenerator.new()
	rng.seed = graine
	salle_courante = salle_de_depart
	inventaire = []
	ennemis_abattus = 0
	tirs_emis = 0
	tirs_touches = 0
	tirs_dans_un_mur = 0
	tirs_perdus = 0
	debut_run = Time.get_ticks_msec() / 1000.0

func ajouter_reactif(id: String) -> void:
	inventaire.append(id)
	inventaire_change.emit()

func retirer_reactifs(ids: Array) -> void:
	for id in ids:
		inventaire.erase(id)
	inventaire_change.emit()

func reactif(id: String) -> Reactif:
	var r := CatalogueReactifs.par_id(id)
	return r if r != null else CatalogueEssences.par_id(id)

func mods() -> Array:
	var liste: Array = []
	for id in inventaire:
		var r := reactif(id)
		if r != null:
			liste.append(r.mods)
	return liste

func duree_run() -> float:
	return Time.get_ticks_msec() / 1000.0 - debut_run

func terminer_run(victoire: bool) -> void:
	run_terminee.emit(victoire)

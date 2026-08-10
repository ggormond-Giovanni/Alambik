extends Node

# Etat de la run en cours. La mort renvoie au menu sans rien conserver de la
# descente ; seul le chapitre atteint reste debloque.

signal run_terminee(victoire: bool)
signal inventaire_change
signal experience_changee
signal niveau_gagne(nouveau_niveau: int)

var salle_courante := 0
var chapitre := 0
var inventaire: Array[String] = []
var niveau := 1
var experience := 0
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
# Temps de jeu, compte en images : en headless le temps reel est compresse, et
# c'est la duree qu'un joueur passerait manette en main qui nous interesse.
var images_de_jeu := 0

func chapitre_courant() -> Dictionary:
	return Chapitres.par_index(chapitre)

func salles_du_chapitre() -> int:
	return int(chapitre_courant()["salles"])

func demarrer_run(graine_demandee: int = 0, salle_de_depart: int = 1, chapitre_demande := 0) -> void:
	# Une graine explicite rend une run rejouable : c'est ce qui permet au bot
	# headless de reproduire un blocage au lieu de le raconter.
	graine = graine_demandee if graine_demandee != 0 else randi()
	rng = RandomNumberGenerator.new()
	rng.seed = graine
	chapitre = clampi(chapitre_demande, 0, Chapitres.nombre() - 1)
	salle_courante = salle_de_depart
	inventaire = []
	niveau = 1
	experience = 0
	ennemis_abattus = 0
	tirs_emis = 0
	tirs_touches = 0
	tirs_dans_un_mur = 0
	tirs_perdus = 0
	debut_run = Time.get_ticks_msec() / 1000.0
	images_de_jeu = 0
	experience_changee.emit()

func experience_requise() -> int:
	return Reglages.EXPERIENCE_PREMIER_NIVEAU + (niveau - 1) * Reglages.EXPERIENCE_PAR_NIVEAU

func ajouter_experience(montant: int) -> void:
	if montant <= 0:
		return
	experience += montant
	while experience >= experience_requise():
		experience -= experience_requise()
		niveau += 1
		niveau_gagne.emit(niveau)
	experience_changee.emit()

func ajouter_reactif(id: String) -> void:
	inventaire.append(id)
	inventaire_change.emit()

func copies(id: String) -> int:
	return DraftLogique.copies(inventaire, id)

# L'inventaire garde ses doublons — c'est ce qui empile les reactifs — mais
# l'affichage, lui, doit montrer une pastille par reactif avec son compte.
func inventaire_groupe() -> Array:
	var ordre: Array[String] = []
	var comptes := {}
	for id in inventaire:
		if not id in ordre:
			ordre.append(id)
			comptes[id] = 0
		comptes[id] += 1
	var resultat: Array = []
	for id in ordre:
		resultat.append([id, comptes[id]])
	return resultat

func retirer_reactifs(ids: Array) -> void:
	for id in ids:
		inventaire.erase(id)
	inventaire_change.emit()

func reactif(id: String) -> Reactif:
	var r := CatalogueReactifs.par_id(id)
	return r if r != null else CatalogueEssences.par_id(id)

func mods() -> Array:
	return Mods.depuis_l_inventaire(inventaire)

func duree_run() -> float:
	return float(images_de_jeu) / float(Engine.physics_ticks_per_second)

func terminer_run(victoire: bool) -> void:
	run_terminee.emit(victoire)

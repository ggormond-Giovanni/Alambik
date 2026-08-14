extends Node

# Etat de la run en cours. La mort renvoie au menu sans rien conserver de la
# descente ; seul le chapitre atteint reste debloque.

signal run_terminee(victoire: bool)
signal inventaire_change
signal experience_run_change

var salle_courante := 0
var chapitre := 0
var inventaire: Array[String] = []
var experience_run := 0
var niveau_run := 0
var rerolls_restants := 0
var mode_run := "grimoire"
var rng := RandomNumberGenerator.new()
var graine := 0
var mode_auto := false          # le bot headless pilote la run
var ennemis_abattus := 0
var temps_mine_restant := 0.0
var elements_alambic_tires: Array[String] = []
var derniere_fusion_epreuve := {}
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
	if mode_run == "retro":
		return 1
	if mode_run == "epreuve_sorts":
		return 5
	if mode_run == "mine":
		return 1
	return int(chapitre_courant()["salles"])

func nom_run() -> String:
	if mode_run == "retro":
		return "Vision enchantée"
	if mode_run == "epreuve_sorts":
		return "Épreuves rituelles"
	if mode_run == "mine":
		return "Mine"
	return str(chapitre_courant()["nom"])

func est_boss_courant() -> bool:
	if mode_run == "retro":
		return get_tree().get_first_node_in_group("boss") != null
	if mode_run == "epreuve_sorts":
		return true
	if mode_run == "mine":
		return get_tree().get_first_node_in_group("boss") != null
	return Chapitres.est_boss(chapitre, salle_courante)

func demarrer_run(graine_demandee: int = 0, salle_de_depart: int = 1, chapitre_demande := 0,
		mode_demande := "grimoire") -> void:
	# Une graine explicite rend une run rejouable : c'est ce qui permet au bot
	# headless de reproduire un blocage au lieu de le raconter.
	graine = graine_demandee if graine_demandee != 0 else randi()
	rng = RandomNumberGenerator.new()
	rng.seed = graine
	mode_run = mode_demande if mode_demande in ["grimoire", "epreuve_sorts", "mine", "retro"] else "grimoire"
	# Le defi a sa propre courbe : il ne depend jamais du dernier livre consulte.
	chapitre = 0 if mode_run != "grimoire" else clampi(chapitre_demande, 0, Chapitres.nombre() - 1)
	salle_courante = salle_de_depart
	inventaire = []
	experience_run = 0
	niveau_run = 0
	rerolls_restants = ArbreCompetences.nombre_rerolls(ReglagesJoueur.rangs_competences_effectifs())
	ennemis_abattus = 0
	temps_mine_restant = Reglages.MINE_DUREE if mode_run == "mine" else 0.0
	elements_alambic_tires = []
	derniere_fusion_epreuve = {}
	tirs_emis = 0
	tirs_touches = 0
	tirs_dans_un_mur = 0
	tirs_perdus = 0
	debut_run = Time.get_ticks_msec() / 1000.0
	images_de_jeu = 0

func est_retro() -> bool:
	return mode_run == "retro"

func ajouter_reactif(id: String) -> void:
	inventaire.append(id)
	inventaire_change.emit()

func gagner_experience_run(nombre: int) -> int:
	if niveau_run >= Reglages.XP_RUN_SEUILS.size() or nombre <= 0:
		return 0
	var multiplicateur := Reglages.AVIDITE_XP_MULT if "avidite" in inventaire else 1.0
	experience_run += maxi(1, roundi(float(nombre) * multiplicateur))
	var niveaux_gagnes := 0
	while niveau_run < Reglages.XP_RUN_SEUILS.size() \
			and experience_run >= int(Reglages.XP_RUN_SEUILS[niveau_run]):
		niveau_run += 1
		niveaux_gagnes += 1
	experience_run_change.emit()
	return niveaux_gagnes

func experience_vers_prochain_niveau() -> Dictionary:
	if niveau_run >= Reglages.XP_RUN_SEUILS.size():
		return {"actuelle": 1, "requise": 1}
	var precedente := 0 if niveau_run == 0 else int(Reglages.XP_RUN_SEUILS[niveau_run - 1])
	return {"actuelle": maxi(0, experience_run - precedente),
		"requise": int(Reglages.XP_RUN_SEUILS[niveau_run]) - precedente}

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

func reactif(id: String) -> Reactif:
	var r := CatalogueReactifs.par_id(id)
	if r == null and CatalogueElements.est_fusion(id):
		r = CatalogueElements.creer_fusion(CatalogueElements.element_de_fusion(id),
			CatalogueElements.augment_de_fusion(id))
	return r

func ajouter_fusion_elementaire(element: String, augment: String) -> bool:
	if augment_deja_fusionne(augment):
		return false
	var fusion := CatalogueElements.creer_fusion(element, augment)
	if fusion == null:
		return false
	inventaire.append(fusion.id)
	inventaire_change.emit()
	return true

func ajouter_fusion_aleatoire_epreuve() -> Dictionary:
	var augments := CatalogueReactifs.ids()
	for id in inventaire:
		if id in augments or CatalogueElements.est_fusion(id):
			augments.erase(id if id in augments else CatalogueElements.augment_de_fusion(id))
	if augments.is_empty():
		return {}
	var augment: String = augments[rng.randi_range(0, augments.size() - 1)]
	var element := tirer_element_alambic()
	if element.is_empty():
		var elements := CatalogueElements.ids()
		element = elements[rng.randi_range(0, elements.size() - 1)]
	ajouter_reactif(augment)
	if not ajouter_fusion_elementaire(element, augment):
		return {}
	var fusion := CatalogueElements.creer_fusion(element, augment)
	derniere_fusion_epreuve = {"augment": augment, "element": element, "fusion": fusion.id}
	return derniere_fusion_epreuve.duplicate()

func augment_deja_fusionne(augment: String) -> bool:
	return not elements_de_augment(augment).is_empty()

func tirer_element_alambic() -> String:
	var disponibles := CatalogueElements.ids()
	for element in elements_alambic_tires:
		disponibles.erase(element)
	if disponibles.is_empty():
		return ""
	var element: String = disponibles[rng.randi_range(0, disponibles.size() - 1)]
	elements_alambic_tires.append(element)
	return element

func elements_de_augment(augment: String) -> Array[String]:
	var resultat: Array[String] = []
	for id in inventaire:
		if CatalogueElements.est_fusion(id) and CatalogueElements.augment_de_fusion(id) == augment:
			resultat.append(CatalogueElements.element_de_fusion(id))
	return resultat

func mods() -> Array:
	return Mods.depuis_l_inventaire(inventaire)

func duree_run() -> float:
	return float(images_de_jeu) / float(Engine.physics_ticks_per_second)

func terminer_run(victoire: bool) -> void:
	run_terminee.emit(victoire)

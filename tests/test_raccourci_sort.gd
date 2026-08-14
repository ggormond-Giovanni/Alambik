extends RefCounted

func test_les_modes_couvrent_les_trois_choix(v: Verif) -> void:
	v.egal(RaccourciTactile.MODES.size(), 3, "icone seule, tape rapide et double tape rapide")
	v.egal(RaccourciTactile.tapes_requises("icone"), 0, "sans raccourci, seule l'icone lance le Sort")
	v.egal(RaccourciTactile.tapes_requises("tape"), 1, "une tape rapide suffit")
	v.egal(RaccourciTactile.tapes_requises("double_tape"), 2, "le double appui en demande deux")
	v.egal(RaccourciTactile.mode_valide("n_importe_quoi"), RaccourciTactile.MODE_DEFAUT,
		"un mode inconnu retombe sur l'icone")

func test_une_tape_breve_et_immobile_est_reconnue(v: Verif) -> void:
	var r := RaccourciTactile.new()
	r.appuyer(Vector2(300, 1200), 0.0)
	v.egal(r.relacher(0.10), 1, "un appui bref et immobile est une tape")

# Le vrai risque du raccourci : lancer le Sort chaque fois que le pouce corrige
# sa trajectoire. Un deplacement n'est jamais une tape, meme tres bref.
func test_un_deplacement_n_est_jamais_une_tape(v: Verif) -> void:
	var r := RaccourciTactile.new()
	r.appuyer(Vector2(300, 1200), 0.0)
	r.deplacer(Vector2(300 + RaccourciTactile.DISTANCE_MAX + 10.0, 1200))
	v.egal(r.relacher(0.10), 0, "un pouce qui pilote le heros ne declenche rien")

func test_un_appui_maintenu_n_est_jamais_une_tape(v: Verif) -> void:
	var r := RaccourciTactile.new()
	r.appuyer(Vector2(300, 1200), 0.0)
	v.egal(r.relacher(RaccourciTactile.DUREE_MAX + 0.05), 0,
		"garder le pouce pose ne declenche rien")

func test_deux_tapes_rapprochees_forment_un_double(v: Verif) -> void:
	var r := RaccourciTactile.new()
	r.appuyer(Vector2(300, 1200), 0.0)
	v.egal(r.relacher(0.08), 1, "la premiere tape est comptee")
	r.appuyer(Vector2(304, 1198), 0.20)
	v.egal(r.relacher(0.28), 2, "la seconde tape rapprochee complete le double")

func test_deux_tapes_espacees_ne_forment_pas_un_double(v: Verif) -> void:
	var r := RaccourciTactile.new()
	r.appuyer(Vector2(300, 1200), 0.0)
	v.egal(r.relacher(0.08), 1, "la premiere tape est comptee")
	var tard := 0.08 + RaccourciTactile.DELAI_ENTRE_TAPES + 0.10
	r.appuyer(Vector2(300, 1200), tard)
	v.egal(r.relacher(tard + 0.05), 1, "trop tard, la serie repart de zero")

# Sans remise a zero apres un tir, la tape suivante completerait un double deja
# consomme et le Sort partirait une fois de trop.
func test_le_sort_lance_remet_la_serie_a_zero(v: Verif) -> void:
	var r := RaccourciTactile.new()
	r.appuyer(Vector2(300, 1200), 0.0)
	r.relacher(0.05)
	r.appuyer(Vector2(300, 1200), 0.15)
	v.egal(r.relacher(0.20), 2, "le double appui est atteint")
	r.consommer()
	r.appuyer(Vector2(300, 1200), 0.30)
	v.egal(r.relacher(0.35), 1, "la tape suivante recommence une nouvelle serie")

func test_un_geste_baladeur_casse_la_serie_en_cours(v: Verif) -> void:
	var r := RaccourciTactile.new()
	r.appuyer(Vector2(300, 1200), 0.0)
	v.egal(r.relacher(0.05), 1, "la premiere tape est comptee")
	r.appuyer(Vector2(300, 1200), 0.10)
	r.deplacer(Vector2(500, 1200))
	v.egal(r.relacher(0.15), 0, "un deplacement franc ne complete pas un double appui")
	r.appuyer(Vector2(300, 1200), 0.20)
	v.egal(r.relacher(0.25), 1, "la serie est bien repartie de zero")

func test_le_reglage_est_conserve(v: Verif) -> void:
	var r: Node = load("res://autoload/reglages_joueur.gd").new()
	r.sauvegarde_active = false
	v.egal(r.raccourci_sort, RaccourciTactile.MODE_DEFAUT,
		"une nouvelle partie n'active aucun raccourci")
	r.definir_raccourci_sort("double_tape")
	v.egal(r.raccourci_sort, "double_tape", "le mode choisi est retenu")
	r.definir_raccourci_sort("inconnu")
	v.egal(r.raccourci_sort, RaccourciTactile.MODE_DEFAUT,
		"un mode invalide ramene a l'icone plutot que de bloquer le Sort")
	r.free()

class_name CatalogueReactifs
extends RefCounted

# Catalogue exact des seize Améliorations actuellement decides. Les Elements vivent
# dans leur propre catalogue et ne peuvent donc jamais polluer les level-ups.

const PROJECTILE := "projectile"
const HEROS := "heros"
const PHENOMENE := "phenomene"
# Quatrieme famille. Un Sceau ne modifie ni le tir, ni le heros, ni un Phenomene :
# il grave une regle permanente sur la salle. Fusionne, son Element devient une
# aura qui marque toute creature qui s'approche, sans lui infliger de degats.
const SCEAU := "sceau"

static var TOUS := {
	"tir_multiple": Reactif.creer("tir_multiple", "Tir multiple",
		"Ajoute un projectile simultané. Chaque trait inflige moins de dégâts.",
		{"nb_projectiles_add": 1, "ecart_lateral_add": 30.0, "degats_mult": 0.72},
		false, Color(0.98, 0.82, 0.42), "eventail", 1, PROJECTILE),
	"salve": Reactif.creer("salve", "Salve",
		"Chaque attaque devient une salve de deux tirs rapides moins puissants.",
		{"drapeaux": ["rafale"], "degats_mult": 0.72},
		false, Color(1.00, 0.72, 0.34), "triple_barre", 1, PROJECTILE),
	"ricochet": Reactif.creer("ricochet", "Ricochet",
		"Les projectiles rebondissent d'un ennemi vers un autre. Les murs les arrêtent.",
		{"rebonds_add": 1}, false, Color(0.62, 0.86, 0.96), "zigzag", 1, PROJECTILE),
	"perforation": Reactif.creer("perforation", "Perforation",
		"Les projectiles traversent un ennemi et poursuivent leur trajectoire.",
		{"perforations_add": 1}, false, Color(0.86, 0.90, 0.98), "lance", 1, PROJECTILE),
	"fragmentation": Reactif.creer("fragmentation", "Fragmentation",
		"L'impact libère plusieurs projectiles secondaires.",
		{"fragments_add": 3, "degats_mult": 0.88}, false, Color(0.80, 0.96, 0.94), "eclats", 1, PROJECTILE),
	"homing": Reactif.creer("homing", "Homing",
		"Les projectiles recherchent leur cible et corrigent leur trajectoire.",
		{"drapeaux": ["homing"], "vitesse_mult": 0.88}, false, Color(0.72, 0.88, 1.00), "oeil", 1, PROJECTILE),
	# Un coup rare mais enorme : la brulure du Feu et le bonus de la Terre se
	# calculent sur l'attaque, donc tout ce qui concentre la frappe les amplifie.
	"frappe_lourde": Reactif.creer("frappe_lourde", "Frappe lourde",
		"Les attaques deviennent lentes et écrasantes.",
		{"degats_mult": 1.62, "cadence_mult": 0.68},
		false, Color(0.92, 0.60, 0.32), "masse", 1, PROJECTILE),
	# L'inverse exact : beaucoup d'impacts faibles. Le vol de vie de la Lumière et
	# la surcharge des Ténèbres se declenchent par impact, pas par degat.
	# Le prix est la portee, pas les degats : trois Améliorations du pool payent
	# deja en degats, et ces malus s'additionnent au point de briser une main.
	"cadence_febrile": Reactif.creer("cadence_febrile", "Cadence fébrile",
		"Les attaques s'enchaînent bien plus vite, mais portent moins loin.",
		{"cadence_mult": 1.45, "portee_mult": 0.78},
		false, Color(1.00, 0.88, 0.52), "triple_barre", 1, PROJECTILE),
	# Une ligne entiere touchee d'un seul trait : l'Eau ralentit tout le rang et
	# le Feu y pose autant de brulures qu'il y a de corps.
	# Couvre un arc large plutot qu'une ligne : la reponse aux salles qui
	# encerclent, la ou Tir multiple reste un mur frontal.
	"spirale": Reactif.creer("spirale", "Spirale",
		"Les attaques s'ouvrent en large éventail de projectiles.",
		{"nb_projectiles_add": 2, "angle_eventail_add": 0.55, "degats_mult": 0.74},
		false, Color(0.94, 0.78, 1.00), "eventail", 1, PROJECTILE),
	"trait_transpercant": Reactif.creer("trait_transpercant", "Trait transperçant",
		"Les projectiles traversent tous les ennemis sans jamais s'arrêter.",
		{"drapeaux": ["perfore_tout"], "degats_mult": 0.78, "vitesse_mult": 0.85},
		false, Color(0.78, 0.94, 0.90), "lance", 1, PROJECTILE),

	"egide": Reactif.creer("egide", "Égide",
		"Annule la première attaque subie dans chaque salle.",
		{"drapeaux": ["egide"]}, false, Color(0.88, 0.92, 1.00), "hexagone", 1, HEROS),
	"regeneration": Reactif.creer("regeneration", "Régénération",
		"Récupère une part des PV entre les salles.",
		{"drapeaux": ["regeneration"]}, false, Color(0.54, 0.92, 0.62), "goutte", 1, HEROS),
	"avidite": Reactif.creer("avidite", "Avidité",
		"Augmente l'XP de run et les Gouttes obtenues pendant cette tentative.",
		{"drapeaux": ["avidite"]}, false, Color(1.00, 0.78, 0.30), "fiole", 1, HEROS),
	"courageux": Reactif.creer("courageux", "Courageux",
		"Les dégâts augmentent progressivement à mesure que les PV diminuent.",
		{"drapeaux": ["courageux"]}, false, Color(0.98, 0.42, 0.40), "flamme", 1, HEROS),
	"mannequin": Reactif.creer("mannequin", "Mannequin",
		"Rester immobile assez longtemps augmente la puissance et la cadence.",
		{"drapeaux": ["mannequin"]}, false, Color(0.82, 0.72, 0.54), "masse", 1, HEROS),
	# Tenir sa place devient viable. Fusionne avec la Terre, la protection de la
	# resurrection se pose sur un heros deja difficile a entamer.
	"peau_de_pierre": Reactif.creer("peau_de_pierre", "Peau de pierre",
		"Réduit fortement les dégâts subis, au prix d'un peu de cadence.",
		{"drapeaux": ["peau_de_pierre"], "cadence_mult": 0.92},
		false, Color(0.68, 0.66, 0.60), "hexagone", 1, HEROS),
	# Chaque elimination rend un peu de vie. Avec la Lumière, le heros se soigne
	# a la fois en frappant et en achevant.
	# L'exact contraire de Mannequin : recompense le jeu mobile, et donne enfin
	# une raison de ne pas se figer pour tirer.
	"elan_vital": Reactif.creer("elan_vital", "Élan vital",
		"Se déplacer augmente fortement la puissance des attaques suivantes.",
		{"drapeaux": ["elan_vital"]}, false, Color(0.56, 0.98, 0.86), "sillage", 1, HEROS),
	"soif_de_sang": Reactif.creer("soif_de_sang", "Soif de sang",
		"Chaque élimination rend une part des PV maximum.",
		{"drapeaux": ["soif_de_sang"]}, false, Color(0.94, 0.34, 0.44), "goutte", 1, HEROS),

	"familier_tireur": Reactif.creer("familier_tireur", "Familier tireur",
		"Un familier à distance attaque automatiquement les ennemis.",
		{"drapeaux": ["familier_tireur"]}, false, Color(0.66, 0.86, 1.00), "oeil", 1, PHENOMENE),
	"meteores": Reactif.creer("meteores", "Météores",
		"Un impact de zone puissant tombe périodiquement sur un ennemi.",
		{"drapeaux": ["meteores"]}, false, Color(1.00, 0.52, 0.28), "etoile", 1, PHENOMENE),
	"zone_heros": Reactif.creer("zone_heros", "Zone alchimique",
		"Une zone offensive entoure le héros et récompense le jeu à courte portée.",
		{"drapeaux": ["zone_heros"]}, false, Color(0.68, 0.94, 0.66), "hexagone", 1, PHENOMENE),
	"familier_gardien": Reactif.creer("familier_gardien", "Familier gardien",
		"Un gardien de mêlée attaque, intercepte les menaces et revient après sa mort.",
		{"drapeaux": ["familier_gardien"]}, false, Color(0.78, 0.72, 0.94), "patte", 1, PHENOMENE),
	"orbes_chargees": Reactif.creer("orbes_chargees", "Orbes chargées",
		"Des orbes s'accumulent pendant le mouvement puis partent avec la prochaine attaque.",
		{"drapeaux": ["orbes_chargees"]}, false, Color(0.94, 0.72, 1.00), "cristal", 1, PHENOMENE),
	# Le seul Phénomène qui touche plusieurs corps d'un coup : comme tous les
	# Phénomènes il devient vecteur de son Element, donc la chaine propage aussi
	# la brulure, le ralentissement ou le vol de vie a chaque maillon.
	"chaine_alchimique": Reactif.creer("chaine_alchimique", "Chaîne alchimique",
		"Un arc frappe régulièrement plusieurs ennemis de proche en proche.",
		{"drapeaux": ["chaine_alchimique"]}, false, Color(0.60, 0.90, 1.00), "zigzag", 1, PHENOMENE),
	# Reprend l'espace au lieu de gagner du temps : le seul Phénomène qui
	# desengage, donc le seul qui sauve d'un encerclement.
	"onde_de_choc": Reactif.creer("onde_de_choc", "Onde de choc",
		"Une déflagration régulière frappe et repousse tout ce qui vous entoure.",
		{"drapeaux": ["onde_de_choc"]}, false, Color(0.86, 0.94, 1.00), "hexagone", 1, PHENOMENE),

	"sceau_furie": Reactif.creer("sceau_furie", "Sceau de furie",
		"Grave une furie permanente : les dégâts augmentent fortement.",
		{"degats_mult": 1.28}, false, Color(1.00, 0.46, 0.36), "flamme", 1, SCEAU),
	"sceau_celerite": Reactif.creer("sceau_celerite", "Sceau de célérité",
		"Grave une hâte permanente : la cadence augmente fortement.",
		{"cadence_mult": 1.26}, false, Color(0.98, 0.92, 0.48), "sillage", 1, SCEAU),
	"sceau_garde": Reactif.creer("sceau_garde", "Sceau de garde",
		"Grave une garde permanente : les dégâts subis diminuent fortement.",
		{"drapeaux": ["sceau_garde"]}, false, Color(0.62, 0.82, 1.00), "hexagone", 1, SCEAU),
	"sceau_portee": Reactif.creer("sceau_portee", "Sceau d’envergure",
		"Grave une envergure permanente : les tirs vont bien plus loin et plus vite.",
		{"portee_mult": 1.45, "vitesse_mult": 1.20}, false, Color(0.74, 0.90, 0.98), "lance", 1, SCEAU),
	# Le seul Sceau qui coute quelque chose : beaucoup de puissance contre une
	# fragilite assumee.
	"sceau_ruine": Reactif.creer("sceau_ruine", "Sceau de ruine",
		"Puissance dévastatrice, mais vous encaissez bien moins bien.",
		{"degats_mult": 1.50, "drapeaux": ["sceau_ruine"]},
		false, Color(0.80, 0.34, 0.86), "cristal", 1, SCEAU),
}

static func par_id(id: String) -> Reactif:
	return TOUS.get(id)

static func ids() -> Array[String]:
	var liste: Array[String] = []
	for id in TOUS:
		liste.append(id)
	liste.sort()
	return liste

static func ids_de_famille(famille: String) -> Array[String]:
	var liste: Array[String] = []
	for id in ids():
		if par_id(id).famille == famille:
			liste.append(id)
	return liste
